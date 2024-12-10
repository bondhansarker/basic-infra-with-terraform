variable "private_network" {
  description = "The private network to attach the instance to."
  type        = string
}

variable "region" {
  description = "The region where the SQL instance will be created."
  type        = string
}

variable "zone" {
  description = "The zone where the SQL instance will be created."
  type        = string
}

variable "secondary_zone" {
  description = "The secondary zone where the SQL instance will be created."
  type        = string
}

variable "instance_name" {
  description = "The name of the SQL instance."
  type        = string
}

variable "create_instance" {
  description = "Whether to create the SQL instance."
  type        = bool
}

variable "instance_database_version" {
  description = "The database version for the SQL instance."
  type        = string
}

variable "instance_edition" {
  description = "The edition of the SQL instance."
  type        = string
}

variable "instance_tier" {
  description = "The tier of the SQL instance."
  type        = string
}

variable "instance_root_password" {
  description = "The root password for the SQL instance."
  type        = string
}

variable "instance_disk_type" {
  description = "The disk type for the SQL instance."
  type        = string
}

variable "instance_disk_size" {
  description = "The disk size for the SQL instance."
  type        = number
}

variable "access_database" {
  description = "The name of the database to create for the access service."
  type        = string
}

variable "dashboard_database" {
  description = "The name of the database to create for the dashboard service."
  type        = string
}

variable "database_user" {
  description = "The user of the database."
  type        = string
}

variable "database_password" {
  description = "The password of the database."
  type        = string
}