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
# Phase 0: Authenticate and Connect to Google Cloud Environment
# =========================================================================

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi

echo "========================================="
echo "GCP Authentication Setup (Impersonation)"
echo "========================================="

# 1. Ask for the project ID
read -p "Please enter your Google Cloud Project ID (e.g., apigee-poc-123): " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
  echo "Error: Project ID cannot be empty."
  exit 1
fi

echo ""
echo "=== Service Account Impersonation ==="
echo "To follow best security practices, we will not use JSON keys."
echo "Instead, we will impersonate a Service Account that has the required permissions"
echo "(e.g., Apigee Admin, Compute Admin, etc.). Your personal account must have the"
echo "'Service Account Token Creator' role on this Service Account to impersonate it."
echo ""
echo "Example: my-apigee-sa@my-project.iam.gserviceaccount.com"

# 2. Ask for the Service Account Email
read -p "Please enter the Service Account Email to impersonate: " SA_EMAIL

if [ -z "$SA_EMAIL" ]; then
  echo "Error: Service Account Email cannot be empty."
  exit 1
fi

echo ""
echo "1. Authenticating your personal account..."
# This opens a browser to authenticate your base user
# (If you are in Cloud Shell, you may already be authenticated, but this guarantees it)
gcloud auth login --update-adc

echo "2. Setting up project: $PROJECT_ID"
gcloud config set project $PROJECT_ID

echo "3. Configuring Service Account Impersonation..."
gcloud config set auth/impersonate_service_account $SA_EMAIL

echo "4. Verifying impersonation..."
# Running a simple command to verify the impersonation is working
if gcloud auth print-access-token &>/dev/null; then
    echo "Successfully connected and impersonating $SA_EMAIL!"
else
    echo "Error: Failed to impersonate the Service Account."
    echo "Make sure your personal account has the 'Service Account Token Creator' role."
    # Reverting impersonation on failure
    gcloud config unset auth/impersonate_service_account
    exit 1
fi

echo "========================================================================="
echo "Environment connection is ready."
echo "You can now proceed with 01_Setup_Apigee_Env.sh"
echo "========================================================================="
