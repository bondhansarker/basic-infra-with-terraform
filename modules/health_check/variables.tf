variable "region" {
  description = "The region for the health check"
  type        = string
}

variable "prefix" {
  description = "The prefix for the health check name"
  type        = string
}

variable "request_path" {
  description = "The request path for the HTTP health check"
  type        = string
}

variable "port" {
  description = "The port number for the HTTP health check"
  type        = string
}
