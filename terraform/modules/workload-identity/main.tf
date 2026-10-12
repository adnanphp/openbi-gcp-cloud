# Workload Identity module for OpenBI workloads.
#
# Creates a GSA for a pod, grants it specific roles, and binds it to a
# Kubernetes ServiceAccount. This is the pod-level identity that
# replaces service account keys.

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
# GSA
# ----------------------------------------------------------------------

resource "google_service_account" "fastapi" {
  account_id   = "${var.name_prefix}-fastapi"
  display_name = "OpenBI FastAPI workload"
  description  = "Service account for the OpenBI FastAPI pod"

  project = var.project_id
}

# ----------------------------------------------------------------------
# IAM roles
# ----------------------------------------------------------------------

# Storage access scoped to buckets matching the prefix.
resource "google_project_iam_member" "storage_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.fastapi.email}"

  condition {
    title       = "openbi-buckets-only"
    description = "Only buckets under the ${var.storage_bucket_prefix} prefix"
    expression  = "resource.name.startsWith('projects/_/buckets/${var.storage_bucket_prefix}')"
  }
}

# Cloud SQL client — needed by the Auth Proxy sidecar.
resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.fastapi.email}"
}

# Secret Manager accessor — needed for direct reads (usually via ESO).
resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.fastapi.email}"

  condition {
    title       = "openbi-secrets-only"
    description = "Only secrets under openbi/dev/"
    expression  = "resource.name.startsWith('projects/${var.project_id}/secrets/openbi/dev')"
  }
}

# ----------------------------------------------------------------------
# Workload Identity binding (KSA → GSA)
# ----------------------------------------------------------------------

resource "google_service_account_iam_member" "fastapi_ksa_binding" {
  service_account_id = google_service_account.fastapi.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.kubernetes_service_account}]"
}
