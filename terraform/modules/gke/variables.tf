# Inputs for the GKE module.
#
# Creates:
#   - A regional GKE Standard cluster with Workload Identity
#   - Two node pools: primary (on-demand) + spot (autoscaling)
#   - Private nodes with Cloud NAT egress
#   - Shielded nodes enabled
#
# Depends on:
#   - VPC module (network, subnet, secondary ranges)
#   - IAM module (node service account)

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

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "openbi-dev"
}

variable "kubernetes_version" {
  description = "Kubernetes version prefix (empty = GKE default for the release channel)"
  type        = string
  default     = ""
}

variable "release_channel" {
  description = "GKE release channel: RAPID, REGULAR, STABLE"
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be RAPID, REGULAR, or STABLE."
  }
}

variable "network_id" {
  description = "VPC network ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID (must have pods/services secondary ranges)"
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the pods secondary range on the subnet"
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the services secondary range on the subnet"
  type        = string
}

variable "node_service_account_email" {
  description = "Service account email for GKE nodes"
  type        = string
}

# ----------------------------------------------------------------------
# Primary node pool
# ----------------------------------------------------------------------

variable "primary_machine_type" {
  description = "Machine type for the primary node pool"
  type        = string
  default     = "e2-medium"
}

variable "primary_min_nodes" {
  description = "Minimum nodes in the primary pool (per zone)"
  type        = number
  default     = 1
}

variable "primary_max_nodes" {
  description = "Maximum nodes in the primary pool (per zone)"
  type        = number
  default     = 3
}

variable "primary_disk_size_gb" {
  description = "Boot disk size for primary nodes"
  type        = number
  default     = 50
}

# ----------------------------------------------------------------------
# Spot node pool
# ----------------------------------------------------------------------

variable "spot_machine_type" {
  description = "Machine type for the spot node pool"
  type        = string
  default     = "e2-medium"
}

variable "spot_min_nodes" {
  description = "Minimum nodes in the spot pool (0 for scale-to-zero)"
  type        = number
  default     = 0
}

variable "spot_max_nodes" {
  description = "Maximum nodes in the spot pool"
  type        = number
  default     = 5
}

variable "spot_disk_size_gb" {
  description = "Boot disk size for spot nodes"
  type        = number
  default     = 50
}

variable "master_authorized_networks" {
  description = "CIDRs allowed to reach the cluster API server (empty = all, subject to other controls)"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_private_endpoint" {
  description = "Make the cluster API server private (reachable only from within the VPC)"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the cluster"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels applied to cluster and node pools"
  type        = map(string)
  default     = {}
}
