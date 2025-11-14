# ==============================================================================
# Terraform Infrastructure for ASPR Autonomous Agent Deployment
# Service: Google Cloud Run + Artifact Registry + IAM Service Account
# Project: apigee-boticario
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type    = string
  default = "apigee-boticario"
}

variable "region" {
  type    = string
  default = "us-east1"
}

# 1. Enable Required GCP APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "apigee.googleapis.com",
    "apihub.googleapis.com",
    "compute.googleapis.com",
    "securitycenter.googleapis.com",
    "modelarmor.googleapis.com",
    "dlp.googleapis.com"
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# 2. Dedicated Service Account for ASPR Agent
resource "google_service_account" "aspr_agent_sa" {
  account_id   = "aspr-agent-sa"
  display_name = "ASPR Security Agent Service Account"
  description  = "Identity for ASPR Autonomous API Security Agent"
  project      = var.project_id
}

# 3. Grant Required IAM Roles to ASPR Service Account
resource "google_project_iam_member" "aspr_roles" {
  for_each = toset([
    "roles/apigee.admin",
    "roles/compute.securityAdmin",
    "roles/compute.networkAdmin",
    "roles/apihub.admin",
    "roles/securitycenter.findingsEditor",
    "roles/securitycenter.findingsViewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.aspr_agent_sa.email}"
}

# 4. Artifact Registry Repository for ASPR Container Images
resource "google_artifact_registry_repository" "aspr_repo" {
  provider      = google
  location      = var.region
  repository_id = "aspr-agent-repo"
  description   = "Artifact Registry Repository for ASPR AI Security Agent"
  format        = "DOCKER"
  project       = var.project_id
  depends_on    = [google_project_service.required_apis]
}

# 5. Cloud Run Service for ASPR Agent
resource "google_cloud_run_v2_service" "aspr_service" {
  name     = "aspr-security-agent"
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.aspr_agent_sa.email

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.aspr_repo.repository_id}/aspr-agent:latest"

      resources {
        limits = {
          cpu    = "2000m"
          memory = "2Gi"
        }
      }

      env {
        name  = "APIGEE_PROJECT_ID"
        value = var.project_id
      }
      env {
        name  = "DEFAULT_WAF_POLICY_NAME"
        value = "apigee-waap-policy"
      }
    }
  }

  depends_on = [
    google_project_service.required_apis,
    google_artifact_registry_repository.aspr_repo
  ]
}

output "aspr_cloud_run_url" {
  value       = google_cloud_run_v2_service.aspr_service.uri
  description = "Public / Internal URL of the deployed ASPR Agent Service"
}

output "aspr_service_account" {
  value       = google_service_account.aspr_agent_sa.email
  description = "IAM Service Account email dedicated to ASPR agent"
}
