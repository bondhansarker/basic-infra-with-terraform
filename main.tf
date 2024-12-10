locals {
  prefix = "${var.project_id}-${terraform.workspace}"

  # Define secrets as a map of key-value pairs
  secrets = {
    MDI_DASHBOARD_DB_NAME                = var.dashboard_db_name
    MDI_ACCESS_DB_NAME                   = var.access_db_name
    MDI_DB_USER                          = var.db_user
    MDI_DB_PASSWORD                      = var.db_password
    MDI_DB_HOST                          = module.sql_instance.private_ip_address
    MDI_DB_PORT                          = var.db_port
    MDI_ACCESS_GIN_MODE                  = "release"
    MDI_REDIS_HOST                       = var.redis_host
    MDI_REDIS_PORT                       = var.redis_port
    MDI_REDIS_PASSWORD                   = var.redis_password
    MDI_ACCESS_MEGASALT                  = var.access_megasalt
    MDI_SMTP_HOST                        = var.smtp_host
    MDI_SMTP_PORT                        = var.smtp_port
    MDI_SMTP_USER_NAME                   = var.smtp_user_name
    MDI_SMTP_PASSWORD                    = var.smtp_password
    MDI_SMTP_SENDER                      = var.smtp_sender
    MDI_ACCESS_WEBHOOK_URLS              = "http://${module.network.dashboard_ip_address}/backend/webhook"
    MDI_ACCESS_NEXTAUTH_SECRET           = "vsfijfrakacsoacsoa"
    MDI_ACCESS_NEXTAUTH_SESSION_DURATION = "86400"
    MDI_BASE_ORGANIZATION_ID             = "684be20f-3014-401d-a099-8acce55ed23b_def"
    MDI_BASE_APPLICATION_ID              = "684be20f-3014-401d-a099-8acce55ed23b_def"
    MDI_BASE_CLIENT_ID                   = "107434d36e"
    MDI_BASE_CLIENT_SECRET               = "3b85efac73704b66fde3"
    MDI_DASHBOARD_DB_QUERY_LOGGER        = "true"
    MDI_DASHBOARD_GEOHASH_RESOLUTION     = var.dashboard_geohash_resolution
    MDI_GOOGLE_MAP_API_KEY               = var.map_api_key
    MDI_ACCESS_API_BASE_URL              = "http://${module.network.access_ip_address}/backend"
    MDI_ACCESS_FRONTEND_URL              = "http://${module.network.access_ip_address}"
    MDI_DASHBOARD_FRONTEND_URL           = "http://${module.network.dashboard_ip_address}"
    MDI_DASHBOARD_API_BASE_URL           = "http://${module.network.dashboard_ip_address}/backend"
    MDI_DASHBOARD_API_URL                = "http://${module.network.dashboard_ip_address}/backend/v1"
    MDI_DASHBOARD_FRONTEND_IMAGE         = "${var.region}-docker.pkg.dev/${var.project_id}/${var.image_registry}/frontend:${var.dashboard_backend_image_tag}"
    MDI_DASHBOARD_BACKEND_IMAGE          = "${var.region}-docker.pkg.dev/${var.project_id}/${var.image_registry}/backend:${var.dashboard_backend_image_tag}"
    MDI_ACCESS_FRONTEND_IMAGE            = "${var.region}-docker.pkg.dev/${var.project_id}/${var.image_registry}/access-frontend:${var.access_frontend_image_tag}"
    MDI_ACCESS_BACKEND_IMAGE             = "${var.region}-docker.pkg.dev/${var.project_id}/${var.image_registry}/access-backend:${var.access_frontend_image_tag}"
    MDI_DASHBOARD_RUN_DB_MIGRATION       = "true"
    MDI_ACCESS_RUN_DB_MIGRATION          = "true"
    MDI_APP_BUCKET_NAME                  = var.app_bucket_name
    MDI_GOOGLE_ACCESS_ID                 = var.service_account_email
  }
}

data "google_client_openid_userinfo" "me" {
}

# This module is the network that will be used to control the traffic
module "network" {
  source = "./modules/network"

  project_id           = var.project_id
  prefix               = "${var.project_id}-${var.environment}"
  region               = var.region
  network_name         = var.network_name
  subnet_name          = var.subnet_name
  lb_proxy_subnet_name = var.lb_proxy_subnet_name
  ip_cidr_range        = var.subnet_ip_cidr_range
  ip_cidr_range_proxy  = var.proxy_subnet_ip_cidr_range

  vpc_access_connector_name = var.network_vpc_access_connector_name
  global_address_name       = var.network_global_address_name
  router_name               = var.network_router_name
  router_nat_name           = var.network_router_nat_name
  access_ip_address_name    = var.network_access_ip_address_name
  dashboard_ip_address_name = var.network_dashboard_ip_address_name
  network_tier              = var.network_tier

  create_network              = var.create_network
  create_subnet               = var.create_subnet
  create_lb_proxy_subnet      = var.create_lb_proxy_subnet
  create_vpc_access_connector = var.create_vpc_access_connector
  create_global_address       = var.create_global_address
  create_router               = var.create_router
  create_router_nat           = var.create_router_nat
  create_access_ip_address    = var.create_access_ip_address
  create_dashboard_ip_address = var.create_dashboard_ip_address
}

# This module is the firewall that will be used to control the traffic rules
module "firewall" {
  source = "./modules/firewall"

  network_name = module.network.network_name
  firewall_rules = [
    {
      name = "${local.prefix}-allow-ssh"
      ports = ["22"]
      target_tags = ["ssh-server"]
      source_ranges = ["0.0.0.0/0"]
    },
    {
      name = "${local.prefix}-allow-http"
      ports = ["80"]
      target_tags = ["http-server"]
      source_ranges = ["0.0.0.0/0"]
    },
    {
      name = "${local.prefix}-allow-https"
      ports = ["443"]
      target_tags = ["https-server"]
      source_ranges = ["0.0.0.0/0"]
    }
  ]
}

# This module is the SQL instance that will be used to store the data
module "sql_instance" {
  source          = "./modules/sql_instance"
  create_instance = var.create_sql_instance

  region                    = var.region
  zone                      = var.zone
  secondary_zone            = var.secondary_zone
  private_network           = module.network.network_link
  instance_database_version = var.sql_instance_database_version
  instance_disk_size        = var.sql_instance_disk_size
  instance_disk_type        = var.sql_instance_disk_type
  instance_edition          = var.sql_instance_edition
  instance_name             = var.sql_instance_name
  instance_root_password    = var.sql_instance_root_password
  instance_tier             = var.sql_instance_tier
  dashboard_database        = var.dashboard_db_name
  access_database           = var.access_db_name
  database_password         = var.db_password
  database_user             = var.db_user
}

module "secret_manager" {
  source = "./modules/secret_manager"

  secrets = local.secrets

  depends_on = [module.sql_instance]
}

# This module is the access service that will be used to authenticate and authorize users
# This depends on secret manager because the access service will need the secrets to connect to the database
module "access" {
  source = "./services/access"

  project_id                                 = var.project_id
  environment                                = var.environment
  zone                                       = var.zone
  secondary_zone                             = var.secondary_zone
  region                                     = var.region
  subnet_name                                = var.subnet_name
  service_account_email                      = var.service_account_email
  network_name                               = var.network_name
  instance_template_machine_type             = var.access_instance_template_machine_type
  instance_template_source_image             = var.access_instance_template_source_image
  instance_template_disk_size_gb             = var.access_instance_template_disk_size_gb
  instance_template_disk_type                = var.access_instance_template_disk_type
  load_balancer_ip_address                   = module.network.access_ip_address
  load_balancer_network_tier                 = var.network_tier
  autoscaler_autoscaling_policy_min_replicas = var.access_instance_group_autoscaler_autoscaling_policy_min_replicas
  autoscaler_autoscaling_policy_max_replicas = var.access_instance_group_autoscaler_autoscaling_policy_max_replicas

  depends_on = [module.secret_manager]
}

# This module is the dashboard service that will be used to manage the data
# This depends on access service because the access service is the one that will do the user authentication and authorization
module "dashboard" {
  source = "./services/dashboard"

  project_id                                 = var.project_id
  environment                                = var.environment
  region                                     = var.region
  zone                                       = var.zone
  secondary_zone                             = var.secondary_zone
  subnet_name                                = var.subnet_name
  service_account_email                      = var.service_account_email
  network_name                               = var.network_name
  instance_template_machine_type             = var.dashboard_instance_template_machine_type
  instance_template_source_image             = var.dashboard_instance_template_source_image
  instance_template_disk_size_gb             = var.dashboard_instance_template_disk_size_gb
  instance_template_disk_type                = var.dashboard_instance_template_disk_type
  load_balancer_ip_address                   = module.network.dashboard_ip_address
  load_balancer_network_tier                 = var.network_tier
  autoscaler_autoscaling_policy_min_replicas = var.dashboard_instance_group_autoscaler_autoscaling_policy_min_replicas
  autoscaler_autoscaling_policy_max_replicas = var.dashboard_instance_group_autoscaler_autoscaling_policy_max_replicas

  depends_on = [module.secret_manager, module.access]
}

# This module is the cloud function that will be used to read the csv file from bucket and store the data in the database
# This depends on dashboard service because the dashboard service is the one that will do the database migration
module "cloud_function" {
  source = "./modules/cloud_function"

  project_id            = var.project_id
  environment           = var.environment
  service_account_email = var.service_account_email
  vpc_connector         = module.network.vpc_access_connector_link
  region                = var.region
  event_trigger_bucket  = var.cloud_storage_trigger_bucket_name
  source_code_bucket    = var.cloud_storage_source_code_bucket_name

  depends_on = [module.secret_manager, module.dashboard]
}