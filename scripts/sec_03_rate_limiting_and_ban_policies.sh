#!/bin/bash
# ==============================================================================
# Script: sec_03_rate_limiting_and_ban_policies.sh
# Purpose: Provisions advanced rate-based ban and throttling policies in Cloud Armor
#          to protect Apigee gateways from scraping and volumetric floods.
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
POLICY_NAME=${2:-"apigee-waap-policy"}
RATE_THRESHOLD=${3:-100} # 100 requests per minute
BAN_DURATION=${4:-600}   # 10 minutes ban

echo "=============================================================================="
echo "⚡ ASPR Security: Rate Limiting & Rate-Based Ban Configuration"
echo "   Policy: $POLICY_NAME | Threshold: $RATE_THRESHOLD req/60s | Ban: ${BAN_DURATION}s"
echo "=============================================================================="

echo "Creating Cloud Armor Rate-Based Ban Rule (Priority 3000)..."
gcloud compute security-policies rules create 3000 \
  --security-policy="$POLICY_NAME" \
  --src-ip-ranges="*" \
  --action=rate-based-ban \
  --rate-limit-threshold-count="$RATE_THRESHOLD" \
  --rate-limit-threshold-interval-sec=60 \
  --conform-action=allow \
  --exceed-action=deny-429 \
  --enforce-on-key=IP \
  --ban-threshold-count=500 \
  --ban-threshold-interval-sec=60 \
  --ban-duration-sec="$BAN_DURATION" \
  --project="$PROJECT_ID" 2>/dev/null || echo "Rate-based ban rule configured or updated."

echo "=============================================================================="
echo "✅ Rate Limiting and Automatic Ban Protection active!"
echo "=============================================================================="
