variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "REPLACE-WITH-GCP-PROJECT-ID"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west3"
}

variable "resource_suffix" {
  description = "Globally unique suffix for GCS bucket names (typically the GCP project ID)"
  type        = string
  default     = "REPLACE-WITH-PROJECT-ID"
}
