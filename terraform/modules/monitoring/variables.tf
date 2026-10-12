# Inputs for the Cloud Monitoring module.
#
# Creates a dashboard, three alert policies, and an email notification
# channel. Alert policies cover:
#   - Cloud SQL CPU > threshold
#   - Pub/Sub DLQ backlog > 0
#   - Load Balancer 5xx rate > threshold

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
  description = "GCP region"
  type        = string
}

variable "notification_email" {
  description = "Email address for alert notifications (empty = no notification channel)"
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------
# Resources to monitor
# ----------------------------------------------------------------------

variable "cloud_sql_instance_name" {
  description = "Cloud SQL instance name"
  type        = string
}

variable "dlq_subscription_name" {
  description = "Pub/Sub DLQ subscription name"
  type        = string
}

variable "lb_name" {
  description = "Load balancer name (empty if no LB yet)"
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------
# Thresholds
# ----------------------------------------------------------------------

variable "sql_cpu_threshold" {
  description = "Cloud SQL CPU utilization threshold (percent)"
  type        = number
  default     = 80
}

variable "lb_5xx_threshold" {
  description = "Load balancer 5xx rate threshold (percent)"
  type        = number
  default     = 5
}

variable "labels" {
  description = "Labels applied to resources"
  type        = map(string)
  default     = {}
}
