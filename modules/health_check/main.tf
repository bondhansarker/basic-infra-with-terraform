resource "google_compute_region_health_check" "this" {
  name                = "${var.prefix}-health-check"
  region              = var.region
  healthy_threshold   = 3
  unhealthy_threshold = 3
  check_interval_sec  = 15
  timeout_sec         = 15

  http_health_check {
    request_path = var.request_path
    port         = var.port
  }
}
