resource "google_sql_database_instance" "this" {
  provider = google-beta
  count    = var.create_instance == true ? 1 : 0

  name             = var.instance_name
  database_version = var.instance_database_version
  region           = var.region
  root_password    = var.instance_root_password

  settings {
    edition           = var.instance_edition
    tier              = var.instance_tier
    activation_policy = "ALWAYS"
    availability_type = "REGIONAL"
    location_preference {
      zone           = var.zone
      secondary_zone = var.secondary_zone
    }
    disk_type             = var.instance_disk_type
    disk_size             = var.instance_disk_size
    disk_autoresize       = true
    disk_autoresize_limit = 0 # 0 means no limit

    backup_configuration {
      point_in_time_recovery_enabled = true
      enabled                        = true
      start_time                     = "03:00"
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network
    }
  }
}

data "google_sql_database_instance" "this" {
  name = var.instance_name

  depends_on = [google_sql_database_instance.this]
}

resource "google_sql_database" "dashboard_db" {
  name     = var.dashboard_database
  instance = data.google_sql_database_instance.this.name
}

resource "google_sql_database" "access_db" {
  name     = var.access_database
  instance = data.google_sql_database_instance.this.name
}

resource "google_sql_user" "user" {
  name     = var.database_user
  instance = data.google_sql_database_instance.this.name
  password = var.database_password
}