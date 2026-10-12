output "fastapi_sa_email" {
  description = "GSA email for the FastAPI pod"
  value       = google_service_account.fastapi.email
}

output "fastapi_sa_name" {
  description = "Full GSA name"
  value       = google_service_account.fastapi.name
}
