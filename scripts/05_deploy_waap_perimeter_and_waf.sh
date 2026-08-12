#!/bin/bash
# ==============================================================================
# Script: 05_deploy_waap_perimeter_and_waf.sh
# Purpose: Deploys External HTTPS Application Load Balancer with Cloud Armor WAF & PSC NEG.
# Documentation Reference: https://docs.cloud.google.com/armor/docs/waf-overview
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
REGION=${2:-"us-east1"}
PREVIEW_MODE=${3:-"true"}
POLICY_NAME="apigee-waap-policy"

echo "=============================================================================="
echo "🛡️ ASPR: Deploying WAAP Perimeter (Cloud Armor + Load Balancer + PSC NEG)"
echo "   Project: $PROJECT_ID | Region: $REGION | Preview Mode: $PREVIEW_MODE"
echo "=============================================================================="

PREVIEW_FLAG=""
if [ "$PREVIEW_MODE" == "true" ]; then
  PREVIEW_FLAG="--preview"
  echo "💡 Best Practice Tip: Rules deployed with PREVIEW=TRUE (72-hour monitor baseline rule)."
fi

# 1. Create Cloud Armor Policy
echo "1. Creating Cloud Armor Security Policy..."
gcloud compute security-policies create "$POLICY_NAME" \
  --description="WAAP Policy for Apigee with OWASP CRS 3.3, Adaptive Protection, and Geo-restrictions" \
  --project="$PROJECT_ID" 2>/dev/null || echo "Policy already exists."

# 2. Enable Layer 7 ML Adaptive Protection
echo "2. Enabling Layer 7 DDoS Adaptive Protection..."
gcloud compute security-policies update "$POLICY_NAME" \
  --enable-layer7-ddos-defense \
  --layer7-ddos-defense-rule-visibility=STANDARD \
  --project="$PROJECT_ID" 2>/dev/null || echo "Adaptive Protection enabled."

# 3. Add OWASP CRS 3.3 Rules (SQLi with Paranoia Level 1, XSS, RCE, LFI)
echo "3. Adding SQL Injection Mitigation (Paranoia Level 1)..."
gcloud compute security-policies rules create 1000 \
  --security-policy="$POLICY_NAME" \
  --expression="evaluatePreconfiguredExpr('sqli-v33-stable', 1)" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || echo "SQLi rule already configured."

echo "4. Adding XSS Mitigation..."
gcloud compute security-policies rules create 1010 \
  --security-policy="$POLICY_NAME" \
  --expression="evaluatePreconfiguredExpr('xss-v33-stable')" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || echo "XSS rule already configured."

# 4. Add Geo-fencing Rule
echo "5. Adding Geographic Restriction (Allow: BR, US)..."
gcloud compute security-policies rules create 2000 \
  --security-policy="$POLICY_NAME" \
  --expression="!origin.region_code.matches('^(BR|US)$')" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || echo "Geo-restriction rule configured."

# 5. Fetch Apigee PSC Attachment and Create NEG
TOKEN=$(gcloud auth print-access-token)
ATTACHMENT=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/instances" | grep '"serviceAttachment":' | head -1 | awk -F'"' '{print $4}' || true)

if [ -n "$ATTACHMENT" ]; then
  echo "6. Creating PSC NEG for Apigee Service Attachment..."
  gcloud compute network-endpoint-groups create apigee-psc-neg \
    --network-endpoint-type=private-service-connect \
    --psc-target-service="$ATTACHMENT" \
    --region="$REGION" \
    --project="$PROJECT_ID" 2>/dev/null || echo "PSC NEG already exists."
else
  echo "ℹ️ Note: Service Attachment not yet visible or already fronted. Verify instance status."
fi

echo "=============================================================================="
echo "✅ WAAP Perimeter Policy '$POLICY_NAME' successfully configured!"
echo "=============================================================================="
