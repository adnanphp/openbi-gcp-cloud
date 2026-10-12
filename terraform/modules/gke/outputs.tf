output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.this.name
}

output "cluster_id" {
  description = "ID of the GKE cluster"
  value       = google_container_cluster.this.id
}

output "cluster_endpoint" {
  description = "HTTPS endpoint of the cluster API server"
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate"
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Region of the cluster"
  value       = google_container_cluster.this.location
}

output "workload_identity_pool" {
  description = "Workload Identity pool (used in GSA↔KSA bindings)"
  value       = "${var.project_id}.svc.id.goog"
}

output "primary_node_pool_name" {
  description = "Name of the primary node pool"
  value       = google_container_node_pool.primary.name
}

output "spot_node_pool_name" {
  description = "Name of the spot node pool"
  value       = google_container_node_pool.spot.name
}
