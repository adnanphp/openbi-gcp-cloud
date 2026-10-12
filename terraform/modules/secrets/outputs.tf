output "eso_service_account_email" {
  description = "GSA email for External Secrets Operator"
  value       = google_service_account.eso.email
}

output "eso_service_account_name" {
  description = "Full GSA name"
  value       = google_service_account.eso.name
}

output "secret_path_prefix" {
  description = "Prefix under which OpenBI secrets should be stored"
  value       = var.secret_path_prefix
}
