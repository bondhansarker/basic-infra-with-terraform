# Instance Template Variables
variable "prefix" {
  description = "Prefix for the instance template"
  type        = string
}

variable "region" {
  description = "Region for the instance template"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the instance template"
  type        = string
}

variable "tags" {
  description = "Tags for the instance template"
  type = list(string)
}

variable "labels" {
  description = "Labels for the instance template"
  type = map(string)
}

variable "source_image" {
  description = "Source image for the instance template disk"
  type        = string
}

variable "disk_size_gb" {
  description = "Disk size in GB for the instance template"
  type        = number
}

variable "disk_type" {
  description = "Disk type for the instance template"
  type        = string
}

variable "network_name" {
  description = "Network name for the instance template"
  type        = string
}

variable "subnet_name" {
  description = "Subnetwork name for the instance template"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the instance template"
  type        = string
}

variable "startup_script" {
  description = "Startup script for the instance template"
  type        = string
}
