# Inputs for the Pub/Sub module.
#
# Creates:
#   - Main topic + subscription
#   - Dead-letter topic + subscription
#   - IAM bindings for the node service account (publish, subscribe)
#
# Design mirrors the AWS SQS module: main + DLQ, delivery attempts
# trigger DLQ routing, long polling on the consumer side.

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

variable "topic_name" {
  description = "Base name for the main topic"
  type        = string
  default     = "openbi-events"
}

variable "topic_suffix" {
  description = "Suffix for topic names (typically project ID, for readability)"
  type        = string
}

# ----------------------------------------------------------------------
# Subscription behavior
# ----------------------------------------------------------------------

variable "ack_deadline_seconds" {
  description = "Time a message is invisible after delivery before redelivery (10-600)"
  type        = number
  default     = 60

  validation {
    condition     = var.ack_deadline_seconds >= 10 && var.ack_deadline_seconds <= 600
    error_message = "ack_deadline_seconds must be between 10 and 600."
  }
}

variable "message_retention_days" {
  description = "How long Pub/Sub retains unacked messages (1-7 days)"
  type        = number
  default     = 7

  validation {
    condition     = var.message_retention_days >= 1 && var.message_retention_days <= 7
    error_message = "message_retention_days must be between 1 and 7."
  }
}

variable "retain_acked_messages" {
  description = "Retain acked messages for the retention window (for replay)"
  type        = bool
  default     = false
}

variable "expiration_ttl_days" {
  description = "Subscription expiration if no activity (empty = never expires)"
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------
# Dead-letter behavior
# ----------------------------------------------------------------------

variable "max_delivery_attempts" {
  description = "Delivery attempts before a message goes to the DLQ (5-100)"
  type        = number
  default     = 5

  validation {
    condition     = var.max_delivery_attempts >= 5 && var.max_delivery_attempts <= 100
    error_message = "max_delivery_attempts must be between 5 and 100."
  }
}

variable "dlq_retention_days" {
  description = "Retention for the DLQ subscription (1-7 days)"
  type        = number
  default     = 7

  validation {
    condition     = var.dlq_retention_days >= 1 && var.dlq_retention_days <= 7
    error_message = "dlq_retention_days must be between 1 and 7."
  }
}

# ----------------------------------------------------------------------
# Access
# ----------------------------------------------------------------------

variable "publisher_members" {
  description = "IAM members granted roles/pubsub.publisher on the main topic"
  type        = list(string)
  default     = []
}

variable "subscriber_members" {
  description = "IAM members granted roles/pubsub.subscriber on the main subscription"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels applied to topics and subscriptions"
  type        = map(string)
  default     = {}
}
