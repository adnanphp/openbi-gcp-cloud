output "repository_id" {
  description = "Repository ID"
  value       = google_artifact_registry_repository.this.repository_id
}

output "repository_name" {
  description = "Fully-qualified repository name"
  value       = google_artifact_registry_repository.this.name
}

output "repository_url" {
  description = "Docker pull/push URL (e.g. europe-west3-docker.pkg.dev/PROJECT/openbi)"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.this.repository_id}"
}

output "location" {
  description = "Region of the repository"
  value       = google_artifact_registry_repository.this.location
}
