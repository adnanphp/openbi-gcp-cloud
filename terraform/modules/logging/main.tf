# Cloud Logging module for OpenBI.
#
# Creates a log bucket, a sink that routes OpenBI logs into it, and
# log-based metrics for error count and latency.

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
# Log bucket with custom retention
# ----------------------------------------------------------------------

resource "google_logging_project_bucket_config" "openbi" {
  project        = var.project_id
  location       = var.location
  bucket_id      = "${var.name_prefix}-logs"
  retention_days = var.retention_days

  description = "OpenBI application logs (${var.name_prefix})"
}

# ----------------------------------------------------------------------
# Log sink: route OpenBI logs to the bucket
# ----------------------------------------------------------------------

resource "google_logging_project_sink" "openbi" {
  name        = "${var.name_prefix}-openbi-logs"
  project     = var.project_id
  destination = "logging.googleapis.com/projects/${var.project_id}/locations/${var.location}/buckets/${google_logging_project_bucket_config.openbi.bucket_id}"

  filter = var.log_filter

  # Ensures the sink's writer identity can write to the destination.
  unique_writer_identity = true
}

# ----------------------------------------------------------------------
# Log-based metrics
# ----------------------------------------------------------------------

# Error count — count of ERROR-severity logs from the openbi namespace.
resource "google_logging_metric" "error_count" {
  name        = "${var.name_prefix}/error_count"
  project     = var.project_id
  description = "Count of ERROR-level logs from OpenBI"
  filter      = "resource.type=\"k8s_container\" AND resource.labels.namespace_name=\"openbi\" AND severity=ERROR"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "OpenBI error count"
  }
}

# FastAPI latency P99 — extracted from JSON logs' duration_ms field.
resource "google_logging_metric" "fastapi_latency" {
  name        = "${var.name_prefix}/fastapi_latency_ms"
  project     = var.project_id
  description = "FastAPI request latency in milliseconds (extracted from JSON logs)"

  filter = "resource.type=\"k8s_container\" AND resource.labels.namespace_name=\"openbi\" AND jsonPayload.path:\"/\""

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "DISTRIBUTION"
    unit         = "ms"
    display_name = "FastAPI request latency"
  }

  value_extractor = "EXTRACT(jsonPayload.duration_ms)"

  bucket_options {
    linear_buckets {
      num_finite_buckets = 20
      width              = 50
      offset             = 0
    }
  }
}
