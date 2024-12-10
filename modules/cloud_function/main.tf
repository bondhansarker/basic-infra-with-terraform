data "google_storage_bucket" "source_code_bucket" {
  name = var.source_code_bucket
}

data "google_storage_bucket" "event_trigger_bucket" {
  name = var.event_trigger_bucket
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/tmp/function.zip"
}

# Add source code zip to the Cloud Function's bucket (cloud_function_bucket) 
resource "google_storage_bucket_object" "zip" {
  source       = data.archive_file.source.output_path
  content_type = "application/zip"
  name         = "src-${data.archive_file.source.output_md5}.zip"
  bucket       = var.source_code_bucket
  depends_on = [
    data.archive_file.source
  ]
}

resource "google_cloudfunctions2_function" "function" {
  name     = "${var.project_id}-${var.environment}-etl"
  location = var.region
  project  = var.project_id

  description = "Cloud function gen2 trigger using terraform "

  build_config {
    runtime     = "python39"
    entry_point = "etl"
    environment_variables = {
      BUILD_CONFIG_TEST = "build_test"
    }
    source {
      storage_source {
        bucket = data.google_storage_bucket.source_code_bucket.name
        object = google_storage_bucket_object.zip.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    min_instance_count = 0
    available_memory   = "8G"
    available_cpu      = 4
    timeout_seconds    = 1800
    environment_variables = {
      PROJECT_ID  = var.project_id
      ENVIRONMENT = var.environment
    }
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = var.service_account_email
    vpc_connector                  = var.vpc_connector
    vpc_connector_egress_settings  = "ALL_TRAFFIC"
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.storage.object.v1.finalized"
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = var.service_account_email
    event_filters {
      attribute = "bucket"
      value     = data.google_storage_bucket.event_trigger_bucket.name
    }
  }
  depends_on = [
    google_storage_bucket_object.zip
  ]
}
