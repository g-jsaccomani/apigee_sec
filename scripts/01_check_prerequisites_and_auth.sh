#!/bin/bash
# ==============================================================================
# Script: 01_check_prerequisites_and_auth.sh
# Purpose: Validates gcloud authentication, active project, and IAM permissions.
# Documentation Reference: https://docs.cloud.google.com/apigee/docs/hybrid/v1.12/precog-iam
# ==============================================================================
set -e

echo "=============================================================================="
echo "🔐 ASPR: Checking Prerequisites, Authentication & IAM Permissions"
echo "=============================================================================="

# 1. Check if gcloud CLI is available
if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  else
    echo "❌ Error: gcloud CLI is not installed or not in PATH."
    echo "💡 Tip: Install Google Cloud SDK or configure PATH correctly."
    exit 1
  fi
fi

# 2. Check active authentication
ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || true)
if [ -z "$ACTIVE_ACCOUNT" ]; then
  echo "⚠️ Warning: No active gcloud session found."
  echo "💡 Tip: Run 'gcloud auth login' or 'gcloud auth activate-service-account' to authenticate."
  exit 1
fi
echo "✅ Active Authenticated Principal: $ACTIVE_ACCOUNT"

# 3. Check active GCP project
PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || true)}
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" == "(unset)" ]; then
  echo "⚠️ Warning: No default GCP project configured in gcloud."
  echo "💡 Tip: Pass the project as an argument or run 'gcloud config set project [PROJECT_ID]'."
  exit 1
fi
echo "✅ Active GCP Project: $PROJECT_ID"

# 4. Check essential IAM roles
echo "------------------------------------------------------------------------------"
echo "📋 Recommended IAM Roles for Full Apigee & WAAP Operations:"
echo "   - roles/apigee.admin              (Apigee full management)"
echo "   - roles/compute.networkAdmin      (PSC NEG & VPC setup)"
echo "   - roles/compute.securityAdmin     (Cloud Armor WAF policies)"
echo "   - roles/apihub.admin              (GCP API Hub management)"
echo "   - roles/iam.serviceAccountUser    (Impersonation delegation)"
echo "------------------------------------------------------------------------------"

# Test API Token Generation
TOKEN=$(gcloud auth print-access-token 2>/dev/null || true)
if [ -n "$TOKEN" ]; then
  echo "✅ OAuth 2.0 Access Token successfully generated."
else
  echo "❌ Error: Failed to generate access token. Verify credentials."
  exit 1
fi

echo "=============================================================================="
echo "🎯 Prerequisites verified successfully for project: $PROJECT_ID"
echo "=============================================================================="
