variable "prefix" {
  description = "Prefix to add to the name of the resources"
  type        = string
}

variable "project_id" {
  description = "The project ID"
  type        = string
}

variable "region" {
  description = "The region of the database instance"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "lb_proxy_subnet_name" {
  description = "Name of the subnet for the load balancer"
  type        = string
}

variable "ip_cidr_range" {
  description = "IP CIDR range for the VPC network"
  type        = string
}

variable "ip_cidr_range_proxy" {
  description = "IP CIDR range for the VPC subnet proxy"
  type        = string
}

variable "network_tier" {
  description = "The network tier"
  type        = string
}

variable "vpc_access_connector_name" {
  description = "The name of the VPC access connector"
  type        = string
}

variable "global_address_name" {
  description = "The name of the global address"
  type        = string
}

variable "router_name" {
  description = "The name of the router"
  type        = string
}

variable "router_nat_name" {
  description = "The name of the NAT configuration"
  type        = string
}

variable "access_ip_address_name" {
  description = "The name of the access IP address"
  type        = string
}

variable "dashboard_ip_address_name" {
  description = "The name of the dashboard IP address"
  type        = string
}

variable "create_network" {
  description = "Create the network"
  type        = bool
}

variable "create_subnet" {
  description = "Create the subnet"
  type        = bool
}

variable "create_lb_proxy_subnet" {
  description = "Create the load balancer proxy subnet"
  type        = bool
}

variable "create_vpc_access_connector" {
  description = "Create the VPC access connector"
  type        = bool
}

variable "create_global_address" {
  description = "Create the global address"
  type        = bool
}

variable "create_router" {
  description = "Create the router"
  type        = bool
}

variable "create_router_nat" {
  description = "Create the NAT configuration"
  type        = bool
}

variable "create_access_ip_address" {
  description = "Create the access IP address"
  type        = bool
}

variable "create_dashboard_ip_address" {
  description = "Create the dashboard IP address"
  type        = bool
}

