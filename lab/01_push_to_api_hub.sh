#!/bin/bash
set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi

PROJECT_ID=$(gcloud config get-value project)
LOCATION="us-central1"
IMPERSONATE="--impersonate-service-account="

echo "========================================="
echo "☁️  Manual Push to GCP API Hub"
echo "========================================="

create_api() {
  local API_ID=$1
  local DISPLAY_NAME=$2
  local DESCRIPTION=$3

  echo "Pushing API: $DISPLAY_NAME ($API_ID)..."
  gcloud apihub apis create \
    --api="$API_ID" \
    --display-name="$DISPLAY_NAME" \
    --description="$DESCRIPTION" \
    --location=$LOCATION \
    --project=$PROJECT_ID \
    $IMPERSONATE || echo "  -> API $API_ID already exists or error (ignoring)."
}

echo "--- 🟢 Greenfield APIs ---"
create_api "app001-profile" "User Profile API (Greenfield)" "Handles user profile data safely."
create_api "app002-data" "Data Processor API (Greenfield)" "Processes background data."
create_api "app003-bulk" "Bulk Ingestion API (Greenfield)" "Secured bulk ingestion with Spike Arrest."
create_api "app004-catalog" "Catalog API (Greenfield)" "Public catalog."
create_api "secureapp" "Secure Core API (Greenfield)" "Core API protected by OAuth and WAF."

echo ""
echo "--- 🟤 Brownfield (Legacy) APIs ---"
create_api "legacy-core" "Legacy Core API (Brownfield)" "Vulnerable core API. No API Key required."
create_api "legacy-auth" "Legacy Auth API (Brownfield)" "Vulnerable to SQL Injection."
create_api "legacy-payment" "Legacy Payment API (Brownfield)" "Vulnerable to volumetric payload abuse."
create_api "legacy-inventory" "Legacy Inventory API (Brownfield)" "Vulnerable unmanaged endpoint."
create_api "legacy-customer" "Legacy Customer API (Brownfield)" "Deprecated customer data access."

echo "========================================="
echo "✅ Push completed! APIs should now be visible in API Hub."
echo "Check the console: https://console.cloud.google.com/apihub/apis?project=$PROJECT_ID"
echo "========================================="
