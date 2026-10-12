# GCP IAM module for OpenBI.
#
# Creates:
#   - A dedicated service account for GKE nodes (least privilege)
#   - A base Workload Identity service account for pods (template)
#
# Design notes:
#   - No service account keys anywhere. Workload Identity uses short-lived
#     tokens from the GKE metadata server.
#   - Node SA gets only what nodes need: logging, monitoring, image pulls.
#   - Workload Identity bindings (KSA → GSA) are added by each service
#     module that needs pod-level GCP access.
#   - GCP predefined roles are used, not custom roles.

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
# GKE node service account
# ----------------------------------------------------------------------
# Nodes use this SA for logging, metrics, and image pulls. Replaces the
# default Compute Engine SA, which has Editor (too broad).

resource "google_service_account" "gke_nodes" {
  account_id   = "${var.name_prefix}-gke-nodes"
  display_name = "OpenBI GKE node service account"
  description  = "Service account for GKE worker nodes (logging, monitoring, registry read)"

  project = var.project_id
}

resource "google_project_iam_member" "gke_nodes_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metrics" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# ----------------------------------------------------------------------
# Base workload identity service account
# ----------------------------------------------------------------------
# Placeholder SA that future service modules use as a template. It has
# no role bindings; its purpose is to demonstrate the pattern. When a
# service needs GCP access from a pod, the pattern is:
#
#   1. Create a GSA (like this one, per service)
#   2. Grant the GSA specific roles on specific resources
#   3. Bind the GSA to a Kubernetes ServiceAccount via
#      google_service_account_iam_member with the Workload Identity
#      member identifier:
#
#        serviceAccount:PROJECT_ID.svc.id.goog[NAMESPACE/KSA_NAME]
#
#   4. Annotate the KSA (or rely on GKE's default binding in newer
#      versions) so pods get the GSA's identity.

resource "google_service_account" "workload_template" {
  account_id   = "${var.name_prefix}-workload-template"
  display_name = "OpenBI workload identity template service account"
  description  = "Template for pod-level GCP access via Workload Identity"

  project = var.project_id
}
