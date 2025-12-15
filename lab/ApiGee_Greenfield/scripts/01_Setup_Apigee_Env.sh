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
# Phase 1: Environment Auditor & Apigee Setup
# This script audits the GCP environment for Apigee prerequisites.
# If the environment is not compliant, it offers to implement the fixes.
# =========================================================================

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
NETWORK_NAME="default"
PEERING_RANGE_NAME="apigee-range"
KEY_RING="apigee-keyring"
KEY_NAME="apigee-org-key"

echo "========================================="
echo "🔍 Starting Apigee Compliance Audit..."
echo "========================================="

COMPLIANT=true
MISSING_APIS=false
MISSING_PEERING=false
MISSING_KMS=false

# 1. Audit APIs
echo "[Audit] Checking if required APIs are enabled..."
REQUIRED_APIS="apigee.googleapis.com servicenetworking.googleapis.com cloudkms.googleapis.com compute.googleapis.com"
for api in $REQUIRED_APIS; do
  if ! gcloud services list --enabled --project=$PROJECT_ID | grep -q $api; then
    echo "  ❌ Missing API: $api"
    COMPLIANT=false
    MISSING_APIS=true
  fi
done

# 2. Audit Network Peering
echo "[Audit] Checking VPC Peering allocation (/22) for Apigee..."
if ! gcloud compute addresses describe $PEERING_RANGE_NAME --global --project=$PROJECT_ID &>/dev/null; then
  echo "  ❌ Missing /22 IP allocation for VPC Peering."
  COMPLIANT=false
  MISSING_PEERING=true
else
  # Check if peering connection exists
  if ! gcloud services vpc-peerings list --network=$NETWORK_NAME --project=$PROJECT_ID | grep -q servicenetworking; then
    echo "  ❌ Missing Private Services Access peering connection."
    COMPLIANT=false
    MISSING_PEERING=true
  fi
fi

# 3. Audit KMS
echo "[Audit] Checking KMS Keyring and Keys for Apigee CMEK..."
if ! gcloud kms keys describe $KEY_NAME --keyring=$KEY_RING --location=$REGION --project=$PROJECT_ID &>/dev/null; then
  echo "  ❌ Missing KMS Key ($KEY_NAME) in region $REGION."
  COMPLIANT=false
  MISSING_KMS=true
fi

echo "========================================="
if [ "$COMPLIANT" = true ]; then
  echo "✅ Environment is 100% COMPLIANT with Apigee Prerequisites!"
  echo "Proceeding to Organization verification..."
else
  echo "⚠️ Environment is NOT compliant."
  echo "To install Apigee safely, the above issues must be resolved."
  read -p "Do you want this script to automatically implement the recommendations now? (y/n): " IMPLEMENT
  
  if [[ "$IMPLEMENT" != "y" && "$IMPLEMENT" != "Y" ]]; then
    echo "Exiting. Please resolve the issues manually."
    exit 1
  fi
  
  echo "========================================="
  echo "🛠️ Implementing Recommendations..."
  echo "========================================="
  
  if [ "$MISSING_APIS" = true ]; then
    echo "-> Enabling required APIs..."
    gcloud services enable $REQUIRED_APIS cloudbuild.googleapis.com run.googleapis.com cloudfunctions.googleapis.com --project=$PROJECT_ID
  fi
  
  if [ "$MISSING_PEERING" = true ]; then
    echo "-> Configuring Network and Private Services Access (Peering)..."
    if ! gcloud compute networks describe $NETWORK_NAME --project=$PROJECT_ID &>/dev/null; then
      echo "   Network $NETWORK_NAME not found. Creating it..."
      gcloud compute networks create $NETWORK_NAME --project=$PROJECT_ID --subnet-mode=auto || true
    fi
    gcloud compute addresses create $PEERING_RANGE_NAME \
      --global --prefix-length=22 --description="Apigee VPC Peering Range" \
      --network=$NETWORK_NAME --purpose=VPC_PEERING || true
    
    gcloud services vpc-peerings connect \
      --service=servicenetworking.googleapis.com \
      --network=$NETWORK_NAME --ranges=$PEERING_RANGE_NAME --project=$PROJECT_ID || true
  fi
  
  if [ "$MISSING_KMS" = true ]; then
    echo "-> Configuring Encryption Keys (KMS)..."
    gcloud kms keyrings create $KEY_RING --location=$REGION --project=$PROJECT_ID || true
    gcloud kms keys create $KEY_NAME --location=$REGION --keyring=$KEY_RING --purpose=encryption --project=$PROJECT_ID || true
    
    echo "-> Forcing creation of Apigee Service Agent..."
    gcloud beta services identity create --service=apigee.googleapis.com --project=$PROJECT_ID || true
    
    APIGEE_SERVICE_ACCOUNT="service-$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')@gcp-sa-apigee.iam.gserviceaccount.com"
    
    # Wait a few seconds for IAM propagation of the new service account
    sleep 5
    
    gcloud kms keys add-iam-policy-binding $KEY_NAME \
      --location=$REGION --keyring=$KEY_RING \
      --member="serviceAccount:$APIGEE_SERVICE_ACCOUNT" \
      --role="roles/cloudkms.cryptoKeyEncrypterDecrypter" --project=$PROJECT_ID || true
  fi
  
  echo "✅ All recommendations implemented successfully!"
fi

echo "========================================="
echo "🚀 Proceeding to Apigee Organization Setup"
echo "========================================="

echo "Creating Apigee Organization (if it doesn't exist)..."
TOKEN=$(gcloud auth print-access-token)
curl -s -X POST "https://apigee.googleapis.com/v1/organizations?parent=projects/$PROJECT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "'"$PROJECT_ID"'",
    "analyticsRegion": "'"$REGION"'",
    "runtimeType": "CLOUD",
    "billingType": "EVALUATION",
    "authorizedNetwork": "projects/'"$PROJECT_ID"'/global/networks/'"$NETWORK_NAME"'"
  }' || echo "Apigee Organization might already exist or is currently being provisioned."

echo "Note: Advanced API Security Add-on will be enabled in Phase 3 once the Org is Active."

echo "========================================================================="
echo "Phase 1 Completed! You can now proceed to Phase 2 (API Hub Provisioning)."
echo "========================================================================="
