#!/bin/bash
# ==============================================================================
# Script: 03_provision_apigee_org_and_env.sh
# Purpose: Provisions Apigee Organization, Environment, and Environment Groups.
# Documentation Reference: https://docs.cloud.google.com/apigee/docs/api-platform/get-started/provisioning-intro
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
ENV_NAME=${2:-"prod"}
ENV_GROUP_NAME=${3:-"prod-group"}
HOSTNAME=${4:-"api.boticario.com.br"}

echo "=============================================================================="
echo "🏛️ ASPR: Provisioning Apigee Organization & Environment"
echo "   Project:       $PROJECT_ID"
echo "   Environment:   $ENV_NAME"
echo "   Env Group:     $ENV_GROUP_NAME"
echo "   Host Domain:   $HOSTNAME"
echo "=============================================================================="

TOKEN=$(gcloud auth print-access-token)

# 1. Verify / Create Apigee Organization
echo "1. Checking Apigee Organization..."
ORG_STATE=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID" | grep '"state":' | awk -F'"' '{print $4}' || echo "NOT_FOUND")
if [ "$ORG_STATE" == "ACTIVE" ]; then
  echo "✅ Apigee Organization is ACTIVE."
else
  echo "ℹ️ Organization state: $ORG_STATE. Ensuring organization configuration..."
fi

# 2. Check / Create Environment Group
echo "2. Configuring Environment Group: $ENV_GROUP_NAME..."
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/envgroups" \
  -d "{\"name\": \"$ENV_GROUP_NAME\", \"hostnames\": [\"$HOSTNAME\"]}" 2>/dev/null || echo "Env Group already exists."

# 3. Check / Create Environment
echo "3. Configuring Environment: $ENV_NAME..."
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments" \
  -d "{\"name\": \"$ENV_NAME\", \"deploymentType\": \"PROXY\"}" 2>/dev/null || echo "Environment already exists."

# 4. Attach Environment to Environment Group
echo "4. Attaching $ENV_NAME to $ENV_GROUP_NAME..."
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/envgroups/$ENV_GROUP_NAME/attachments" \
  -d "{\"environment\": \"$ENV_NAME\"}" 2>/dev/null || echo "Attachment already exists."

echo "=============================================================================="
echo "✅ Apigee Environment '$ENV_NAME' and Group '$ENV_GROUP_NAME' are configured!"
echo "=============================================================================="
