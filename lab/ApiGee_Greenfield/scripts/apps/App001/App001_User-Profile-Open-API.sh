#!/bin/bash
function _finish_report {
    local exit_code=$?
    echo -e "\n========================================="
    echo "📊 SCRIPT EXECUTION REPORT"
    echo "========================================="
    if [ $exit_code -eq 0 ]; then
        echo "✅ All steps completed SUCCESSFULLY."
    else
        echo "❌ Script FAILED."
        echo "Please review the output above for errors."
    fi
    echo "========================================="
}
trap _finish_report EXIT

# =========================================================================
# App 1: User-Profile-Open-API (Open Access)
# Vulnerability: Absence of VerifyAPIKey or OAuthV2
# Backend: Cloud Function v2 (Node.js) public
# =========================================================================

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"

echo "=== 1. Creating Cloud Function Code (Node.js) ==="
gcloud services enable cloudfunctions.googleapis.com run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
mkdir -p app1-user-profile
cd app1-user-profile

cat << 'EOF' > index.js
const functions = require('@google-cloud/functions-framework');
functions.http('getUserProfile', (req, res) => {
  res.status(200).json({ id: "102938", name: "John Doe", profile: "Admin", email: "john@example.com" });
});
EOF

cat << 'EOF' > package.json
{
  "name": "user-profile-api",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": { "@google-cloud/functions-framework": "^3.0.0" }
}
EOF

echo "=== 2. Deploying Cloud Function (Public) ==="
gcloud functions deploy user-profile-open-api \
  --gen2 \
  --runtime=nodejs22 \
  --region=$REGION \
  --source=. \
  --entry-point=getUserProfile \
  --trigger-http \
  --allow-unauthenticated

FUNCTION_URL=$(gcloud functions describe user-profile-open-api --gen2 --region=$REGION --format="value(serviceConfig.uri)")

echo "=== 3. Generating Apigee Proxy ==="
cd ..
mkdir -p apigee-app1/apiproxy/proxies apigee-app1/apiproxy/targets

cat << 'EOF' > apigee-app1/apiproxy/User-Profile-Open-API.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<APIProxy revision="1" name="User-Profile-Open-API">
    <Basepaths>/user-profile</Basepaths>
    <Description>Public Vulnerable API - Open Access (No Auth)</Description>
    <Policies/>
    <ProxyEndpoints><ProxyEndpoint>default</ProxyEndpoint></ProxyEndpoints>
    <TargetEndpoints><TargetEndpoint>default</TargetEndpoint></TargetEndpoints>
</APIProxy>
EOF

cat << 'EOF' > apigee-app1/apiproxy/proxies/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ProxyEndpoint name="default">
    <!-- NO AUTHENTICATION POLICIES CONFIGURED HERE -->
    <PreFlow name="PreFlow"/>
    <HTTPProxyConnection>
        <BasePath>/user-profile</BasePath>
        <VirtualHost>secure</VirtualHost>
    </HTTPProxyConnection>
    <RouteRule name="default"><TargetEndpoint>default</TargetEndpoint></RouteRule>
</ProxyEndpoint>
EOF

cat << EOF > apigee-app1/apiproxy/targets/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<TargetEndpoint name="default">
    <HTTPTargetConnection><URL>${FUNCTION_URL}</URL></HTTPTargetConnection>
</TargetEndpoint>
EOF

cd apigee-app1 && zip -r ../User-Profile-Open-API-proxy.zip apiproxy && cd ..
echo "App 1 Completed! Bundle: User-Profile-Open-API-proxy.zip"
