# Secret Manager module for OpenBI.
#
# Creates the GCP service account (GSA) that External Secrets Operator
# assumes via Workload Identity to read secrets from Secret Manager.
# The GSA is scoped to secrets under a common prefix.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

data "google_project" "current" {
  project_id = var.project_id
}

# ----------------------------------------------------------------------
# Service account for External Secrets Operator
# ----------------------------------------------------------------------

resource "google_service_account" "eso" {
  account_id   = "${var.name_prefix}-eso"
  display_name = "External Secrets Operator"
  description  = "Reads OpenBI secrets from Secret Manager and materializes them as Kubernetes Secrets"

  project = var.project_id
}

# Grant Secret Manager accessor on secrets matching the prefix.
# GCP IAM conditions can scope by resource name.
resource "google_project_iam_member" "eso_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.eso.email}"

  condition {
    title       = "openbi-secrets-only"
    description = "Only allow access to secrets under the ${var.secret_path_prefix} prefix"
    expression  = "resource.name.startsWith('projects/${var.project_id}/secrets/${var.secret_path_prefix}')"
  }
}

# ----------------------------------------------------------------------
# Workload Identity binding (KSA → GSA)
# ----------------------------------------------------------------------
# Lets the ESO Kubernetes ServiceAccount assume this GCP service account.

resource "google_service_account_iam_member" "eso_workload_identity" {
  service_account_id = google_service_account.eso.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.eso_namespace}/${var.eso_service_account}]"
}
