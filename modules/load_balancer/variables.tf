variable "region" {
  description = "The region for the resources"
  type        = string
}

variable "prefix" {
  description = "The prefix for the resource names"
  type        = string
}

variable "backend_service_protocol" {
  description = "The protocol used by the backend service"
  type        = string
}

variable "backend_service_port_name" {
  description = "The port name for the backend service"
  type        = string
}

variable "backend_service_health_check_id" {
  description = "ID of the health check for the backend service"
  type        = string
}

variable "backend_instance_group" {
  description = "The link to the instance group"
  type        = string
}

variable "forwarding_rule_ip_protocol" {
  description = "The IP protocol for the forwarding rule"
  type        = string
}

variable "forwarding_rule_port_range" {
  description = "The port range for the forwarding rule"
  type        = string
}

variable "network_name" {
  description = "The name of the network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnetwork"
  type        = string
}

variable "forwarding_rule_ip_address" {
    description = "static IP address for the forwarding rule"
    type        = string
}

variable "forwarding_rule_network_tier" {
    description = "The network tier for the forwarding rule"
    type        = string
}
