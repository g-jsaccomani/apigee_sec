#!/bin/bash
set -e
cd "$(dirname "$0")/.."
export PATH="$HOME/google-cloud-sdk/bin:$PATH"
PROJECT_ID=$(gcloud config get-value project)
TOKEN=$(gcloud auth print-access-token)
ENV_NAME="env-brownfield"

echo "========================================="
echo "🛠 Deploying Legacy (Unprotected) APIs"
echo "========================================="

APPS=("LegacyApp" "LegacyAuthApp" "LegacyPaymentApp" "LegacyInventoryApp" "LegacyCustomerApp")

for APP_NAME in "${APPS[@]}"; do
  echo "Uploading $APP_NAME proxy bundle..."
  REV=$(curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/apis?action=import&name=$APP_NAME" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@scripts/apps/$APP_NAME/$APP_NAME.zip" | grep '"revision":' | awk -F'"' '{print $4}')

  if [ -z "$REV" ]; then
    # If it exists, get latest revision
    REV=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/apis/$APP_NAME" | grep -o '"revision": \[[^]]*\]' | grep -o '[0-9]*' | tail -1)
    echo "$APP_NAME already exists, using revision $REV"
  else
    echo "Imported $APP_NAME revision $REV"
  fi

  echo "Deploying $APP_NAME revision $REV to environment '$ENV_NAME'..."
  curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments/$ENV_NAME/apis/$APP_NAME/revisions/$REV/deployments" \
    -H "Authorization: Bearer $TOKEN"
  echo ""
done

echo "========================================="
echo "✅ All Legacy APIs Deployed to Brownfield!"
echo "========================================="
