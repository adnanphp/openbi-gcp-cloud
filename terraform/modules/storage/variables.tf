# Inputs for the Cloud Storage module.
#
# Creates three buckets mirroring the OpenBI data lifecycle:
#   - raw: versioning on, tiered lifecycle (Nearline/Coldline/Archive)
#   - processed: versioning off, delete after N days
#   - models: versioning on, keep non-current versions for N days

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.name_prefix))
    error_message = "name_prefix must start with a letter, 3-32 chars, lowercase letters, digits, hyphens."
  }
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for bucket placement"
  type        = string
}

variable "bucket_suffix" {
  description = "Globally unique suffix for bucket names (typically the project ID)"
  type        = string
}

variable "raw_bucket_name" {
  description = "Base name for the raw data bucket"
  type        = string
  default     = "openbi-raw"
}

variable "processed_bucket_name" {
  description = "Base name for the processed data bucket"
  type        = string
  default     = "openbi-processed"
}

variable "models_bucket_name" {
  description = "Base name for the models bucket"
  type        = string
  default     = "openbi-models"
}

# Lifecycle tuning (days)
variable "raw_nearline_days" {
  description = "Days after which raw objects move to Nearline"
  type        = number
  default     = 30
}

variable "raw_coldline_days" {
  description = "Days after which raw objects move to Coldline"
  type        = number
  default     = 90
}

variable "raw_archive_days" {
  description = "Days after which raw objects move to Archive"
  type        = number
  default     = 365
}

variable "raw_expiration_days" {
  description = "Days after which raw objects are deleted"
  type        = number
  default     = 730
}

variable "processed_expiration_days" {
  description = "Days after which processed objects are deleted"
  type        = number
  default     = 90
}

variable "models_noncurrent_expiration_days" {
  description = "Days after which non-current model versions are deleted"
  type        = number
  default     = 90
}

# Access
variable "additional_reader_members" {
  description = "Additional IAM members granted storage.objectViewer on all three buckets (e.g. service accounts)"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels applied to all buckets"
  type        = map(string)
  default     = {}
}
