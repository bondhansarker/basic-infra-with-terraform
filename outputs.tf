output "terraform-workspace" {
  value = terraform.workspace
}

output "logged-in-email" {
  value = data.google_client_openid_userinfo.me.email
}

output "database_instance_connection_name" {
  description = "The connection name of the database instance"
  value       = module.sql_instance.connection_name
}

output "database_instance_private_ip_address" {
  description = "The IP address of the database instance"
  value       = module.sql_instance.private_ip_address
}

output "network_id" {
  description = "ID of the VPC network"
  value       = module.network.network_id
}

output "access_ip_address" {
  description = "The IP address of the access service"
  value       = module.network.access_ip_address
}

output "dashboard_ip_address" {
  description = "The IP address of the dashboard service"
  value       = module.network.dashboard_ip_address
}