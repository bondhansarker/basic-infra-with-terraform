variable "project_id" {
  description = "The project ID where resources will be created."
  type        = string
}

variable "environment" {
  description = "The environment name, e.g., 'dev', 'staging', 'prod'."
  type        = string
}

variable "region" {
  description = "The region where resources will be deployed."
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet where resources will be created."
  type        = string
}

variable "service_account_email" {
  description = "The service account email to be attached to the instance."
  type        = string
}

variable "network_name" {
  description = "The name of the network where resources will be deployed."
  type        = string
}

variable "instance_template_machine_type" {
  description = "The machine type for the instance template."
  type        = string
}

variable "instance_template_source_image" {
  description = "The source image to use for the instance template."
  type        = string
}

variable "instance_template_disk_size_gb" {
  description = "The disk size in GB for the instance template."
  type        = number
}

variable "instance_template_disk_type" {
  description = "The type of disk to attach to the instance template."
  type        = string
}

variable "zone" {
  description = "The zone where the instance group will be created."
  type        = string
}

variable "secondary_zone" {
  description = "The secondary zone where the instance group will be created."
  type        = string
}

variable "autoscaler_autoscaling_policy_max_replicas" {
  description = "The maximum number of replicas for the autoscaler."
  type        = number
}

variable "autoscaler_autoscaling_policy_min_replicas" {
  description = "The minimum number of replicas for the autoscaler."
  type        = number
}

variable "load_balancer_ip_address" {
  description = "The IP address for the load balancer."
  type        = string
}

variable "load_balancer_network_tier" {
  description = "The network tier for the load balancer."
  type        = string
}