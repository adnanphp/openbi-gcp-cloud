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

# ----------------------------------------------------------------------
# Cloud Storage
# ----------------------------------------------------------------------

module "storage" {
  source = "../../modules/storage"

  name_prefix   = local.name_prefix
  project_id    = var.project_id
  region        = var.region
  bucket_suffix = var.resource_suffix

  labels = local.common_labels
}

# ----------------------------------------------------------------------
# Cloud SQL
# ----------------------------------------------------------------------

module "cloud_sql" {
  source = "../../modules/cloud-sql"

  name_prefix = local.name_prefix
  project_id  = var.project_id
  region      = var.region

  instance_name     = "openbi-dev-pg"
  database_version  = "POSTGRES_16"
  tier              = "db-f1-micro"
  disk_size_gb      = 20
  availability_type = "ZONAL"

  backup_retention_days = 7
  deletion_protection   = false

  database_name = "openbi"
  database_user = "openbiadmin"

  network_id        = module.vpc.network_id
  network_self_link = module.vpc.network_name # Cloud SQL wants the self link or name; see output

  create_private_service_access = true

  labels = local.common_labels
}

# ----------------------------------------------------------------------
# Pub/Sub
# ----------------------------------------------------------------------

module "pubsub" {
  source = "../../modules/pubsub"

  name_prefix  = local.name_prefix
  project_id   = var.project_id
  topic_name   = "openbi-events"
  topic_suffix = var.resource_suffix

  ack_deadline_seconds   = 60
  message_retention_days = 7
  max_delivery_attempts  = 5
  dlq_retention_days     = 7

  labels = local.common_labels
}

# ----------------------------------------------------------------------
# Load Balancing
# ----------------------------------------------------------------------

module "load_balancing" {
  source = "../../modules/load-balancing"

  name_prefix = local.name_prefix
  project_id  = var.project_id
  region      = var.region

  # Reserve an external static IP for the LB.
  reserve_external_ip = true
  external_ip_name    = "openbi-dev-lb-ip"

  # Internal LB is optional; disabled by default.
  reserve_internal_ip = false

  # Managed certificate — empty for HTTP-only (lab default).
  domain_name = ""

  labels = local.common_labels
}

# ----------------------------------------------------------------------
# Cloud Logging
# ----------------------------------------------------------------------

module "logging" {
  source = "../../modules/logging"

  name_prefix = local.name_prefix
  project_id  = var.project_id
  location    = "global"

  retention_days = 30

  labels = local.common_labels
}

# ----------------------------------------------------------------------
# Cloud Monitoring
# ----------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix = local.name_prefix
  project_id  = var.project_id
  region      = var.region

  # Set to a real email to receive alerts.
  notification_email = ""

  cloud_sql_instance_name = module.cloud_sql.instance_name
  dlq_subscription_name   = "${module.pubsub.dlq_topic_name}-sub-${var.resource_suffix}"

  # LB name is set once the LB exists (Phase G10).
  lb_name = ""

  sql_cpu_threshold = 80
  lb_5xx_threshold  = 5
}

# ----------------------------------------------------------------------
# Secrets (External Secrets Operator Workload Identity)
# ----------------------------------------------------------------------

module "secrets" {
  source = "../../modules/secrets"

  name_prefix = local.name_prefix
  project_id  = var.project_id

  secret_path_prefix = "openbi/dev"
}
