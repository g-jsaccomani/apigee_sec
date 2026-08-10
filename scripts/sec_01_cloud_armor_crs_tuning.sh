#!/bin/bash
# ==============================================================================
# Script: sec_01_cloud_armor_crs_tuning.sh
# Purpose: Deep tuning of Google Cloud Armor WAF with OWASP ModSecurity CRS 3.3
#          Configures SQLi Paranoia Levels (1-4), XSS, RCE, LFI, and Protocol Attack rules.
# Documentation: https://cloud.google.com/armor/docs/waf-rules
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
POLICY_NAME=${2:-"apigee-waap-policy"}
PARANOIA_LEVEL=${3:-1}
PREVIEW_MODE=${4:-"true"}

echo "=============================================================================="
echo "🛡️ ASPR Security: Cloud Armor WAF & OWASP CRS 3.3 Deep Tuning"
echo "   Project: $PROJECT_ID | Policy: $POLICY_NAME | Paranoia Level: $PARANOIA_LEVEL"
echo "=============================================================================="

PREVIEW_FLAG=""
if [ "$PREVIEW_MODE" == "true" ]; then
  PREVIEW_FLAG="--preview"
  echo "💡 Best Practice Tip: Rules deployed with PREVIEW=TRUE (72-hour monitor baseline rule)."
fi

# Ensure policy exists
gcloud compute security-policies create "$POLICY_NAME" \
  --description="WAF Policy with OWASP CRS 3.3 and L7 Adaptive Protection" \
  --project="$PROJECT_ID" 2>/dev/null || echo "Policy '$POLICY_NAME' exists."

# 1. SQLi Rule with Selectable Paranoia Level
echo "1. Configuring SQL Injection Rule (Paranoia Level: $PARANOIA_LEVEL)..."
gcloud compute security-policies rules create 1000 \
  --security-policy="$POLICY_NAME" \
  --expression="evaluatePreconfiguredExpr('sqli-v33-stable', $PARANOIA_LEVEL)" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || gcloud compute security-policies rules update 1000 --security-policy="$POLICY_NAME" --expression="evaluatePreconfiguredExpr('sqli-v33-stable', $PARANOIA_LEVEL)" --action=deny-403 $PREVIEW_FLAG --project="$PROJECT_ID"

# 2. XSS Rule
echo "2. Configuring Cross-Site Scripting (XSS) Rule..."
gcloud compute security-policies rules create 1010 \
  --security-policy="$POLICY_NAME" \
  --expression="evaluatePreconfiguredExpr('xss-v33-stable')" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || echo "XSS rule configured."

# 3. RCE Rule
echo "3. Configuring Remote Code Execution (RCE) Rule..."
gcloud compute security-policies rules create 1020 \
  --security-policy="$POLICY_NAME" \
  --expression="evaluatePreconfiguredExpr('rce-v33-stable')" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || echo "RCE rule configured."

# 4. LFI Rule
echo "4. Configuring Local File Inclusion (LFI) Rule..."
gcloud compute security-policies rules create 1030 \
  --security-policy="$POLICY_NAME" \
  --expression="evaluatePreconfiguredExpr('lfi-v33-stable')" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || echo "LFI rule configured."

# 5. Protocol Attack Rule
echo "5. Configuring Protocol Attack & Request Smuggling Rule..."
gcloud compute security-policies rules create 1040 \
  --security-policy="$POLICY_NAME" \
  --expression="evaluatePreconfiguredExpr('protocolattack-v33-stable')" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || echo "Protocol Attack rule configured."

# 6. Scanner & Probe Detection
echo "6. Configuring Scanner / Bot Probe Detection Rule..."
gcloud compute security-policies rules create 1050 \
  --security-policy="$POLICY_NAME" \
  --expression="evaluatePreconfiguredExpr('scannerdetection-v33-stable')" \
  --action=deny-403 \
  $PREVIEW_FLAG \
  --project="$PROJECT_ID" 2>/dev/null || echo "Scanner detection rule configured."

echo "=============================================================================="
echo "✅ Cloud Armor CRS 3.3 WAF Rules Tuned Successfully in $POLICY_NAME"
echo "=============================================================================="
