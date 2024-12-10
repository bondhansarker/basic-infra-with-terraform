output "network_id" {
    description = "ID of the VPC network"
    value       = data.google_compute_network.this.id
}

output "network_name" {
    description = "Name of the network"
    value       = data.google_compute_network.this.name
}

output "subnet_name" {
    description = "Name of the subnet"
    value       = data.google_compute_subnetwork.this.name
}

output "network_link" {
    description = "ID of the VPC network"
    value       = data.google_compute_network.this.self_link
}

output "vpc_access_connector_link" {
    description = "The VPC connector to use for the Cloud Function"
    value       = data.google_vpc_access_connector.this.self_link
}

output "dashboard_ip_address" {
    description = "The IP address of the dashboard"
    value       = data.google_compute_address.dashboard.address
}

output "access_ip_address" {
    description = "The IP address of the access"
    value       = data.google_compute_address.access.address
}

output "global_address_range" {
    description = "The IP address of the VPC access connector"
    value       = data.google_compute_global_address.this.address
}
