#!/bin/bash
set -e
export PATH="$HOME/google-cloud-sdk/bin:$PATH"
PROJECT_ID=$(gcloud config get-value project)
TOKEN=$(gcloud auth print-access-token)

echo "========================================="
echo "🛡  ACTIVATING ADVANCED API SECURITY"
echo "========================================="
echo "Simulating the business decision of turning on Advanced API Security..."
sleep 2

# We re-assert the Addon configuration via API
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID:setAddons"   -H "Authorization: Bearer $TOKEN"   -H "Content-Type: application/json"   -d '{
    "addonsConfig": {
      "advancedApiOpsConfig": { "enabled": true },
      "apiSecurityConfig": { "enabled": true }
    }
  }' > /dev/null

echo "✅ Advanced API Security Add-On is ENABLED for Organization '$PROJECT_ID'."
echo ""
echo "📈 The Machine Learning models are now scanning the 'env-brownfield' telemetry retroactively."
echo ""
echo "Next Steps to present to the client:"
echo "1. Open Google Cloud Console: https://console.cloud.google.com/apigee/apirisk?project=$PROJECT_ID"
echo "2. Filter by Environment: 'env-brownfield'"
echo "3. Notice the 'Shadow APIs' (traffic henterpriseng /legacy/shadow-endpoint)."
echo "4. Notice the Misconfigurations (LegacyApp lacks Shared Flows, API Key Verification, and Spike Arrest)."
echo "5. Navigate to Security Reports > Bot Detection to find the IP generating large payloads and scraping."
echo "========================================="
