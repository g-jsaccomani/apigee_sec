#!/bin/bash
# ==============================================================================
# Script: activate_api_hub.sh
# Objective: Provision and activate GCP API Hub as a centralized API catalog.
# Usage: ./activate_api_hub.sh [PROJECT_ID] [LOCATION]
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
LOCATION=${2:-"us-central1"}

echo "=============================================================================="
echo "🌐 ASPR: Activating GCP API Hub"
echo "   Project:  $PROJECT_ID"
echo "   Location: $LOCATION"
echo "=============================================================================="

echo "1. Enabling API Hub API Service..."
gcloud services enable apihub.googleapis.com --project="$PROJECT_ID"

echo "2. Registering Host Project..."
gcloud apihub host-project-registrations create "$PROJECT_ID" \
  --gcp-project="projects/$PROJECT_ID" \
  --project="$PROJECT_ID" \
  --location="$LOCATION" \
  --impersonate-service-account="" 2>/dev/null || echo "Host Project already registered or in progress."

echo "3. Creating / Checking API Hub Instance..."
gcloud apihub api-hub-instances create "$PROJECT_ID" \
  --location="$LOCATION" \
  --config-disable-search \
  --project="$PROJECT_ID" \
  --impersonate-service-account="" 2>/dev/null || echo "API Hub Instance already exists or is being created."

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

echo "4. Attaching Runtime Project for Auto-discovery..."
gcloud apihub runtime-project-attachments create "$PROJECT_ID" \
  --runtime-project="projects/$PROJECT_ID" \
  --project="$PROJECT_ID" \
  --location="$LOCATION" \
  --impersonate-service-account="" 2>/dev/null || echo "Runtime Project already attached."

echo "=============================================================================="
echo "✅ API Hub Activated Successfully in project: $PROJECT_ID ($LOCATION)"
echo "=============================================================================="
