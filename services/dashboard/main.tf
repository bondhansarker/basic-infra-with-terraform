locals {
  app    = "dashboard"
  prefix = "${var.project_id}-${var.environment}-${local.app}"
}

module "instance_template" {
  source = "../../modules/instance_template"

  prefix                = local.prefix
  service_account_email = var.service_account_email
  region                = var.region
  network_name          = var.network_name
  subnet_name           = var.subnet_name
  tags = ["http-server", "https-server", "ssh-server"]
  machine_type          = var.instance_template_machine_type
  source_image          = var.instance_template_source_image
  disk_size_gb          = var.instance_template_disk_size_gb
  disk_type             = var.instance_template_disk_type
  startup_script = file("${path.module}/startup.sh")

  labels = {
    app         = local.app
    environment = var.environment
  }
}

module "health_check" {
  source = "../../modules/health_check"

  prefix       = "${var.project_id}-${var.environment}-${local.app}"
  region       = var.region
  port         = 80
  request_path = "/backend/"
}

module "instance_group" {
  source = "../../modules/instance_group"

  prefix            = local.prefix
  region            = var.region
  zone              = var.zone
  secondary_zone    = var.secondary_zone
  instance_template = module.instance_template.id
  health_check_id   = module.health_check.id
  named_ports = [
    {
      name = "http"
      port = 80
    }
  ]
  autoscaler_min_replicas = var.autoscaler_autoscaling_policy_min_replicas
  autoscaler_max_replicas = var.autoscaler_autoscaling_policy_max_replicas
}

module "load_balancer" {
  source = "../../modules/load_balancer"

  prefix                          = local.prefix
  region                          = var.region
  network_name                    = var.network_name
  subnet_name                     = var.subnet_name
  backend_service_port_name       = "http"
  backend_service_protocol        = "HTTP"
  backend_instance_group          = module.instance_group.instance_group
  backend_service_health_check_id = module.health_check.id
  forwarding_rule_ip_address      = var.load_balancer_ip_address
  forwarding_rule_ip_protocol     = "TCP"
  forwarding_rule_port_range      = "80"
  forwarding_rule_network_tier    = var.load_balancer_network_tier
}