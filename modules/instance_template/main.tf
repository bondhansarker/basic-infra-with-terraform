resource "google_compute_region_instance_template" "this" {
  provider = google-beta
  name     = "${var.prefix}-instance-template"
  region   = var.region

  machine_type = var.machine_type
  tags         = var.tags

  labels = var.labels

  disk {
    source_image = var.source_image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    labels       = var.labels
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name
    nic_type   = "GVNIC"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  service_account {
    email = var.service_account_email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = var.startup_script
  lifecycle {
    create_before_destroy = true
  }
}
