output "gke_nodes_sa_email" {
  description = "Email of the GKE node service account"
  value       = google_service_account.gke_nodes.email
}

output "gke_nodes_sa_name" {
  description = "Fully-qualified name of the GKE node service account"
  value       = google_service_account.gke_nodes.name
}

output "gke_nodes_sa_id" {
  description = "Account ID of the GKE node service account"
  value       = google_service_account.gke_nodes.account_id
}

output "workload_template_sa_email" {
  description = "Email of the base workload identity service account"
  value       = google_service_account.workload_template.email
}
