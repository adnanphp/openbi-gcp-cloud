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
