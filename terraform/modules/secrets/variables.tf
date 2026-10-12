# Inputs for the Secret Manager module.
#
# Provides the Workload Identity service account that External Secrets
# Operator assumes to read secrets from Secret Manager. The secrets
# themselves are created by the modules that own them (e.g. Cloud SQL
# creates openbi/dev/db).

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

variable "secret_path_prefix" {
  description = "Prefix for all OpenBI secrets (used to scope IAM)"
  type        = string
  default     = "openbi/dev"
}

variable "eso_namespace" {
  description = "Namespace of External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "eso_service_account" {
  description = "ServiceAccount name for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}
