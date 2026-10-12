output "dashboard_id" {
  description = "ID of the Cloud Monitoring dashboard"
  value       = google_monitoring_dashboard.main.id
}

output "sql_cpu_alert_id" {
  description = "ID of the Cloud SQL CPU alert policy"
  value       = google_monitoring_alert_policy.sql_cpu_high.id
}

output "dlq_alert_id" {
  description = "ID of the Pub/Sub DLQ alert policy"
  value       = google_monitoring_alert_policy.dlq_backlog.id
}

output "notification_channel_id" {
  description = "ID of the email notification channel (empty if none)"
  value       = var.notification_email != "" ? google_monitoring_notification_channel.email[0].id : ""
}
