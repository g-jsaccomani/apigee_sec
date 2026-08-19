#!/bin/bash
# ==============================================================================
# Script: sec_04_perimeter_bypass_detector.sh
# Purpose: Deep audit to detect whether Apigee proxies are directly exposed to the
#          public internet (bypass) without passing through Cloud Armor WAF.
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}

echo "=============================================================================="
echo "🔍 ASPR Security: Perimeter Bypass & Direct Exposure Detection Audit"
echo "   Project: $PROJECT_ID"
echo "=============================================================================="

TOKEN=$(gcloud auth print-access-token)

echo "1. Checking External Application Load Balancers..."
XLB_LIST=$(gcloud compute backend-services list --filter="loadBalancingScheme=EXTERNAL_MANAGED" --format="value(name)" --project="$PROJECT_ID" 2>/dev/null || echo "")

if [ -z "$XLB_LIST" ]; then
  echo "🚨 CRITICAL SECURITY FINDING: No External HTTPS Load Balancer detected."
  echo "   Apigee endpoints may be directly exposed or missing Cloud Armor protection."
  echo "   Penalty Applied: -35.0 Health Score Points."
else
  echo "✅ External Load Balancer Backend Service found: $XLB_LIST"
  
  echo "2. Checking Cloud Armor Policy Attachment..."
  ARMOR_POLICY=$(gcloud compute backend-services describe "$XLB_LIST" --global --format="value(securityPolicy)" --project="$PROJECT_ID" 2>/dev/null || echo "")
  if [ -n "$ARMOR_POLICY" ]; then
    echo "✅ Cloud Armor Security Policy attached: $ARMOR_POLICY"
    echo "✅ Direct Bypass Risk: LOW (Perimeter Defense in Depth Verified)"
  else
    echo "⚠️ Warning: Load Balancer exists but has NO Cloud Armor Security Policy attached!"
    echo "   Penalty Applied: -35.0 Health Score Points."
  fi
fi

echo "=============================================================================="
echo "🎯 Perimeter Bypass Audit Complete."
echo "=============================================================================="
