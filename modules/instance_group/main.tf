resource "google_compute_region_instance_group_manager" "this" {
  name                             = "${var.prefix}-instance-group"
  base_instance_name               = "${var.prefix}-instance"
  region                           = var.region
  distribution_policy_zones = [var.zone, var.secondary_zone]
  distribution_policy_target_shape = "EVEN"
  version {
    instance_template = var.instance_template
  }
  auto_healing_policies {
    health_check      = var.health_check_id
    initial_delay_sec = 240
  }
  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = named_port.value.name
      port = named_port.value.port
    }
  }
}

resource "google_compute_region_autoscaler" "this" {
  name   = "${var.prefix}-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.this.self_link
  autoscaling_policy {
    cooldown_period = 240
    min_replicas    = var.autoscaler_min_replicas
    max_replicas    = var.autoscaler_max_replicas
    mode            = "ON"
    cpu_utilization {
      target = 0.7
    }
  }
}
