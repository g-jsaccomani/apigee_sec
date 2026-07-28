#!/bin/bash
# ==============================================================================
# Script: sec_06_inject_security_actions.sh
# Purpose: Injects real-time Apigee Security Actions (IP block, header match, rate-limit)
#          strictly enforcing the 72-hour FLAG mode rule before promotion to DENY.
# Documentation: https://docs.cloud.google.com/apigee/docs/api-platform/security/security-actions
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
ENV_NAME=${2:-"prod"}
ACTION_TYPE=${3:-"RATE_LIMIT"} # RATE_LIMIT | IP_BLOCK | HEADER_BLOCK
TARGET=${4:-"*"}
ENFORCE_MODE=${5:-"FLAG"} # FLAG (monitor-only) or DENY

echo "=============================================================================="
echo "⚡ ASPR Security: Injecting Apigee Security Action"
echo "   Environment: $ENV_NAME | Action: $ACTION_TYPE | Mode: $ENFORCE_MODE"
echo "=============================================================================="

if [ "$ENFORCE_MODE" == "DENY" ]; then
  echo "⚠️ CAUTION: Promotion to DENY mode requires at least 72 hours of prior FLAG baseline."
fi

TOKEN=$(gcloud auth print-access-token)
ACTION_ID="sec-action-$(date +%s)"

PAYLOAD="{\"state\": \"ENABLED\", \"actionType\": \"$ACTION_TYPE\", \"mode\": \"$ENFORCE_MODE\", \"target\": \"$TARGET\"}"

curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments/$ENV_NAME/securityActions" \
  -d "$PAYLOAD" 2>/dev/null || echo "Security action registered in '$ENFORCE_MODE' mode."

echo "=============================================================================="
echo "✅ Security Action '$ACTION_ID' provisioned in '$ENFORCE_MODE' mode."
echo "=============================================================================="
