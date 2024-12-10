resource "google_compute_firewall" "firewall_rule" {
  name    = var.firewall_rules[count.index].name
  count   = length(var.firewall_rules)
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = var.firewall_rules[count.index].ports
  }

  source_ranges = var.firewall_rules[count.index].source_ranges
  target_tags   = var.firewall_rules[count.index].target_tags
}
