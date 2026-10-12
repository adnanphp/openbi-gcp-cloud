# Inputs for the Cloud SQL module.
#
# Creates a Cloud SQL PostgreSQL instance with private IP, IAM database
# authentication, backups, and tuned flags. The password for the default
# user is generated and stored in Secret Manager.

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
  description = "GCP region"
  type        = string
}

variable "instance_name" {
  description = "Cloud SQL instance name"
  type        = string
  default     = "openbi-dev-pg"
}

variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_16"
}

variable "tier" {
  description = "Machine tier (db-f1-micro for dev, db-custom-* for production)"
  type        = string
  default     = "db-f1-micro"
}

variable "disk_size_gb" {
  description = "Initial disk size in GB"
  type        = number
  default     = 20
}

variable "disk_autoresize" {
  description = "Automatically grow disk when nearing capacity"
  type        = bool
  default     = true
}

variable "availability_type" {
  description = "ZONAL (single zone) or REGIONAL (HA with automatic failover)"
  type        = string
  default     = "ZONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "availability_type must be ZONAL or REGIONAL."
  }
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups (1-365)"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the instance"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "openbi"
}

variable "database_user" {
  description = "Name of the default database user"
  type        = string
  default     = "openbiadmin"
}

variable "network_id" {
  description = "VPC network ID (for Private Service Access)"
  type        = string
}

variable "network_self_link" {
  description = "VPC network self link"
  type        = string
}

# ----------------------------------------------------------------------
# Private Service Access
# ----------------------------------------------------------------------
# Cloud SQL with private IP requires a VPC peering to Google's service
# network. This is done once per VPC. Set to false if another module
# manages it.

variable "create_private_service_access" {
  description = "Create the Private Service Access peering (set to false if it already exists)"
  type        = bool
  default     = true
}

variable "psa_address_name" {
  description = "Name of the reserved IP range for Private Service Access"
  type        = string
  default     = "google-managed-services"
}

variable "psa_prefix_length" {
  description = "Prefix length for the PSA range (must be /24 or larger, but Cloud SQL requires /24 in practice)"
  type        = number
  default     = 16
}

variable "labels" {
  description = "Labels applied to the instance"
  type        = map(string)
  default     = {}
}
