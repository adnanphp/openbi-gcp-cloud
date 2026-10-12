# Inputs for the GCP IAM module.
#
# Creates service accounts for GKE nodes and a base workload identity
# service account for pods. The Workload Identity pool itself is created
# by GKE (Phase G4) — this module defines the SAs that will be bound to
# it.

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
