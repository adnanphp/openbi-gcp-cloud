# Pub/Sub module for OpenBI.
#
# Creates a main topic + subscription and a dead-letter topic +
# subscription. Messages that exceed max_delivery_attempts are moved to
# the DLQ topic.
#
# Design notes:
#   - Pub/Sub has no "queue" — only topics (producers write) and
#     subscriptions (consumers read). One subscription on a topic is
#     the closest thing to a work queue.
#   - The DLQ requires its own subscription; without one, Pub/Sub
#     deletes messages published to the DLQ topic.
#   - Pub/Sub creates its own service account internally. To use a DLQ,
#     that service account needs publish access on the DLQ topic and
#     subscribe access on the main subscription.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# ----------------------------------------------------------------------
# Main topic and subscription
# ----------------------------------------------------------------------

resource "google_pubsub_topic" "main" {
  name    = "${var.topic_name}-${var.topic_suffix}"
  project = var.project_id

  labels = var.labels

  # Message retention for the topic itself (distinct from subscription
  # retention; the topic retention applies to unacked messages still
  # attached to the topic).
  message_retention_duration = "${var.message_retention_days * 86400}s"
}

resource "google_pubsub_subscription" "main" {
  name    = "${var.topic_name}-sub-${var.topic_suffix}"
  project = var.project_id
  topic   = google_pubsub_topic.main.id

  ack_deadline_seconds       = var.ack_deadline_seconds
  message_retention_duration = "${var.message_retention_days * 86400}s"
  retain_acked_messages      = var.retain_acked_messages

  # Dead-letter policy: forward to the DLQ topic after N attempts.
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq.id
    max_delivery_attempts = var.max_delivery_attempts
  }

  # Optional expiration (empty = never).
  expiration_policy {
    ttl = var.expiration_ttl_days != "" ? "${var.expiration_ttl_days * 86400}s" : ""
  }

  labels = var.labels
}

# ----------------------------------------------------------------------
# Dead-letter topic and subscription
# ----------------------------------------------------------------------

resource "google_pubsub_topic" "dlq" {
  name    = "${var.topic_name}-dlq-${var.topic_suffix}"
  project = var.project_id

  labels = var.labels

  message_retention_duration = "${var.dlq_retention_days * 86400}s"
}

resource "google_pubsub_subscription" "dlq" {
  name    = "${var.topic_name}-dlq-sub-${var.topic_suffix}"
  project = var.project_id
  topic   = google_pubsub_topic.dlq.id

  ack_deadline_seconds       = var.ack_deadline_seconds
  message_retention_duration = "${var.dlq_retention_days * 86400}s"

  labels = var.labels
}

# ----------------------------------------------------------------------
# Pub/Sub service agent IAM
# ----------------------------------------------------------------------
# Pub/Sub uses a Google-managed service account (service-PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com)
# to perform DLQ forwarding. It needs:
#   - publisher on the DLQ topic
#   - subscriber on the main subscription

data "google_project" "current" {
  project_id = var.project_id
}

locals {
  pubsub_service_agent = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.dlq.name
  role    = "roles/pubsub.publisher"
  member  = local.pubsub_service_agent
}

resource "google_pubsub_subscription_iam_member" "main_subscriber_for_dlq" {
  project      = var.project_id
  subscription = google_pubsub_subscription.main.name
  role         = "roles/pubsub.subscriber"
  member       = local.pubsub_service_agent
}

# ----------------------------------------------------------------------
# Application IAM bindings
# ----------------------------------------------------------------------

resource "google_pubsub_topic_iam_member" "main_publishers" {
  for_each = toset(var.publisher_members)

  project = var.project_id
  topic   = google_pubsub_topic.main.name
  role    = "roles/pubsub.publisher"
  member  = each.value
}

resource "google_pubsub_subscription_iam_member" "main_subscribers" {
  for_each = toset(var.subscriber_members)

  project      = var.project_id
  subscription = google_pubsub_subscription.main.name
  role         = "roles/pubsub.subscriber"
  member       = each.value
}
