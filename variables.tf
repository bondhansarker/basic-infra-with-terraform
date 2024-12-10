variable "project_id" {
  description = "The project ID for Google Cloud"
  type        = string
}

variable "region" {
  description = "The region for Google Cloud resources"
  type        = string
}

variable "zone" {
  description = "Zone for the Compute Engine instance"
  type        = string
}

variable "secondary_zone" {
  description = "Secondary zone for the Compute Engine instance"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the Compute Engine instance"
  type        = string
}

variable "environment" {
  description = "Environment label for the deployment"
  type        = string
}

#Network Module
variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "lb_proxy_subnet_name" {
  description = "Name of the proxy subnet for the load balancer"
  type        = string
}

variable "proxy_subnet_ip_cidr_range" {
  description = "IP CIDR range for the VPC subnet proxy"
  type        = string
}

variable "subnet_ip_cidr_range" {
  description = "IP CIDR range for the VPC subnet proxy"
  type        = string
}

variable "network_vpc_access_connector_name" {
  description = "Name of the VPC access connector"
  type        = string
}

variable "network_global_address_name" {
  description = "Name of the global address"
  type        = string
}

variable "network_router_name" {
  description = "Name of the router"
  type        = string
}

variable "network_router_nat_name" {
  description = "Name of the router NAT"
  type        = string
}

variable "network_dashboard_ip_address_name" {
  description = "Name of the dashboard IP address"
  type        = string
}

variable "network_access_ip_address_name" {
  description = "Name of the access IP address"
  type        = string
}

variable "network_tier" {
  description = "The network tier"
  type        = string
}

variable "create_network" {
  description = "Create the network"
  type        = bool
  default     = false
}

variable "create_subnet" {
  description = "Create the subnet"
  type        = bool
  default     = false
}

variable "create_lb_proxy_subnet" {
  description = "Create the load balancer proxy subnet"
  type        = bool
  default     = false
}

variable "create_vpc_access_connector" {
  description = "Create the VPC access connector"
  type        = bool
  default     = false
}

variable "create_global_address" {
  description = "Create the global address"
  type        = bool
  default     = false
}

variable "create_router" {
  description = "Create the router"
  type        = bool
  default     = false
}

variable "create_router_nat" {
  description = "Create the NAT configuration"
  type        = bool
  default     = false
}

variable "create_access_ip_address" {
  description = "Create the access IP address"
  type        = bool
  default     = false
}

variable "create_dashboard_ip_address" {
  description = "Create the dashboard IP address"
  type        = bool
  default     = false
}

// access Module
variable "access_instance_template_machine_type" {
  description = "The machine type for the access instance template."
  type        = string
}

variable "access_instance_template_source_image" {
  description = "The source image to use for the access instance template."
  type        = string
}

variable "access_instance_template_disk_size_gb" {
  description = "The disk size in GB for the access instance template."
  type        = number
}

variable "access_instance_template_disk_type" {
  description = "The type of disk to attach to the access instance template."
  type        = string
}

variable "access_instance_group_autoscaler_autoscaling_policy_min_replicas" {
  description = "The minimum number of replicas for the access autoscaler."
  type        = number
}

variable "access_instance_group_autoscaler_autoscaling_policy_max_replicas" {
  description = "The maximum number of replicas for the access autoscaler."
  type        = number
}

// dashboard Module
variable "dashboard_instance_template_machine_type" {
  description = "The machine type for the dashboard instance template."
  type        = string
}

variable "dashboard_instance_template_source_image" {
  description = "The source image to use for the dashboard instance template."
  type        = string
}

variable "dashboard_instance_template_disk_size_gb" {
  description = "The disk size in GB for the dashboard instance template."
  type        = number
}

variable "dashboard_instance_template_disk_type" {
  description = "The type of disk to attach to the dashboard instance template."
  type        = string
}

variable "dashboard_instance_group_autoscaler_autoscaling_policy_min_replicas" {
  description = "The minimum number of replicas for the dashboard autoscaler."
  type        = number
}

variable "dashboard_instance_group_autoscaler_autoscaling_policy_max_replicas" {
  description = "The maximum number of replicas for the dashboard autoscaler."
  type        = number
}

# SQL Module
variable "sql_instance_name" {
  description = "Name of the SQL instance."
  type        = string
}

variable "create_sql_instance" {
  description = "Create the SQL instance."
  type        = bool
  default     = false
}

variable "sql_instance_database_version" {
  description = "Database version for the SQL instance."
  type        = string
}

variable "sql_instance_root_password" {
  description = "Root password for the SQL instance."
  type        = string
}

variable "sql_instance_edition" {
  description = "Edition of the SQL instance."
  type        = string
}

variable "sql_instance_tier" {
  description = "Machine type or tier for the SQL instance."
  type        = string
}

variable "sql_instance_disk_type" {
  description = "Type of disk for the SQL instance."
  type        = string
}

variable "sql_instance_disk_size" {
  description = "Size of the disk in GB for the SQL instance."
  type        = number
}

variable "sql_data_cache_enabled" {
  description = "Enable the data cache"
  type        = bool
}

// Bucket Module
variable "cloud_storage_source_code_bucket_name" {
  description = "Name of the Cloud Storage bucket."
  type        = string
}

variable "cloud_storage_trigger_bucket_name" {
  description = "Location of the Cloud Storage bucket."
  type        = string
}

variable "create_cloud_func_storage_bucket" {
  description = "Create the Cloud Storage bucket"
  type        = bool
  default     = false
}

// Service Module
variable "db_user" {
  description = "The database user"
  type        = string
}

variable "db_password" {
  description = "The database password"
  type        = string
}

variable "db_port" {
  description = "The port on which the database listens"
  type        = string
}

variable "dashboard_db_name" {
  description = "The name of the dashboard database"
  type        = string
}

variable "access_db_name" {
  description = "The name of the access database"
  type        = string
}

variable "redis_password" {
  description = "The password for Redis"
  type        = string
}

variable "redis_host" {
  description = "The host for Redis"
  type        = string
}

variable "redis_port" {
  description = "The port for Redis"
  type        = string
}

variable "access_megasalt" {
  description = "The mega salt value for access"
  type        = string
}

variable "smtp_host" {
  description = "The SMTP host"
  type        = string
}

variable "smtp_port" {
  description = "The SMTP port"
  type        = string
}

variable "smtp_user_name" {
  description = "The SMTP username"
  type        = string
}

variable "smtp_password" {
  description = "The SMTP password"
  type        = string
}

variable "smtp_sender" {
  description = "The email address of the SMTP sender"
  type        = string
}

variable "map_api_key" {
  description = "The Api key for the map"
  type        = string
}

variable "dashboard_geohash_resolution" {
  description = "The geohash resolution for the dashboard"
  type        = string
}

variable "app_bucket_name" {
  description = "The bucket name for the app"
  type        = string
}

variable "image_registry" {
  description = "The image registry for the container"
  type        = string
}

variable "dashboard_backend_image_tag" {
    description = "The tag for the dashboard backend container image"
    type        = string
}

variable "access_backend_image_tag" {
    description = "The tag for the access backend container image"
    type        = string
}

variable "dashboard_frontend_image_tag" {
    description = "The tag for the dashboard frontend container image"
    type        = string
}

variable "access_frontend_image_tag" {
    description = "The tag for the access frontend container image"
    type        = string
}
