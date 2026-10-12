output "raw_bucket_name" {
  description = "Name of the raw bucket"
  value       = google_storage_bucket.raw.name
}

output "raw_bucket_url" {
  description = "gs:// URL of the raw bucket"
  value       = "gs://${google_storage_bucket.raw.name}"
}

output "processed_bucket_name" {
  description = "Name of the processed bucket"
  value       = google_storage_bucket.processed.name
}

output "processed_bucket_url" {
  description = "gs:// URL of the processed bucket"
  value       = "gs://${google_storage_bucket.processed.name}"
}

output "models_bucket_name" {
  description = "Name of the models bucket"
  value       = google_storage_bucket.models.name
}

output "models_bucket_url" {
  description = "gs:// URL of the models bucket"
  value       = "gs://${google_storage_bucket.models.name}"
}
