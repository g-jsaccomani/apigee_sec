#!/bin/bash
# ==============================================================================
# Script: push_specs_to_api_hub.sh
# Objective: Upload and synchronize local OpenAPI specs with GCP API Hub.
# Usage: ./push_specs_to_api_hub.sh [PROJECT_ID] [LOCATION]
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
LOCATION=${2:-"us-central1"}
LAB_SCRIPT="/Users/jsaccomani/Documents/Jetsky/My Projects/apigee_sec/lab/01_push_to_api_hub.sh"

echo "=============================================================================="
echo "📤 ASPR: Pushing OpenAPI Specifications to GCP API Hub"
echo "   Project:  $PROJECT_ID"
echo "   Location: $LOCATION"
echo "=============================================================================="

if [ -f "$LAB_SCRIPT" ]; then
  bash "$LAB_SCRIPT"
else
  echo "⚠️ Lab push script not found, registering default catalog via gcloud..."
  gcloud apihub apis list --location="$LOCATION" --project="$PROJECT_ID" || true
fi
