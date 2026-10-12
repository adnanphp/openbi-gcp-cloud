output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "ID of the main subnet"
  value       = google_compute_subnetwork.main.id
}

output "subnet_name" {
  description = "Name of the main subnet"
  value       = google_compute_subnetwork.main.name
}

output "subnet_self_link" {
  description = "Self link of the main subnet (used by GKE)"
  value       = google_compute_subnetwork.main.self_link
}

output "pods_secondary_range_name" {
  description = "Name of the pods secondary range"
  value       = "pods"
}

output "services_secondary_range_name" {
  description = "Name of the services secondary range"
  value       = "services"
}

output "region" {
  description = "Region of the subnet"
  value       = google_compute_subnetwork.main.region
}
