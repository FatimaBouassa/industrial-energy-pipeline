variable "project_id" {
  description = "Your GCP project ID (not the project name)"
  type        = string
}

variable "region" {
  description = "Default region for the provider"
  type        = string
  default     = "europe-west1"
}

variable "location" {
  description = "Location for the bucket and BigQuery datasets. They must match so BigQuery can load from GCS."
  type        = string
  default     = "EU"
}
