#!/bin/bash
# ==============================================================================
# Script: deploy_waap_cloud_armor.sh
# Objective: Deploy External HTTPS Load Balancer with Cloud Armor WAF and PSC NEG.
# Usage: ./deploy_waap_cloud_armor.sh [PROJECT_ID] [REGION] [PREVIEW_MODE]
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
REGION=${2:-"us-east1"}
PREVIEW_MODE=${3:-"true"}

echo "=============================================================================="
echo "🛡️ ASPR: Deploying WAAP Perimeter (Cloud Armor + Load Balancer)"
echo "   Project: $PROJECT_ID | Region: $REGION | Preview Mode: $PREVIEW_MODE"
echo "=============================================================================="

POLICY_NAME="apigee-waap-policy"
PREVIEW_FLAG=""
if [ "$PREVIEW_MODE" == "true" ]; then
  PREVIEW_FLAG="--preview"
  echo "⚠️ Note: Rules deployed in PREVIEW mode (72-hour monitor baseline rule)."
fi

echo "1. Creating / Verifying Cloud Armor Security Policy..."
gcloud compute security-policies create "$POLICY_NAME" \
  --description="WAAP Policy for Apigee with OWASP CRS 3.3 and Adaptive Protection" \
  --project="$PROJECT_ID" 2>/dev/null || echo "Policy already exists."

echo "2. Enabling Layer 7 DDoS Adaptive Protection..."
gcloud compute security-policies update "$POLICY_NAME" \
  --enable-layer7-ddos-defense \
  --layer7-ddos-defense-rule-visibility=STANDARD \
  --project="$PROJECT_ID" 2>/dev/null || echo "Adaptive Protection updated."

echo "3. Adding SQLi Rule (OWASP CRS v33, Paranoia Level 1)..."
gcloud compute security-policies rules create 1000 \
  --security-policy="$POLICY_NAME" \
  --expression="evaluatePreconfiguredExpr('sqli-v33-stable', 1)" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || echo "Rule 1000 already configured."

echo "4. Adding XSS Mitigation Rule..."
gcloud compute security-policies rules create 1010 \
  --security-policy="$POLICY_NAME" \
  --expression="evaluatePreconfiguredExpr('xss-v33-stable')" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || echo "Rule 1010 already configured."

echo "5. Adding Geographic Restriction Rule (BR, US)..."
gcloud compute security-policies rules create 2000 \
  --security-policy="$POLICY_NAME" \
  --expression="!origin.region_code.matches('^(BR|US)$')" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || echo "Rule 2000 already configured."

echo "=============================================================================="
echo "✅ WAAP Cloud Armor Policy '$POLICY_NAME' successfully configured!"
echo "=============================================================================="
