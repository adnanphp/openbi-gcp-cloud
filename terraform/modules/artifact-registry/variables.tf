# Inputs for the Artifact Registry module.
#
# Creates a Docker-format repository for OpenBI container images.

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

variable "region" {
  description = "GCP region for the repository (must match the GKE cluster region)"
  type        = string
}

variable "repository_id" {
  description = "Repository ID (short name)"
  type        = string
  default     = "openbi"
}

variable "keep_last_tagged" {
  description = "Number of tagged image versions to keep"
  type        = number
  default     = 10
}

variable "delete_untagged_after_days" {
  description = "Days after which untagged images are deleted"
  type        = number
  default     = 7
}

variable "labels" {
  description = "Labels applied to the repository"
  type        = map(string)
  default     = {}
}
