output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = google_compute_forwarding_rule.this.ip_address
}