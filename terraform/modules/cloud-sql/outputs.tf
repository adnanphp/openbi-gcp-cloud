output "instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.this.name
}

output "instance_connection_name" {
  description = "Connection name (used by the Cloud SQL Auth Proxy)"
  value       = google_sql_database_instance.this.connection_name
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = google_sql_database_instance.this.private_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Name of the application database"
  value       = google_sql_database.this.name
}

output "database_user" {
  description = "Name of the application database user"
  value       = google_sql_user.app_user.name
}

output "credentials_secret_id" {
  description = "Secret Manager secret ID holding the credentials"
  value       = google_secret_manager_secret.db_credentials.secret_id
}

output "psa_range_name" {
  description = "Name of the Private Service Access reserved IP range"
  value       = var.create_private_service_access ? google_compute_global_address.psa[0].name : null
}
