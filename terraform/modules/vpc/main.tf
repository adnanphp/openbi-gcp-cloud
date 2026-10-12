# GCP VPC module for OpenBI.
#
# Creates:
#   - A custom-mode VPC network
#   - One regional subnet with secondary ranges for GKE pods/services
#   - Cloud Router + Cloud NAT for egress
#   - VPC Flow Logs (optional)
#   - Firewall rules for GKE and internal access
#
# Design notes:
#   - Custom mode (not auto mode) for explicit control.
#   - Secondary ranges on the subnet are required for GKE VPC-native
#     clusters; this is the GKE default and recommended mode.
#   - Cloud NAT provides egress for private nodes without public IPs.
#   - GKE has no notion of "public" vs "private" subnets like AWS; the
#     distinction comes from whether nodes have external IPs, which GKE
#     controls at the node pool level.

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
# VPC network
# ----------------------------------------------------------------------

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  description = "OpenBI VPC (${var.name_prefix})"
}

# ----------------------------------------------------------------------
# Subnet with secondary ranges for GKE
# ----------------------------------------------------------------------

resource "google_compute_subnetwork" "main" {
  name          = "${var.name_prefix}-subnet-${var.region}"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr

  # GKE requires secondary ranges for VPC-native clusters.
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  # VPC Flow Logs
  log_config {
    aggregation_interval = var.enable_flow_logs ? var.flow_logs_aggregation_interval : null
    flow_sampling        = var.enable_flow_logs ? var.flow_logs_sampling : null
    metadata             = var.enable_flow_logs ? "INCLUDE_ALL_METADATA" : null
  }

  private_ip_google_access = true
}

# ----------------------------------------------------------------------
# Cloud Router + Cloud NAT
# ----------------------------------------------------------------------

resource "google_compute_router" "router" {
  name    = "${var.name_prefix}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.name_prefix}-nat"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ----------------------------------------------------------------------
# Firewall rules
# ----------------------------------------------------------------------

# Allow internal traffic within the VPC.
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.name_prefix}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc.name

  direction = "INGRESS"
  priority  = 1000

  source_ranges = [
    var.subnet_cidr,
    var.pods_cidr,
    var.services_cidr,
  ]

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}

# Allow SSH via IAP (Identity-Aware Proxy) — no public SSH port.
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.name_prefix}-allow-iap-ssh"
  project = var.project_id
  network = google_compute_network.vpc.name

  direction = "INGRESS"
  priority  = 1000

  # Google's IAP source range.
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
