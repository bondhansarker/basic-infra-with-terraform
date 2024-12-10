project_id            = "demo-project"
region                = "asia-southeast1"
zone                  = "asia-southeast1-a"
secondary_zone        = "asia-southeast1-b"
service_account_email = "demo@demo.iam.gserviceaccount.com"
environment = "dev"

# This is the name of the network that will be used for the services
network_name = "vpc"
create_network = false

# This is the subnet that will be used for the services
subnet_ip_cidr_range = "10.0.0.0/28"
subnet_name          = "dev-subnet-asia-southeast1"
create_subnet = false

# This is the subnet that will be used for the load balancer
proxy_subnet_ip_cidr_range = "10.1.0.0/26"
lb_proxy_subnet_name       = "lb-subnet"
create_lb_proxy_subnet = false

# This is used to connect cloud function to the VPC
network_vpc_access_connector_name = "vpc-connector"
create_vpc_access_connector = false

# This is used to connect the VPC to the gcp cloud services like cloud sql
network_global_address_name = "dev-vpc-ip-range"
create_global_address = false

# This is used to connect the VPC to the internet
network_router_name     = "dev-router"
create_router           = false
network_router_nat_name = "dev-nat"
create_router_nat = false

# These are the names of the IP addresses that will be used for the dashboard and access service load balancers
network_dashboard_ip_address_name = "dashboard"
network_access_ip_address_name    = "access"

network_tier = "STANDARD"

# Dashboard Instance Template Values
access_instance_template_machine_type                            = "e2-medium"
access_instance_template_source_image                            = "debian-cloud/debian-12"
access_instance_template_disk_size_gb                            = 20
access_instance_template_disk_type                               = "pd-ssd"
access_instance_group_autoscaler_autoscaling_policy_min_replicas = 1
access_instance_group_autoscaler_autoscaling_policy_max_replicas = 2

# Access Instance Template Values
dashboard_instance_template_machine_type                            = "e2-medium"
dashboard_instance_template_source_image                            = "debian-cloud/debian-12"
dashboard_instance_template_disk_size_gb                            = 20
dashboard_instance_template_disk_type                               = "pd-ssd"
dashboard_instance_group_autoscaler_autoscaling_policy_min_replicas = 1
dashboard_instance_group_autoscaler_autoscaling_policy_max_replicas = 2

# SQL Database Instance Values
sql_instance_name   = "database"
create_sql_instance = true

sql_instance_database_version = "POSTGRES_15"
sql_instance_edition          = "ENTERPRISE"

# data cache available only for Enterprise Plus
# have to enable it in the code to use the data cache
sql_data_cache_enabled     = false
sql_instance_tier          = "db-custom-2-7680"
sql_instance_root_password = "hello_database"
sql_instance_disk_type     = "PD_SSD"
sql_instance_disk_size = 30

# This is the bucket that will be used to store the source code for the cloud function
cloud_storage_source_code_bucket_name = "bucket-name"
create_cloud_func_storage_bucket = false

# This is the bucket that will be used to trigger the cloud function
cloud_storage_trigger_bucket_name = "bucket-name"

# This is image registry and tag that will be used to deploy the services
image_registry = "demo-repo"
dashboard_backend_image_tag = "dev"
access_backend_image_tag = "dev"
dashboard_frontend_image_tag = "dev"
access_frontend_image_tag = "dev"

# These are the environment variables that will be used in the services
db_user                      = "postgres"
db_port                      = "5432"
db_password                  = "hello@12345"
dashboard_db_name            = "dashboard"
access_db_name               = "access"
redis_password               = "redis_password"
redis_host                   = "redis"
redis_port                   = "6379"
access_megasalt              = "salt123456"
smtp_host                    = "smtp.sendgrid.net"
smtp_port                    = "587"
smtp_user_name               = "demoapikey"
smtp_password                = "password"
smtp_sender                  = "email"
dashboard_geohash_resolution = "8"
map_api_key                  = "map_key"
app_bucket_name              = "bucket_name"