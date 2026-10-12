# GKE module for OpenBI.
#
# Creates a regional GKE Standard cluster with Workload Identity, two
# node pools (primary + spot), and observability enabled.
#
# Design notes:
#   - Standard (not Autopilot): shows node pool configuration explicitly.
#   - Regional: control plane spread across three zones.
#   - Private nodes: no external IPs; egress via Cloud NAT (G1).
#   - Workload Identity: required for pod-level GCP access.
#   - Shielded nodes: vTPM-based integrity, enabled by default.
#   - Cluster Autoscaler: enabled on the spot pool only.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

data "google_project" "current" {
  project_id = var.project_id
}

# ----------------------------------------------------------------------
# Cluster
# ----------------------------------------------------------------------

resource "google_container_cluster" "this" {
  name     = var.cluster_name
  project  = var.project_id
  location = var.region

  # Regional cluster (control plane across 3 zones).
  node_locations = []

  # We manage node pools separately.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_id
  subnetwork = var.subnet_id

  # Private nodes — no external IPs.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # VPC-native networking with secondary ranges for pods and services.
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Workload Identity.
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Release channel for automatic upgrades.
  release_channel {
    channel = var.release_channel
  }

  # Kubernetes version override (empty = default for the release channel).
  min_master_version = var.kubernetes_version != "" ? var.kubernetes_version : null

  # Shielded nodes.
  enable_shielded_nodes = true

  # Observability.
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]

    managed_prometheus {
      enabled = true
    }
  }

  # Addons.
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    gcp_filestore_csi_driver_config {
      enabled = false
    }

    gcs_fuse_csi_driver_config {
      enabled = false
    }
  }

  # Access to the control plane.
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []

    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Deletion protection.
  deletion_protection = var.deletion_protection

  resource_labels = var.labels

  # Allow the cluster to be destroyed cleanly. Without this, a
  # `terraform destroy` may fail on resources the API server created
  # (persistent disks, load balancers).
  # These are safe defaults for a lab; production should be more careful.
  lifecycle {
    ignore_changes = [
      # Ignore the initial node count after creation.
      initial_node_count,
    ]
  }

  # Database encryption (default: Google-managed keys).
  # Customer-managed encryption keys (CMEK) can be added later.
}

# ----------------------------------------------------------------------
# Primary node pool
# ----------------------------------------------------------------------

resource "google_container_node_pool" "primary" {
  name     = "${var.cluster_name}-primary"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.this.name

  # Regional node pool: min/max are per zone, so total = value * 3.
  node_count = null

  autoscaling {
    min_node_count = var.primary_min_nodes
    max_node_count = var.primary_max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type    = var.primary_machine_type
    disk_size_gb    = var.primary_disk_size_gb
    disk_type       = "pd-balanced"
    image_type      = "COS_CONTAINERD"
    service_account = var.node_service_account_email

    # No external IP; egress via Cloud NAT.
    # The subnet already has private_ip_google_access = true.
    # GKE sets this automatically for private clusters, but being explicit.
    tags = ["gke-node", "${var.cluster_name}-primary"]

    # OAuth scopes. Minimal set. Workload Identity handles per-pod access.
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = var.labels

    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Enable GKE metadata server (required for Workload Identity).
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# ----------------------------------------------------------------------
# Spot node pool
# ----------------------------------------------------------------------

resource "google_container_node_pool" "spot" {
  name     = "${var.cluster_name}-spot"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.this.name

  node_count = null

  autoscaling {
    min_node_count = var.spot_min_nodes
    max_node_count = var.spot_max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type    = var.spot_machine_type
    disk_size_gb    = var.spot_disk_size_gb
    disk_type       = "pd-balanced"
    image_type      = "COS_CONTAINERD"
    service_account = var.node_service_account_email

    # Spot VMs.
    spot = true

    tags = ["gke-node", "${var.cluster_name}-spot"]

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = var.labels

    metadata = {
      disable-legacy-endpoints = "true"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    taint {
      key    = "cloud.google.com/gke-spot"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }
}
