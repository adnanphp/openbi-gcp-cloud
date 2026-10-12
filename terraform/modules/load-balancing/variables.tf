# Inputs for the load balancing module.
#
# On GKE, the load balancer itself is created by GKE when an Ingress is
# applied — not by Terraform. This module reserves a static IP and
# (optionally) sets up a managed certificate, both of which the Ingress
# references.

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
  description = "GCP region (for the internal static IP)"
  type        = string
}

# ----------------------------------------------------------------------
# External load balancing
# ----------------------------------------------------------------------

variable "reserve_external_ip" {
  description = "Reserve a global static external IP for the load balancer"
  type        = bool
  default     = true
}

variable "external_ip_name" {
  description = "Name of the global static external IP"
  type        = string
  default     = "openbi-dev-lb-ip"
}

# ----------------------------------------------------------------------
# Internal load balancing
# ----------------------------------------------------------------------

variable "reserve_internal_ip" {
  description = "Reserve a regional static internal IP for internal load balancing"
  type        = bool
  default     = false
}

variable "internal_ip_name" {
  description = "Name of the regional static internal IP"
  type        = string
  default     = "openbi-dev-lb-internal-ip"
}

variable "internal_ip_subnet_self_link" {
  description = "Subnet self link for the internal IP (required if reserve_internal_ip is true)"
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------
# Managed certificate (optional, requires a domain)
# ----------------------------------------------------------------------

variable "domain_name" {
  description = "Domain for the managed certificate (empty = no certificate)"
  type        = string
  default     = ""
}

variable "certificate_name" {
  description = "Name of the Kubernetes ManagedCertificate resource"
  type        = string
  default     = "openbi-dev-cert"
}

variable "labels" {
  description = "Labels applied to resources"
  type        = map(string)
  default     = {}
}
