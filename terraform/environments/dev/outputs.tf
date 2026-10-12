output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = module.vpc.network_name
}

output "subnet_self_link" {
  description = "Self link of the main subnet"
  value       = module.vpc.subnet_self_link
}

output "region" {
  description = "Region"
  value       = var.region
}
