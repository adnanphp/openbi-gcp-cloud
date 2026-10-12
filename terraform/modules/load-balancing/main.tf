# Load balancing module for GKE.
#
# On GKE, load balancers are provisioned by GKE when an Ingress is
# applied. Unlike AWS (where you install the AWS Load Balancer
# Controller), GKE has this built in.
#
# This module reserves static IPs that Ingress resources reference.
# The Ingress itself lives in the OpenBI application manifests (Phase
# G10) and is created by kubectl, not Terraform.

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
# Global external IP (for external Ingress)
# ----------------------------------------------------------------------

resource "google_compute_global_address" "external_lb" {
  count = var.reserve_external_ip ? 1 : 0

  name    = var.external_ip_name
  project = var.project_id

  address_type = "EXTERNAL"
  ip_version   = "IPV4"

  labels = var.labels
}

# ----------------------------------------------------------------------
# Regional internal IP (for internal Ingress)
# ----------------------------------------------------------------------

resource "google_compute_address" "internal_lb" {
  count = var.reserve_internal_ip ? 1 : 0

  name         = var.internal_ip_name
  project      = var.project_id
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = var.internal_ip_subnet_self_link

  labels = var.labels
}
