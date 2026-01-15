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
# App 2: Data-Processor-Unbound-API (Resource Exhaustion)
# Vulnerability: Absence of Quota and SpikeArrest
# Backend: Cloud Run (Python Flask) with VPC Connector
# =========================================================================

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"

echo "=== 1. Creating Network Infra and Connector ==="
gcloud services enable run.googleapis.com vpcaccess.googleapis.com
gcloud compute networks create vpc-app2 --subnet-mode=custom || true
gcloud compute networks subnets create sub-app2 --network=vpc-app2 --range=10.8.0.0/28 --region=$REGION || true
gcloud compute networks vpc-access connectors create vpc-conn-app2 \
  --network=vpc-app2 --region=$REGION --range=10.9.0.0/28 || true || true

echo "=== 2. Creating Python Code (Flask) ==="
mkdir -p app2-data-processor
cd app2-data-processor

cat << 'EOF' > main.py
from flask import Flask
app = Flask(__name__)
@app.route("/")
def process():
    return {"status": "processing", "data": "heavy load"}
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
EOF

cat << 'EOF' > requirements.txt
Flask==3.0.0
EOF

cat << 'EOF' > Dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "main.py"]
EOF

echo "=== 3. Deploying to Cloud Run ==="
gcloud run deploy data-processor-api \
  --source . \
  --region=$REGION \
  --vpc-connector=vpc-conn-app2 \
  --allow-unauthenticated \
  --quiet

RUN_URL=$(gcloud run services describe data-processor-api --region=$REGION --format="value(status.url)")

echo "=== 4. Generating Apigee Proxy ==="
cd ..
mkdir -p apigee-app2/apiproxy/proxies apigee-app2/apiproxy/targets

cat << 'EOF' > apigee-app2/apiproxy/Data-Processor-Unbound-API.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<APIProxy revision="1" name="Data-Processor-Unbound-API">
    <Basepaths>/data-processor</Basepaths>
    <Description>API Vulnerable to DoS - No Quota/SpikeArrest</Description>
    <Policies/>
    <ProxyEndpoints><ProxyEndpoint>default</ProxyEndpoint></ProxyEndpoints>
    <TargetEndpoints><TargetEndpoint>default</TargetEndpoint></TargetEndpoints>
</APIProxy>
EOF

cat << 'EOF' > apigee-app2/apiproxy/proxies/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ProxyEndpoint name="default">
    <!-- NO SPIKE ARREST OR QUOTA POLICY HERE -->
    <PreFlow name="PreFlow"/>
    <HTTPProxyConnection>
        <BasePath>/data-processor</BasePath>
        <VirtualHost>secure</VirtualHost>
    </HTTPProxyConnection>
    <RouteRule name="default"><TargetEndpoint>default</TargetEndpoint></RouteRule>
</ProxyEndpoint>
EOF

cat << EOF > apigee-app2/apiproxy/targets/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<TargetEndpoint name="default">
    <HTTPTargetConnection><URL>${RUN_URL}</URL></HTTPTargetConnection>
</TargetEndpoint>
EOF

cd apigee-app2 && zip -r ../Data-Processor-Unbound-API-proxy.zip apiproxy && cd ..
echo "App 2 Completed! Bundle: Data-Processor-Unbound-API-proxy.zip"
