# Cloud Monitoring module for OpenBI.
#
# Creates a dashboard, three alert policies, and an optional email
# notification channel.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

data "google_project" "current" {
  project_id = var.project_id
}

# ----------------------------------------------------------------------
# Notification channel
# ----------------------------------------------------------------------

resource "google_monitoring_notification_channel" "email" {
  count = var.notification_email != "" ? 1 : 0

  project      = var.project_id
  display_name = "${var.name_prefix} email alerts"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}

locals {
  channel_ids = var.notification_email != "" ? [google_monitoring_notification_channel.email[0].id] : []
}

# ----------------------------------------------------------------------
# Alert: Cloud SQL CPU high
# ----------------------------------------------------------------------

resource "google_monitoring_alert_policy" "sql_cpu_high" {
  project      = var.project_id
  display_name = "${var.name_prefix} — Cloud SQL CPU high"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL CPU > ${var.sql_cpu_threshold}%"

    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.project_id}:${var.cloud_sql_instance_name}\" AND metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.sql_cpu_threshold / 100
      duration        = "600s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = local.channel_ids
  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Cloud SQL CPU has exceeded ${var.sql_cpu_threshold}% for 10 minutes on ${var.cloud_sql_instance_name}."
    mime_type = "text/markdown"
  }
}

# ----------------------------------------------------------------------
# Alert: Pub/Sub DLQ backlog
# ----------------------------------------------------------------------

resource "google_monitoring_alert_policy" "dlq_backlog" {
  project      = var.project_id
  display_name = "${var.name_prefix} — Pub/Sub DLQ has messages"
  combiner     = "OR"

  conditions {
    display_name = "DLQ subscription has undelivered messages"

    condition_threshold {
      filter          = "resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"${var.dlq_subscription_name}\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = local.channel_ids
  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "The Pub/Sub DLQ subscription `${var.dlq_subscription_name}` has undelivered messages. A consumer is failing."
    mime_type = "text/markdown"
  }
}

# ----------------------------------------------------------------------
# Alert: Load Balancer 5xx rate
# ----------------------------------------------------------------------
# Only created if an LB exists (lb_name is set).

resource "google_monitoring_alert_policy" "lb_5xx_high" {
  count = var.lb_name != "" ? 1 : 0

  project      = var.project_id
  display_name = "${var.name_prefix} — Load balancer 5xx rate high"
  combiner     = "OR"

  conditions {
    display_name = "5xx rate > ${var.lb_5xx_threshold}%"

    condition_threshold {
      filter          = "resource.type=\"https_lb_rule\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\" AND metric.labels.response_code_class=\"500\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.lb_5xx_threshold
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = local.channel_ids
  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "The load balancer 5xx rate has exceeded ${var.lb_5xx_threshold}% for 5 minutes."
    mime_type = "text/markdown"
  }
}

# ----------------------------------------------------------------------
# Dashboard
# ----------------------------------------------------------------------

resource "google_monitoring_dashboard" "main" {
  project = var.project_id

  dashboard_json = jsonencode({
    displayName = "${var.name_prefix} — OpenBI Platform"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          xPos = 0, yPos = 0, width = 12, height = 3
          widget = {
            title = "Cloud SQL — CPU utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.project_id}:${var.cloud_sql_instance_name}\" AND metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis             = { label = "CPU fraction", scale = "LINEAR" }
            }
          }
        },
        {
          xPos = 0, yPos = 3, width = 6, height = 3
          widget = {
            title = "Pub/Sub DLQ — undelivered messages"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"${var.dlq_subscription_name}\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MAX"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis             = { label = "messages", scale = "LINEAR" }
            }
          }
        },
        {
          xPos = 6, yPos = 3, width = 6, height = 3
          widget = {
            title = "GKE — running pods"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_cluster\" AND metric.type=\"kubernetes.io/container/restart_count\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis             = { label = "restarts/sec", scale = "LINEAR" }
            }
          }
        }
      ]
    }
  })
}
