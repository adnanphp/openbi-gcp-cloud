output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = module.vpc.network_name
}

output "subnet_self_link" {
  description = "Self link of the main subnet"
  value       = module.vpc.subnet_self_link
}

output "region" {
  description = "Region"
  value       = var.region
}

# ----------------------------------------------------------------------
# IAM outputs
# ----------------------------------------------------------------------

output "gke_nodes_sa_email" {
  description = "GKE node service account email"
  value       = module.iam.gke_nodes_sa_email
}

output "workload_template_sa_email" {
  description = "Base workload identity service account email"
  value       = module.iam.workload_template_sa_email
}

# ----------------------------------------------------------------------
# Artifact Registry outputs
# ----------------------------------------------------------------------

output "artifact_registry_url" {
  description = "Docker URL for the OpenBI Artifact Registry repository"
  value       = module.artifact_registry.repository_url
}

# ----------------------------------------------------------------------
# GKE outputs
# ----------------------------------------------------------------------

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster API endpoint"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_workload_identity_pool" {
  description = "Workload Identity pool identifier"
  value       = module.gke.workload_identity_pool
}

# ----------------------------------------------------------------------
# Cloud Storage outputs
# ----------------------------------------------------------------------

output "gcs_raw_bucket" {
  description = "Name of the raw data bucket"
  value       = module.storage.raw_bucket_name
}

output "gcs_processed_bucket" {
  description = "Name of the processed data bucket"
  value       = module.storage.processed_bucket_name
}

output "gcs_models_bucket" {
  description = "Name of the models bucket"
  value       = module.storage.models_bucket_name
}
