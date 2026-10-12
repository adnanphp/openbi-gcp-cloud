# Inputs for the Workload Identity module.
#
# Creates the GSA for the FastAPI pod and grants it:
#   - Storage access to openbi-* buckets
#   - Cloud SQL client (for the Auth Proxy sidecar)
#   - Secret Manager accessor (via ESO, but also direct for emergencies)
#
# Binds the GSA to the Kubernetes ServiceAccount `openbi/fastapi`.

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.name_prefix))
    error_message = "name_prefix must start with a letter, 3-32 chars, lowercase letters, digits, hyphens."
  }
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the workload"
  type        = string
  default     = "openbi"
}

variable "kubernetes_service_account" {
  description = "Kubernetes ServiceAccount name"
  type        = string
  default     = "fastapi"
}

variable "storage_bucket_prefix" {
  description = "Prefix of buckets the workload can access (e.g. 'openbi-')"
  type        = string
  default     = "openbi-"
}
