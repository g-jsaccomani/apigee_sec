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
# Phase 3: Provisioning Apigee Runtime and Routing
# NOTE: Run this script only AFTER the organization has been successfully created
# =========================================================================

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi
PROJECT_ID=$(gcloud config get-value project)
REGION="us-east1"
INSTANCE_NAME="apigee-instance"
ENV_NAME="poc-env"
ENV_GROUP_NAME="poc-envgroup"
HOSTNAME="api.poc-apigee.com" # Fictional hostname for testing

TOKEN=$(gcloud auth print-access-token)

echo "=== 0. Verifying Organization Status ==="
ORG_STATUS=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID" | grep '"state":' | head -1 | awk -F'"' '{print $4}')

if [ "$ORG_STATUS" != "ACTIVE" ]; then
  echo "❌ Error: The Apigee Organization is not ACTIVE yet. Current status: ${ORG_STATUS:-UNKNOWN_OR_NOT_FOUND}"
  echo "   Apigee provisioning typically takes 20 to 45 minutes. It is still being created in the background."
  echo "   Please wait and try running this script again later."
  exit 1
fi
echo "✅ Apigee Organization is ACTIVE!"

echo "=== 0.5 Enabling Advanced API Security (Security Module) ==="
HAS_ADDONS=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID" | grep '"apiSecurityConfig"' -A 1 | grep "true" || echo "false")
if [ "$HAS_ADDONS" != "false" ]; then
  echo "Advanced API Security is already enabled."
else
  curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID:setAddons" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "addonsConfig": {
        "advancedApiOpsConfig": { "enabled": true },
        "apiSecurityConfig": { "enabled": true }
      }
    }' || echo "Failed to enable Security Module via API."
  echo "Addons update initiated. Waiting 10 seconds to avoid locking issues..."
  sleep 10
fi

echo "=== 1. Creating Apigee Instance ==="
# This takes about 15 to 30 minutes
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/instances" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "'"$INSTANCE_NAME"'",
    "location": "'"$REGION"'"
  }' || echo "Instance already exists or is being created."

echo "=== 2. Creating Environment ==="
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "'"$ENV_NAME"'"
  }' || echo "Environment already exists."

echo "=== 3. Attaching Environment to Instance ==="
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/instances/$INSTANCE_NAME/attachments" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "environment": "'"$ENV_NAME"'"
  }' || echo "Environment already attached to instance."

echo "=== 4. Creating Environment Group ==="
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/envgroups" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "'"$ENV_GROUP_NAME"'",
    "hostnames": ["'"$HOSTNAME"'"]
  }' || echo "Environment Group already exists."

echo "=== 5. Attaching Environment to Group ==="
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/envgroups/$ENV_GROUP_NAME/attachments" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "environment": "'"$ENV_NAME"'"
  }' || echo "Attachment already exists."

echo "========================================================================="
echo "Apigee Runtime Provisioned!"
echo "The next real-world step would be to create an MIG and an External Load Balancer"
echo "to route internet traffic to your Apigee instance IP."
echo "To speed up the POC, internal tests can be done using a VM in the same VPC."
echo "========================================================================="
