output "log_bucket_id" {
  description = "ID of the OpenBI log bucket"
  value       = google_logging_project_bucket_config.openbi.bucket_id
}

output "sink_name" {
  description = "Name of the log sink"
  value       = google_logging_project_sink.openbi.name
}

output "sink_writer_identity" {
  description = "Writer identity of the sink (needs permission on the destination)"
  value       = google_logging_project_sink.openbi.writer_identity
}

output "error_count_metric" {
  description = "Full name of the log-based error count metric"
  value       = google_logging_metric.error_count.name
}

output "fastapi_latency_metric" {
  description = "Full name of the log-based latency metric"
  value       = google_logging_metric.fastapi_latency.name
}
