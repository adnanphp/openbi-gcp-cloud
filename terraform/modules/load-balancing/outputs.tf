output "external_ip_address" {
  description = "Reserved global external IP (empty if not reserved)"
  value       = var.reserve_external_ip ? google_compute_global_address.external_lb[0].address : ""
}

output "external_ip_name" {
  description = "Name of the reserved external IP (empty if not reserved)"
  value       = var.reserve_external_ip ? google_compute_global_address.external_lb[0].name : ""
}

output "internal_ip_address" {
  description = "Reserved regional internal IP (empty if not reserved)"
  value       = var.reserve_internal_ip ? google_compute_address.internal_lb[0].address : ""
}

output "internal_ip_name" {
  description = "Name of the reserved internal IP (empty if not reserved)"
  value       = var.reserve_internal_ip ? google_compute_address.internal_lb[0].name : ""
}
