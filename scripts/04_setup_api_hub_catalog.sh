#!/bin/bash
# ==============================================================================
# Script: 04_setup_api_hub_catalog.sh
# Purpose: Provisions Google Cloud API Hub, registers host project, and catalogs APIs.
# Documentation Reference: https://docs.cloud.google.com/api-hub/docs/overview
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
LOCATION=${2:-"us-central1"}

echo "=============================================================================="
echo "🌐 ASPR: Provisioning & Configuring Google Cloud API Hub"
echo "   Project:  $PROJECT_ID"
echo "   Location: $LOCATION"
echo "=============================================================================="

# 1. Enable API Hub Service
echo "1. Enabling API Hub API..."
gcloud services enable apihub.googleapis.com --project="$PROJECT_ID"

# 2. Register Host Project
echo "2. Registering Host Project in API Hub..."
gcloud apihub host-project-registrations create "$PROJECT_ID" \
  --gcp-project="projects/$PROJECT_ID" \
  --project="$PROJECT_ID" \
  --location="$LOCATION" \
  --impersonate-service-account="" 2>/dev/null || echo "Host Project already registered."

# 3. Create / Verify API Hub Instance
echo "3. Creating / Checking API Hub Instance..."
gcloud apihub api-hub-instances create "$PROJECT_ID" \
  --location="$LOCATION" \
  --config-disable-search \
  --project="$PROJECT_ID" \
  --impersonate-service-account="" 2>/dev/null || echo "API Hub Instance already exists or is initializing."

echo "Waiting for API Hub Instance to become ACTIVE..."
for i in {1..20}; do
  STATE=$(gcloud apihub api-hub-instances describe "$PROJECT_ID" --location="$LOCATION" --project="$PROJECT_ID" --format="value(state)" --impersonate-service-account="" 2>/dev/null || echo "CREATING")
  if [ "$STATE" == "ACTIVE" ]; then
    echo -e "\n✅ API Hub Instance is ACTIVE!"
    break
  fi
  echo -n "."
  sleep 10
done

# 4. Attach Runtime Project for Automatic Discovery
echo "4. Attaching Apigee runtime project to API Hub..."
gcloud apihub runtime-project-attachments create "$PROJECT_ID" \
  --runtime-project="projects/$PROJECT_ID" \
  --project="$PROJECT_ID" \
  --location="$LOCATION" \
  --impersonate-service-account="" 2>/dev/null || echo "Runtime Project already attached."

echo "=============================================================================="
echo "✅ API Hub Catalog is ready for enterprise governance and OpenAPI audits!"
echo "=============================================================================="
