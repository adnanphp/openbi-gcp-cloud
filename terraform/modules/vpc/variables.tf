# Inputs for the GCP VPC module.
#
# Creates a custom-mode VPC with regional subnets, Cloud NAT, and VPC
# Flow Logs. The layout mirrors the AWS VPC module (A1) so the two
# clouds are architecturally comparable.

variable "name_prefix" {
  description = "Prefix for all resource names"
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
  default     = "europe-west3"
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "openbi-vpc"
}

variable "subnet_cidr" {
  description = "Primary CIDR range for the main subnet"
  type        = string
  default     = "10.30.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary CIDR for GKE pods"
  type        = string
  default     = "10.40.0.0/14"
}

variable "services_cidr" {
  description = "Secondary CIDR for GKE services"
  type        = string
  default     = "10.44.0.0/20"
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs on the subnet"
  type        = bool
  default     = true
}

variable "flow_logs_aggregation_interval" {
  description = "Flow logs aggregation interval (INTERVAL_5_SEC, INTERVAL_30_SEC, INTERVAL_1_MIN, INTERVAL_5_MIN, INTERVAL_10_MIN, INTERVAL_15_MIN)"
  type        = string
  default     = "INTERVAL_5_SEC"
}

variable "flow_logs_sampling" {
  description = "Flow logs sampling rate (0.0 to 1.0)"
  type        = number
  default     = 0.5
}

variable "tags" {
  description = "Common labels applied to all resources"
  type        = map(string)
  default     = {}
}
