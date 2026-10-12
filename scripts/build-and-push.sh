#!/usr/bin/env bash
# Build OpenBI container images and push them to Artifact Registry.
#
# Usage:
#   ./scripts/build-and-push.sh <artifact-registry-url> <tag-suffix>
#
# Example:
#   ./scripts/build-and-push.sh \
#     europe-west3-docker.pkg.dev/my-project/openbi \
#     v0.1.0
#
# Requires:
#   - gcloud CLI authenticated (gcloud auth login)
#   - Docker running
#   - The OpenBI source repository available locally
#
# NOT verified against real GCP. Commands are correct as written.

set -euo pipefail

REGISTRY_URL="${1:-}"
TAG_SUFFIX="${2:-latest}"

if [ -z "$REGISTRY_URL" ]; then
  echo "Usage: $0 <artifact-registry-url> [tag-suffix]"
  echo "Example: $0 europe-west3-docker.pkg.dev/my-project/openbi v0.1.0"
  exit 1
fi

echo "==> Registry: $REGISTRY_URL"
echo "==> Tag suffix: $TAG_SUFFIX"
echo

# Derive the registry hostname for gcloud auth
REGISTRY_HOST="$(echo "$REGISTRY_URL" | cut -d/ -f1)"
REGION="$(echo "$REGISTRY_HOST" | cut -d- -f1-2)"

# ----------------------------------------------------------------------
# Authenticate Docker to Artifact Registry
# ----------------------------------------------------------------------

echo "==> Authenticating Docker to Artifact Registry"
gcloud auth configure-docker "${REGISTRY_HOST}" --quiet

# ----------------------------------------------------------------------
# Build and push OpenBI images
# ----------------------------------------------------------------------

OPENBI_SRC="${OPENBI_SRC:-$HOME/projects/openbi}"

IMAGES=(
  "openbi-fastapi:latest fastapi"
  # "openbi-superset:latest superset"
  # "ghcr.io/netvark/minio:latest minio"
)

for entry in "${IMAGES[@]}"; do
  read -r local_ref remote_prefix <<< "$entry"
  [ -z "$local_ref" ] && continue

  remote_tag="${REGISTRY_URL}/${remote_prefix}-${TAG_SUFFIX}"

  echo
  echo "==> Processing: $local_ref  →  $remote_tag"

  if ! docker image inspect "$local_ref" >/dev/null 2>&1; then
    echo "    Local image missing. Building..."
    case "$remote_prefix" in
      fastapi)
        docker build \
          -t "$local_ref" \
          -f "$OPENBI_SRC/infrastructure/kubernetes/fastapi-app/Dockerfile" \
          "$OPENBI_SRC"
        ;;
      *)
        echo "    ERROR: no build recipe for $remote_prefix"
        exit 1
        ;;
    esac
  fi

  docker tag "$local_ref" "$remote_tag"
  docker push "$remote_tag"
done

echo
echo "==> Done. Images pushed to $REGISTRY_URL"
