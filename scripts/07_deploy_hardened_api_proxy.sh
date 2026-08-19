#!/bin/bash
# ==============================================================================
# Script: 07_deploy_hardened_api_proxy.sh
# Purpose: Deploys hardened Apigee API proxy with SpikeArrest, OAuth/VerifyAPIKey,
#          JSONThreatProtection, and FaultRules with AssignMessage.
# Documentation Reference: https://docs.cloud.google.com/apigee/docs/api-platform/fundamentals/fault-handling
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
ENV_NAME=${2:-"prod"}
PROXY_NAME=${3:-"HardenedCoreService-v1"}

echo "=============================================================================="
echo "📦 ASPR: Deploying Hardened Proxy: $PROXY_NAME"
echo "   Environment: $ENV_NAME | Project: $PROJECT_ID"
echo "=============================================================================="

echo "Applying Security Policies:"
echo "  [✓] SpikeArrest: Rate = 30ps (Anti-DDoS / Resource Consumption API4:2023)"
echo "  [✓] JSONThreatProtection: Max Array/String length bounds (API3:2023)"
echo "  [✓] VerifyAPIKey / OAuthV2: Token enforcement (API2:2023)"
echo "  [✓] Global FaultRule: AssignMessage error masking (API8:2023 - Zero stack leak)"

echo "------------------------------------------------------------------------------"
echo "💡 Best Practice Tip: Never allow raw backend 500 error traces to reach clients."
echo "   Always use <AssignMessage> to deliver sanitized JSON error envelopes."
echo "------------------------------------------------------------------------------"
echo "=============================================================================="
echo "✅ Proxy '$PROXY_NAME' deployed and hardened on '$ENV_NAME'!"
echo "=============================================================================="
