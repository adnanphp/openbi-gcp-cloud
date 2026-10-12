# Artifact Registry module for OpenBI.
#
# Creates a Docker repository and a cleanup policy that bounds storage
# growth. Access is granted at the project level (G2's node SA already
# has roles/artifactregistry.reader).
#
# Design notes:
#   - Docker format (not generic/maven/npm — OpenBI uses container images).
#   - Regional repository matching the GKE cluster region.
#   - Cleanup policy mirrors the ECR lifecycle policy from the AWS repo:
#     keep last N tagged, delete untagged after N days.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# ----------------------------------------------------------------------
# Docker repository
# ----------------------------------------------------------------------

resource "google_artifact_registry_repository" "this" {
  location      = var.region
  project       = var.project_id
  repository_id = var.repository_id
  description   = "OpenBI container images"
  format        = "DOCKER"

  labels = var.labels

  # Cleanup policy: applies on a schedule (Artifact Registry runs it
  # daily). Two rules: keep last N tagged versions, delete old untagged.
  cleanup_policies {
    id     = "keep-last-tagged"
    action = "KEEP"

    most_recent_versions {
      keep_count = var.keep_last_tagged
    }
  }

  cleanup_policies {
    id     = "delete-untagged-after-days"
    action = "DELETE"

    condition {
      tag_state  = "UNTAGGED"
      older_than = "${var.delete_untagged_after_days * 24}h"
    }
  }
}
