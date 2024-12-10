variable "network_name" {
  description = "Name of the network for the firewall rules"
  type        = string
}

variable "firewall_rules" {
  description = "List of firewall rules to create"
  type = list(object({
    name           = string
    ports          = list(string)
    target_tags    = list(string)
    source_ranges  = list(string)
  }))
}
