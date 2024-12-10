variable "zone" {
  description = "Zone for the Compute Engine instance"
  type        = string
}

variable "region" {
  description = "Region for the Compute Engine instance"
  type        = string
}

variable "secondary_zone" {
  description = "Secondary zone for the Compute Engine instance"
  type        = string
}

variable "prefix" {
  description = "Prefix for the instance group name"
  type        = string
}

variable "instance_template" {
  description = "The link/id to the instance template"
  type        = string
}

variable "health_check_id" {
  description = "ID of the health check for auto-healing policies"
  type        = string
}

variable "named_ports" {
  description = "List of named ports for the instance group"
  type = list(object({
    name = string
    port = number
  }))
}

variable "autoscaler_max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
}

variable "autoscaler_min_replicas" {
  description = "Minimum number of replicas for autoscaling"
  type        = number
}