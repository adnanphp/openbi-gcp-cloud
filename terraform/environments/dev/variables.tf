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
  description = "Globally unique suffix for resource names that require it"
  type        = string
  default     = "REPLACE-WITH-PROJECT-ID"
}
