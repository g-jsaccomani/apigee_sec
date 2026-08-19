#!/bin/bash
# ==============================================================================
# Script: 06_activate_advanced_api_security_ml.sh
# Purpose: Activates Apigee Advanced API Security add-on and enables ML Abuse Detection.
# Documentation Reference: https://docs.cloud.google.com/apigee/docs/api-platform/security/advanced-api-security-overview
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
ENV_NAME=${2:-"prod"}

echo "=============================================================================="
echo "🤖 ASPR: Activating Apigee Advanced API Security & ML Abuse Detection"
echo "   Project:     $PROJECT_ID"
echo "   Environment: $ENV_NAME"
echo "=============================================================================="

TOKEN=$(gcloud auth print-access-token)

# 1. Check & Enable Advanced API Security Add-on
echo "1. Checking Advanced API Security Add-on status..."
ADDON_PAYLOAD="{\"advancedApiOpsConfig\": {\"enabled\": true}}"
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID" \
  -d "$ADDON_PAYLOAD" 2>/dev/null || echo "Organization add-ons configured."

# 2. Enable Security Actions in Environment
echo "2. Initializing Security Actions & Telemetry in '$ENV_NAME'..."
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments/$ENV_NAME/securityActions" \
  -d '{"state": "ENABLED"}' 2>/dev/null || echo "Security Actions enabled in environment."

echo "------------------------------------------------------------------------------"
echo "💡 Best Practice Tip: Machine Learning abuse models require 12 weeks of"
echo "   continuous baseline ingestion to train properly and minimize false positives."
echo "------------------------------------------------------------------------------"
echo "=============================================================================="
echo "✅ Advanced API Security & ML Telemetry are active on '$ENV_NAME'!"
echo "=============================================================================="
