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
# App 5: Internal-Status-Verbose-API (Information Leakage)
# Vulnerability: No FaultRule, leaks stack trace and injects token
# Backend: GKE Autopilot (Node.js/Express)
# =========================================================================

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
CLUSTER_NAME="app5-cluster"
REPO_NAME="app5-repo"
IMAGE_NAME="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/verbose-api:v1"

echo "=== 1. GKE Infra and Artifact Registry ==="
gcloud container clusters create-auto $CLUSTER_NAME --region=$REGION --enable-private-nodes || true
gcloud artifacts repositories create $REPO_NAME --repository-format=docker --location=$REGION || true
gcloud auth configure-docker ${REGION}-docker.pkg.dev -q

echo "=== 2. Creating Node.js Code ==="
mkdir -p app5-verbose
cd app5-verbose

cat << 'EOF' > index.js
const express = require('express');
const app = express();
app.get('/', (req, res) => {
    throw new Error("Database query failed: connect ECONNREFUSED 10.2.4.5:5432");
});
app.use((err, req, res, next) => {
    res.status(500).send({ error: "Internal Server Error", message: err.message, stack: err.stack });
});
app.listen(8080);
EOF

cat << 'EOF' > package.json
{"name":"verbose-api","version":"1.0.0","dependencies":{"express":"^4.18.2"}}
EOF

cat << 'EOF' > Dockerfile
FROM node:18-slim
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "index.js"]
EOF

echo "=== 3. Build & Deploy ==="
gcloud services enable container.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com
gcloud builds submit --tag $IMAGE_NAME .

gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION || true

if ! command -v kubectl &> /dev/null || ! command -v gke-gcloud-auth-plugin &> /dev/null; then
    echo "⚙️ Installing kubectl and gke-gcloud-auth-plugin..."
    gcloud components install kubectl gke-gcloud-auth-plugin --quiet
fi

# Ensure plugin is loaded in shell
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Note: Ensure you have kubectl and the gke-gcloud-auth-plugin installed locally to deploy to GKE
kubectl create deployment verbose-api --image=$IMAGE_NAME || kubectl set image deployment/verbose-api verbose-api=$IMAGE_NAME
kubectl expose deployment verbose-api --type=LoadBalancer --port=80 --target-port=8080 || true

echo "=== 4. Generating Apigee Proxy ==="
cd ..
mkdir -p apigee-app5/apiproxy/proxies apigee-app5/apiproxy/targets apigee-app5/apiproxy/policies

cat << 'EOF' > apigee-app5/apiproxy/Internal-Status-Verbose-API.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<APIProxy revision="1" name="Internal-Status-Verbose-API">
    <Basepaths>/verbose</Basepaths>
    <Policies><Policy>Inject-Admin-Token</Policy></Policies>
    <ProxyEndpoints><ProxyEndpoint>default</ProxyEndpoint></ProxyEndpoints>
    <TargetEndpoints><TargetEndpoint>default</TargetEndpoint></TargetEndpoints>
</APIProxy>
EOF

cat << 'EOF' > apigee-app5/apiproxy/policies/Inject-Admin-Token.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<AssignMessage async="false" continueOnError="false" enabled="true" name="Inject-Admin-Token">
    <Add><Headers><Header name="X-Admin-Token">supersecret123</Header></Headers></Add>
    <AssignTo createNew="false" transport="http" type="response"/>
</AssignMessage>
EOF

cat << 'EOF' > apigee-app5/apiproxy/proxies/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ProxyEndpoint name="default">
    <FaultRules/><!-- NO FAULT RULES CONFIGURED TO MASK ERRORS -->
    <PreFlow name="PreFlow"/>
    <PostFlow name="PostFlow">
        <Response><Step><Name>Inject-Admin-Token</Name></Step></Response>
    </PostFlow>
    <HTTPProxyConnection>
        <BasePath>/verbose</BasePath>
        <VirtualHost>secure</VirtualHost>
    </HTTPProxyConnection>
    <RouteRule name="default"><TargetEndpoint>default</TargetEndpoint></RouteRule>
</ProxyEndpoint>
EOF

cat << EOF > apigee-app5/apiproxy/targets/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<TargetEndpoint name="default">
    <HTTPTargetConnection><URL>http://REPLACE_WITH_LB_IP</URL></HTTPTargetConnection>
</TargetEndpoint>
EOF

cd apigee-app5 && zip -r ../Internal-Status-Verbose-API-proxy.zip apiproxy && cd ..
echo "App 5 Completed! Bundle: Internal-Status-Verbose-API-proxy.zip"
