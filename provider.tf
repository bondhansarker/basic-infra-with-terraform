terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
  backend "gcs" {
    bucket  = "bucket_name"
    prefix  = "terraform/state"
  }
}

data "terraform_remote_state" "foo" {
  backend = "gcs"
  config = {
    bucket  = "bucket_name"
    prefix  = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
