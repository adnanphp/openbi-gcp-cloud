# Inputs for the Cloud Logging module.
#
# Creates:
#   - A log sink that routes OpenBI logs to a dedicated bucket
#   - A log bucket with configurable retention
#   - Log-based metrics (error count, latency P99)

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

variable "location" {
  description = "Location for the log bucket (e.g. 'europe-west3' or 'global')"
  type        = string
  default     = "global"
}

variable "retention_days" {
  description = "Log retention in days (1-3650)"
  type        = number
  default     = 30

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 3650
    error_message = "retention_days must be between 1 and 3650."
  }
}

variable "log_filter" {
  description = "Filter for the log sink (which logs to route to the bucket)"
  type        = string
  default     = "resource.type=\"k8s_container\" AND resource.labels.namespace_name=\"openbi\""
}

variable "labels" {
  description = "Labels applied to the bucket"
  type        = map(string)
  default     = {}
}
