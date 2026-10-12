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
