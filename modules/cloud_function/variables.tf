variable "project_id" {
  description = "The project ID"
  type        = string
}

variable "environment" {
  description = "Environment label for the deployment"
  type        = string
}

variable "region" {
  description = "Region for the instance template"
  type        = string
}

variable "event_trigger_bucket" {
  description = "The bucket to trigger the Cloud Function"
  type        = string
}

variable "source_code_bucket" {
    description = "The bucket to store the Cloud Function source code"
    type        = string
}

variable "service_account_email" {
  type      = string
  description = "The service account email to use for the Cloud Function"
  sensitive = true
}

variable "vpc_connector" {
  type    = string
  description = "The VPC connector to use for the Cloud Function"
}
