# OpenBI GCP — dev environment.
#
# Composition layer. Wires modules together with environment-specific
# values. Phase G1 (current): VPC only. Future phases add: GKE, Artifact
# Registry, GCS, Cloud SQL, Pub/Sub, Load Balancing, Cloud Logging, Secret Manager.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  common_labels = {
    project     = "openbi"
    environment = "dev"
    managed_by  = "terraform"
    repository  = "github.com/adnanphp/openbi-gcp-cloud"
  }

  name_prefix = "openbi-dev"
}

# ----------------------------------------------------------------------
# VPC
# ----------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  name_prefix = local.name_prefix
  project_id  = var.project_id
  region      = var.region

  vpc_name      = "openbi-dev-vpc"
  subnet_cidr   = "10.30.0.0/20"
  pods_cidr     = "10.40.0.0/14"
  services_cidr = "10.44.0.0/20"

  enable_flow_logs = true

  tags = local.common_labels
}

# ----------------------------------------------------------------------
# IAM
# ----------------------------------------------------------------------

module "iam" {
  source = "../../modules/iam"

  name_prefix = local.name_prefix
  project_id  = var.project_id
}

# ----------------------------------------------------------------------
# Artifact Registry
# ----------------------------------------------------------------------

module "artifact_registry" {
  source = "../../modules/artifact-registry"

  name_prefix   = local.name_prefix
  project_id    = var.project_id
  region        = var.region
  repository_id = "openbi"

  labels = local.common_labels
}

# ----------------------------------------------------------------------
# GKE
# ----------------------------------------------------------------------

module "gke" {
  source = "../../modules/gke"

  name_prefix = local.name_prefix
  project_id  = var.project_id
  region      = var.region

  cluster_name       = "openbi-dev"
  release_channel    = "REGULAR"
  kubernetes_version = ""

  network_id = module.vpc.network_id
  subnet_id  = module.vpc.subnet_id

  pods_secondary_range_name     = module.vpc.pods_secondary_range_name
  services_secondary_range_name = module.vpc.services_secondary_range_name

  node_service_account_email = module.iam.gke_nodes_sa_email

  # Dev sizing: small VMs, spot pool scales from 0.
  primary_machine_type = "e2-medium"
  primary_min_nodes    = 1
  primary_max_nodes    = 3
  primary_disk_size_gb = 50

  spot_machine_type = "e2-medium"
  spot_min_nodes    = 0
  spot_max_nodes    = 5
  spot_disk_size_gb = 50

  # Private endpoint only by default.
  enable_private_endpoint = false

  # No deletion protection in dev.
  deletion_protection = false

  labels = local.common_labels
}
