#!/usr/bin/env bash
# Show current deployment status. Read-only.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$REPO_ROOT/terraform/environments/dev"
REGION="europe-west3"
CLUSTER_NAME="openbi-dev"

step() {
  echo
  echo "============================================================"
  echo " $*"
  echo "============================================================"
}

# ----------------------------------------------------------------------
step "GCP"

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
  echo "  Not authenticated. Run: gcloud auth login"
  exit 0
fi

PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "(unset)")
ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1)
echo "  Account: $ACCOUNT"
echo "  Project: $PROJECT_ID"
echo "  Region:  $REGION"

# ----------------------------------------------------------------------
step "Terraform"

if [ -f "$TF_DIR/terraform.tfstate" ]; then
  echo "  State file: present"
  echo
  echo "  Resources:"
  (cd "$TF_DIR" && terraform state list 2>/dev/null | head -25)
else
  echo "  No terraform state."
fi

# ----------------------------------------------------------------------
step "GKE"

if gcloud container clusters describe "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
  STATUS=$(gcloud container clusters describe "$CLUSTER_NAME" --region "$REGION" --format="value(status)")
  VERSION=$(gcloud container clusters describe "$CLUSTER_NAME" --region "$REGION" --format="value(currentMasterVersion)")
  echo "  Cluster: $CLUSTER_NAME"
  echo "  Status:  $STATUS"
  echo "  Version: $VERSION"

  echo
  echo "  Node pools:"
  gcloud container node-pools list --cluster="$CLUSTER_NAME" --region="$REGION" --format="table(name,config.machineType,autoscaling.minNodeCount,autoscaling.maxNodeCount)"
else
  echo "  Cluster not found."
fi

# ----------------------------------------------------------------------
step "Kubernetes"

if kubectl cluster-info >/dev/null 2>&1; then
  echo "  Nodes:"
  kubectl get nodes --no-headers 2>/dev/null | head -10

  for ns in openbi external-secrets; do
    if kubectl get namespace "$ns" >/dev/null 2>&1; then
      echo
      echo "  Pods in $ns:"
      kubectl -n "$ns" get pods --no-headers 2>/dev/null | head -10 || echo "    (none)"
    fi
  done

  echo
  echo "  Ingresses:"
  kubectl get ingress -A --no-headers 2>/dev/null | head -5 || echo "    (none)"
else
  echo "  kubectl cannot reach a cluster."
fi

# ----------------------------------------------------------------------
step "Helm releases"

helm list -n external-secrets 2>/dev/null || echo "  (none)"

echo
echo "Done."
