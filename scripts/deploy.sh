#!/usr/bin/env bash
# Deploy OpenBI to GCP.
#
# Wraps the sequence documented in docs/deployment.md:
#   1. Verify gcloud credentials + project
#   2. terraform apply
#   3. gcloud container clusters get-credentials
#   4. Install External Secrets Operator via Helm
#   5. Apply Kubernetes manifests
#
# NOT verified against real GCP. Dry-run by default.
#
# Usage:
#   ./scripts/deploy.sh              # dry-run
#   ./scripts/deploy.sh --apply      # actually apply

set -euo pipefail

APPLY=false
ENV="dev"
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=true ;;
    --env=*) ENV="${arg#--env=}" ;;
    -h|--help)
      echo "Usage: $0 [--apply] [--env=dev]"
      exit 0
      ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$REPO_ROOT/terraform/environments/$ENV"
K8S_DIR="$REPO_ROOT/kubernetes"

run() {
  if [ "$APPLY" = true ]; then echo "  → $*"; "$@"; else echo "  (dry-run) $*"; fi
}

step() {
  echo
  echo "============================================================"
  echo " $*"
  echo "============================================================"
}

# ----------------------------------------------------------------------
step "1. Verify tooling and credentials"

for tool in gcloud terraform kubectl helm jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: $tool not found." >&2
    exit 1
  fi
done

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
  echo "ERROR: no active gcloud account. Run: gcloud auth login" >&2
  exit 1
fi

PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo "ERROR: no active gcloud project. Run: gcloud config set project PROJECT_ID" >&2
  exit 1
fi

REGION="europe-west3"
CLUSTER_NAME="openbi-dev"

echo "  Project: $PROJECT_ID"
echo "  Region:  $REGION"
echo "  Env:     $ENV"

# ----------------------------------------------------------------------
step "2. terraform apply"

cd "$TF_DIR"
run terraform init -input=false
run terraform apply -input=false -auto-approve -var="resource_suffix=$PROJECT_ID"

if [ "$APPLY" = true ]; then
  echo
  echo "  Terraform outputs:"
  terraform output -json | head -50
fi

# ----------------------------------------------------------------------
step "3. Configure kubectl"

run gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

if [ "$APPLY" = true ]; then
  kubectl cluster-info || true
fi

# ----------------------------------------------------------------------
step "4. Install External Secrets Operator"

if [ "$APPLY" = true ]; then
  ESO_GSA=$(cd "$TF_DIR" && terraform output -raw eso_service_account_email)
fi

run helm repo add external-secrets https://charts.external-secrets.io
run helm repo update
run helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set serviceAccount.name=external-secrets \
  --set serviceAccount.annotations."iam\.gke\.io/gcp-service-account=${ESO_GSA:-REPLACE}"

# ----------------------------------------------------------------------
step "5. Apply Kubernetes manifests"

run kubectl apply -f "$K8S_DIR/namespaces/"
run kubectl apply -f "$K8S_DIR/external-secrets/cluster-secret-store.yaml"
echo
echo "  NOTE: openbi-app manifests contain REPLACE-WITH-* placeholders."
echo "        Substitute before applying."
run kubectl apply -k "$K8S_DIR/openbi-app/overlays/$ENV"

# ----------------------------------------------------------------------
step "Summary"

if [ "$APPLY" = true ]; then
  echo "  Deployment complete."
  echo "  Next: ./scripts/status.sh"
else
  echo "  Dry-run. To apply: ./scripts/deploy.sh --apply"
fi
