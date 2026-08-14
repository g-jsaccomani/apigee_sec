#!/bin/bash
# ==============================================================================
# Script: sec_15_generate_api_threat_model.sh
# Purpose: Shell wrapper for ASPR Threat Model & STRIDE Risk Assessment Generator.
# ==============================================================================
set -e

API_NAME=${1:-"PaymentGatewayProxy"}
BASE_URL=${2:-"https://api.boticario.com.br/v1/payments"}
PROJECT_ID=${3:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}

echo "=============================================================================="
echo "🛡️ ASPR Security: Generating STRIDE & OWASP API Threat Model"
echo "   API: $API_NAME | Base URL: $BASE_URL | Project: $PROJECT_ID"
echo "=============================================================================="

python3 "/Users/jsaccomani/Documents/Jetsky/My Projects/apigee_sec/scripts/sec_15_generate_api_threat_model.py" "$API_NAME" "$BASE_URL" "$PROJECT_ID"
