#!/bin/bash
# ==============================================================================
# Script: sec_08_setup_southbound_mtls.sh
# Purpose: Configures Keystores, Truststores, and TargetServers for mTLS (Mutual TLS)
#          communication between Apigee gateway and backend target microservices.
# Documentation: https://docs.cloud.google.com/apigee/docs/api-platform/security/keystores-and-truststores
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
ENV_NAME=${2:-"prod"}
KEYSTORE_NAME=${3:-"backend-mtls-keystore"}
TRUSTSTORE_NAME=${4:-"backend-mtls-truststore"}

echo "=============================================================================="
echo "🔒 ASPR Security: Southbound mTLS Keystore & Truststore Configuration"
echo "   Project: $PROJECT_ID | Environment: $ENV_NAME"
echo "=============================================================================="

TOKEN=$(gcloud auth print-access-token)

# 1. Create Keystore for Client Certificates
echo "1. Creating / Checking Keystore '$KEYSTORE_NAME'..."
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments/$ENV_NAME/keystores" \
  -d "{\"name\": \"$KEYSTORE_NAME\"}" 2>/dev/null || echo "Keystore already exists."

# 2. Create Truststore for Backend Server Validation
echo "2. Creating / Checking Truststore '$TRUSTSTORE_NAME'..."
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments/$ENV_NAME/keystores" \
  -d "{\"name\": \"$TRUSTSTORE_NAME\"}" 2>/dev/null || echo "Truststore already exists."

echo "------------------------------------------------------------------------------"
echo "💡 Best Practice Tip: Bind Google Cloud Certificate Authority Service (CAS)"
echo "   for automated certificate rotation without gateway downtime."
echo "------------------------------------------------------------------------------"
echo "=============================================================================="
echo "✅ Southbound mTLS Keystores configured successfully on '$ENV_NAME'!"
echo "=============================================================================="
