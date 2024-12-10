resource "google_compute_network" "this" {
  count                   = var.create_network == true ? 1 : 0
  name                    = var.network_name
  auto_create_subnetworks = false
}

data "google_compute_network" "this" {
  project = var.project_id
  name    = var.network_name

  depends_on = [google_compute_network.this]
}

resource "google_compute_subnetwork" "this" {
  count                    = var.create_subnet == true ? 1 : 0
  name                     = var.subnet_name
  region                   = var.region
  network                  = data.google_compute_network.this.name
  ip_cidr_range            = var.ip_cidr_range
  private_ip_google_access = true
}

data "google_compute_subnetwork" "this" {
  name    = var.subnet_name
  region  = var.region
  project = var.project_id

  depends_on = [google_compute_subnetwork.this]
}

// This is needed to allow the load balancer to communicate with the instances in the private subnet
resource "google_compute_subnetwork" "lb-proxy-subnet" {
  count = var.create_lb_proxy_subnet == true ? 1 : 0

  name          = var.lb_proxy_subnet_name
  region        = var.region
  network       = data.google_compute_network.this.name
  ip_cidr_range = var.ip_cidr_range_proxy
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"

}

# This is needed to allow the load balancer to communicate with the instances in the private subnet
data "google_compute_subnetwork" "lb-proxy" {
  name    = var.lb_proxy_subnet_name
  region  = var.region
  project = var.project_id

  depends_on = [google_compute_subnetwork.lb-proxy-subnet]
}

# This is needed to allow the cloud function in the private subnet to communicate with the database instance
resource "google_vpc_access_connector" "this" {
  count = var.create_vpc_access_connector == true ? 1 : 0

  name   = var.vpc_access_connector_name
  region = var.region
  subnet {
    name = data.google_compute_subnetwork.this.name
  }
  max_throughput = 500
  machine_type   = "e2-micro"
  min_instances  = 2
  max_instances  = 5
}

# This is needed to allow the cloud function in the private subnet to communicate with the database instance
data "google_vpc_access_connector" "this" {
  name    = var.vpc_access_connector_name
  region  = var.region
  project = var.project_id

  depends_on = [google_vpc_access_connector.this]
}

# This is needed to allow the database instance to communicate with the instances in the private subnet
resource "google_compute_global_address" "this" {
  count = var.create_global_address == true ? 1 : 0

  provider      = google-beta
  name          = var.global_address_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.this.name
}

// This is needed to allow the database instance to communicate with the instances in the private subnet
data "google_compute_global_address" "this" {
  provider = google-beta

  name     = var.global_address_name
  project  = var.project_id

  depends_on = [google_compute_global_address.this]
}


# resource "google_service_networking_connection" "this" {
#   provider = google-beta
#
#   service         = "servicenetworking.googleapis.com"
#   network         = data.google_compute_network.this.name
#   reserved_peering_ranges = [data.google_compute_global_address.this.name]
#   deletion_policy = "ABANDON"
# }

# needed for the NAT Gateway
# this is needed to allow the instances in the private subnet to access the internet
resource "google_compute_router" "this" {
  count = var.create_router == true ? 1 : 0

  name    = var.router_name
  network = data.google_compute_network.this.name
  region  = var.region
}

# needed for the NAT Gateway
# this is needed to allow the instances in the private subnet to access the internet
data "google_compute_router" "this" {
  name    = var.router_name
  network = var.network_name
  region  = var.region
  project = var.project_id

  depends_on = [google_compute_router.this]
}

resource "google_compute_router_nat" "this" {
  count = var.create_router_nat == true ? 1 : 0

  name                               = var.router_nat_name
  router                             = data.google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

data "google_compute_router_nat" "this" {
  name    = var.router_nat_name
  router  = var.router_name
  region  = var.region
  project = var.project_id

  depends_on = [google_compute_router_nat.this]
}

// this is needed to allow the instances in the private subnet to access the internet
// these are the private IPs of the instances in the private subnet
resource "google_compute_address" "dashboard" {
  count = var.create_dashboard_ip_address == true ? 1 : 0

  name         = var.dashboard_ip_address_name
  region       = var.region
  subnetwork   = data.google_compute_subnetwork.this.name
  network_tier = var.network_tier
  address_type = "INTERNAL"
}

// this is needed to allow the instances in the private subnet to access the internet
// these are the private IPs of the instances in the private subnet
data "google_compute_address" "dashboard" {
  name   = var.dashboard_ip_address_name
  region = var.region
  project = var.project_id

  depends_on = [google_compute_address.dashboard]
}

resource "google_compute_address" "access" {
  count = var.create_access_ip_address == true ? 1 : 0

  name         = var.access_ip_address_name
  region       = var.region
  subnetwork   = data.google_compute_subnetwork.this.name
  network_tier = var.network_tier
  address_type = "INTERNAL"
}

// these are the private IPs of the instances in the private subnet
data "google_compute_address" "access" {
  name   = var.access_ip_address_name
  region = var.region
  project = var.project_id

  depends_on = [google_compute_address.access]
}
