#!/usr/bin/env bash
# Tear down OpenBI from GCP.
#
# Reverse of deploy. Dry-run by default.
#
# Usage:
#   ./scripts/teardown.sh         # dry-run
#   ./scripts/teardown.sh --yes   # actually destroy

set -euo pipefail

CONFIRM=false
ENV="dev"
for arg in "$@"; do
  case "$arg" in
    --yes) CONFIRM=true ;;
    --env=*) ENV="${arg#--env=}" ;;
    -h|--help) echo "Usage: $0 [--yes] [--env=dev]"; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$REPO_ROOT/terraform/environments/$ENV"
K8S_DIR="$REPO_ROOT/kubernetes"

run() {
  if [ "$CONFIRM" = true ]; then echo "  → $*"; "$@"; else echo "  (dry-run) $*"; fi
}

step() {
  echo
  echo "============================================================"
  echo " $*"
  echo "============================================================"
}

step "Teardown — $ENV"

if [ "$CONFIRM" != true ]; then
  echo
  echo "  DRY-RUN. Nothing destroyed. Pass --yes to actually destroy."
fi

PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "REPLACE")
REGION="europe-west3"

# ----------------------------------------------------------------------
step "1. Delete Kubernetes resources"

run kubectl delete -k "$K8S_DIR/openbi-app/overlays/$ENV" --ignore-not-found=true
run kubectl delete -f "$K8S_DIR/external-secrets/cluster-secret-store.yaml" --ignore-not-found=true
run kubectl delete -f "$K8S_DIR/external-secrets/example-external-secret.yaml" --ignore-not-found=true
run kubectl delete -f "$K8S_DIR/ingress/" --ignore-not-found=true

# ----------------------------------------------------------------------
step "2. Uninstall Helm releases"

run helm uninstall external-secrets -n external-secrets || true

# ----------------------------------------------------------------------
step "3. Delete namespaces"

run kubectl delete namespace openbi --ignore-not-found=true
run kubectl delete namespace external-secrets --ignore-not-found=true

# ----------------------------------------------------------------------
step "4. terraform destroy"

cd "$TF_DIR"
run terraform destroy -input=false -auto-approve -var="resource_suffix=$PROJECT_ID"

# ----------------------------------------------------------------------
step "Summary"

if [ "$CONFIRM" = true ]; then
  echo "  Teardown complete."
  echo
  echo "  Verify no orphaned resources:"
  echo "    gcloud compute instances list"
  echo "    gcloud sql instances list"
  echo "    gcloud storage buckets list | grep openbi"
  echo "    gcloud pubsub topics list | grep openbi"
  echo "    gcloud compute addresses list"
else
  echo "  Dry-run only. To destroy: ./scripts/teardown.sh --yes"
fi
