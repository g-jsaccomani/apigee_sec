#!/bin/bash
function _finish_report {
    local exit_code=$?
    echo -e "\n========================================="
    echo "📊 SCRIPT EXECUTION REPORT"
    echo "========================================="
    if [ $exit_code -eq 0 ]; then
        echo "✅ All API Proxies deployed SUCCESSFULLY."
    else
        echo "❌ Script FAILED."
        echo "Please review the output above for errors."
    fi
    echo "========================================="
}
trap _finish_report EXIT

set -e
cd "$(dirname "$0")"

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi

PROJECT_ID=$(gcloud config get-value project)
ENV_NAME="poc-env"

echo "========================================="
echo "🚀 Starting Phase 4: Deploying Vulnerable Apps and Apigee Proxies"
echo "========================================="

APPS=(
  "App001_User-Profile-Open-API.sh|User-Profile-Open-API"
  "App002_Data-Processor-Unbound-API.sh|Data-Processor-Unbound-API"
  "App003_Public-Catalog-Cors-API.sh|Public-Catalog-Cors-API"
  "App004_Bulk-Ingestion-Raw-API.sh|Bulk-Ingestion-Raw-API"
  "App005_Internal-Status-Verbose-API.sh|Internal-Status-Verbose-API"
)

# Obter o token da Service Account impersonada (que tem permissão no Apigee)
TOKEN=$(gcloud auth print-access-token)

for app_info in "${APPS[@]}"; do
  SCRIPT="${app_info%%|*}"
  PROXY_NAME="${app_info##*|}"
  ZIP_FILE="${PROXY_NAME}-proxy.zip"

  echo -e "\n---------------------------------------------------"
  echo "▶️ Processing: $PROXY_NAME"
  echo "---------------------------------------------------"

  # Verifica se já está deployed
  STATUS_RESP=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments/$ENV_NAME/apis/$PROXY_NAME/deployments")
  if echo "$STATUS_RESP" | grep -q '"deployStartTime"'; then
    echo "⏭️  Proxy '$PROXY_NAME' is already deployed in '$ENV_NAME'. Skipping to save time!"
    continue
  fi

  echo "▶️ Executing Backend Script: $SCRIPT"
  APP_DIR="apps/$(echo $SCRIPT | cut -d'_' -f1)"
  cd "$APP_DIR"
  chmod +x "$SCRIPT"
  ./"$SCRIPT"


  if [ -f "$ZIP_FILE" ]; then
    echo "⬆️ Uploading Proxy Bundle: $ZIP_FILE to Apigee as $PROXY_NAME..."
    
    # Import the proxy ZIP via Apigee REST API
    UPLOAD_RESP=$(curl -s -w "\n%{http_code}" -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/apis?action=import&name=$PROXY_NAME" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/octet-stream" \
      --data-binary @"$ZIP_FILE")
    
    HTTP_CODE=$(echo "$UPLOAD_RESP" | tail -n1)
    BODY=$(echo "$UPLOAD_RESP" | sed '$d')

    if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" ]]; then
      REV=$(echo "$BODY" | grep -o '"revision": "[0-9]*"' | awk -F'"' '{print $4}' | head -n 1)
      
      if [ -z "$REV" ]; then
        echo "❌ Failed to parse revision from successful upload response:"
        echo "$BODY"
      else
        echo "✅ Proxy uploaded successfully. Revision: $REV"
        echo "🔄 Deploying Revision $REV to environment '$ENV_NAME'..."
        
        DEPLOY_RESP=$(curl -s -w "\n%{http_code}" -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments/$ENV_NAME/apis/$PROXY_NAME/revisions/$REV/deployments?override=true" \
          -H "Authorization: Bearer $TOKEN")
        
        DEPLOY_HTTP=$(echo "$DEPLOY_RESP" | tail -n1)
        DEPLOY_BODY=$(echo "$DEPLOY_RESP" | sed '$d')

        if [[ "$DEPLOY_HTTP" == "200" || "$DEPLOY_HTTP" == "201" ]]; then
           echo "✅ Deployment requested successfully! (Apigee will start routing traffic shortly)"
        else
           echo "⚠️ Deployment API returned HTTP $DEPLOY_HTTP. Response:"
           echo "$DEPLOY_BODY"
        fi
      fi
    else
      echo "❌ Failed to upload proxy. HTTP $HTTP_CODE. Response:"
      echo "$BODY"
    fi
  else
    echo "❌ Expected ZIP file $ZIP_FILE not found! Skipping Apigee upload."
  fi
  
  cd ../../
done

echo -e "\n================================================================="
echo "✅ All Apps and Apigee Proxies are deployed!"
echo "Note: It might take a few minutes for the new proxies to become active and reachable."
echo "You can view them in the Apigee Console under 'API Proxies'."
echo "================================================================="
