terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# No credentials here on purpose: the provider uses Application Default
# Credentials (gcloud auth application-default login).
provider "google" {
  project = var.project_id
  region  = var.region
}

# Raw data lake: EIA JSONL files land here, partitioned by extract date.
resource "google_storage_bucket" "raw" {
  name                        = "${var.project_id}-eia-raw"
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true # learning project: allows `terraform destroy` with files inside

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

# BigQuery dataset for raw loaded tables.
resource "google_bigquery_dataset" "raw" {
  dataset_id                 = "eia_raw"
  location                   = var.location
  delete_contents_on_destroy = true
  description                = "Raw EIA data loaded from GCS (US hourly + international)"
}

# BigQuery dataset where dbt will build staging and marts models.
resource "google_bigquery_dataset" "analytics" {
  dataset_id                 = "eia_analytics"
  location                   = var.location
  delete_contents_on_destroy = true
  description                = "dbt-built models for the dashboard"
}
