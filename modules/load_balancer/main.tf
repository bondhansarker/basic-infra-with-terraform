# Define the regional access service
resource "google_compute_region_backend_service" "this" {
  provider              = google-beta
  name                  = "${var.prefix}-backend-service"
  port_name             = var.backend_service_port_name
  protocol              = var.backend_service_protocol
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"
  region                = var.region

  health_checks = [var.backend_service_health_check_id]

  backend {
    group           = var.backend_instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
}

resource "google_compute_region_url_map" "this" {
  name            = "${var.prefix}-url-map"
  region          = var.region
  default_service = google_compute_region_backend_service.this.self_link
}

resource "google_compute_region_target_http_proxy" "this" {
  name    = "${var.prefix}-target-http-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.this.self_link
}

# Define the forwarding rule for the internal load balancer
resource "google_compute_forwarding_rule" "this" {
  provider              = google-beta
  name                  = "${var.prefix}-forwarding-rule"
  region                = var.region
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = var.forwarding_rule_network_tier
  ip_protocol           = var.forwarding_rule_ip_protocol
  port_range            = var.forwarding_rule_port_range
  ip_address            = var.forwarding_rule_ip_address
  target                = google_compute_region_target_http_proxy.this.self_link
  network               = var.network_name
}
