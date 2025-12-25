#!/bin/bash
function _finish_report {
    local exit_code=$?
    echo -e "\n========================================="
    echo "📊 SCRIPT EXECUTION REPORT"
    echo "========================================="
    if [ $exit_code -eq 0 ]; then
        echo "✅ All steps completed SUCCESSFULLY."
    else
        echo "❌ Script FAILED."
        echo "Please review the output above for errors."
    fi
    echo "========================================="
}
trap _finish_report EXIT

# =========================================================================
# Phase 2: Provisioning API Hub
# This script provisions API Hub as a centralized catalog.
# =========================================================================

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi

PROJECT_ID=$(gcloud config get-value project)
# API Hub is usually placed in us-central1 for global availability in most orgs
LOCATION="us-central1"

echo "========================================="
echo "🌐 Starting API Hub Provisioning..."
echo "========================================="

echo "=== 1. Enabling API Hub Service ==="
gcloud services enable apihub.googleapis.com --project=$PROJECT_ID

echo "=== 2. Registering Host Project ==="
# Note: Host project registration currently fails when using impersonation, 
# so we temporarily unset the impersonation for this specific call.
gcloud apihub host-project-registrations create $PROJECT_ID \
  --gcp-project=projects/$PROJECT_ID \
  --project=$PROJECT_ID \
  --location=$LOCATION \
  --impersonate-service-account="" || echo "Host Project already registered or in progress."

echo "=== 3. Creating API Hub Instance ==="
gcloud apihub api-hub-instances create $PROJECT_ID \
  --location=$LOCATION \
  --config-disable-search \
  --project=$PROJECT_ID \
  --impersonate-service-account="" || echo "API Hub Instance already exists or is being created."

echo "Waiting for API Hub Instance to become ACTIVE (this may take several minutes)..."
while true; do
  # Temporarily disable impersonation for describe if it causes issues, though it should be fine.
  STATE=$(gcloud apihub api-hub-instances describe $PROJECT_ID --location=$LOCATION --project=$PROJECT_ID --format="value(state)" --impersonate-service-account="" 2>/dev/null || echo "CREATING")
  if [ "$STATE" == "ACTIVE" ]; then
    echo -e "\n✅ API Hub Instance is ACTIVE!"
    break
  fi
  echo -n "."
  sleep 15
done

echo "=== 4. Tuning: Attaching Runtime Project ==="
# Attach the current project as a runtime project so Apigee/API Hub can discover the APIs
gcloud apihub runtime-project-attachments create $PROJECT_ID \
  --runtime-project=projects/$PROJECT_ID \
  --project=$PROJECT_ID \
  --location=$LOCATION \
  --impersonate-service-account="" || echo "Runtime Project already attached."

echo "========================================================================="
echo "API Hub Provisioned and Tuned Successfully!"
echo "You can now view your cataloged APIs in the API Hub dashboard."
echo "========================================================================="
