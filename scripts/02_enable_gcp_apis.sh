#!/bin/bash
# ==============================================================================
# Script: 02_enable_gcp_apis.sh
# Purpose: Enables all required Google Cloud APIs for Apigee, WAAP, and API Hub.
# Documentation Reference: https://docs.cloud.google.com/apigee/docs/api-platform/get-started/enable-apis
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}

echo "=============================================================================="
echo "🚀 ASPR: Enabling Google Cloud APIs for Project: $PROJECT_ID"
echo "=============================================================================="

APIS=(
  "apigee.googleapis.com"
  "compute.googleapis.com"
  "servicenetworking.googleapis.com"
  "apihub.googleapis.com"
  "recaptchaenterprise.googleapis.com"
  "dlp.googleapis.com"
  "modelarmor.googleapis.com"
  "cloudresourcemanager.googleapis.com"
  "monitoring.googleapis.com"
  "logging.googleapis.com"
)

for api in "${APIS[@]}"; do
  echo "Enabling $api..."
  gcloud services enable "$api" --project="$PROJECT_ID"
done

echo "=============================================================================="
echo "✅ All required Google Cloud APIs are enabled for: $PROJECT_ID"
echo "=============================================================================="
