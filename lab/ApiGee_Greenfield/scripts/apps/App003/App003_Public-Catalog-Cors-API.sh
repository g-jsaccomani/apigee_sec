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
# App 3: Public-Catalog-Cors-API (Permissive CORS)
# Vulnerability: CORS pointing to * with AllowCredentials
# Backend: App Engine (Go)
# =========================================================================

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"

echo "=== 1. Enabling App Engine ==="
gcloud services enable run.googleapis.com

echo "=== 2. Creating Go Code ==="
mkdir -p app3-catalog
cd app3-catalog

cat << 'EOF' > main.go
package main
import (
	"fmt"
	"net/http"
	"os"
)
func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, `{"catalog": ["item1", "item2"]}`)
	})
	port := os.Getenv("PORT")
	if port == "" { port = "8080" }
	http.ListenAndServe(":"+port, nil)
}
EOF

cat << 'EOF' > go.mod
module catalog
go 1.21
EOF



echo "=== 3. Deploying to Cloud Run ==="
gcloud run deploy public-catalog-api \
  --source . \
  --region=$REGION \
  --allow-unauthenticated \
  --quiet
APP_URL=$(gcloud run services describe public-catalog-api --region=$REGION --format="value(status.url)")

echo "=== 4. Generating Apigee Proxy ==="
cd ..
mkdir -p apigee-app3/apiproxy/proxies apigee-app3/apiproxy/targets apigee-app3/apiproxy/policies

cat << 'EOF' > apigee-app3/apiproxy/Public-Catalog-Cors-API.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<APIProxy revision="1" name="Public-Catalog-Cors-API">
    <Basepaths>/catalog</Basepaths>
    <Description>API with extremely permissive CORS</Description>
    <Policies><Policy>CORS-Vulnerable</Policy></Policies>
    <ProxyEndpoints><ProxyEndpoint>default</ProxyEndpoint></ProxyEndpoints>
    <TargetEndpoints><TargetEndpoint>default</TargetEndpoint></TargetEndpoints>
</APIProxy>
EOF

cat << 'EOF' > apigee-app3/apiproxy/policies/CORS-Vulnerable.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<CORS async="false" continueOnError="false" enabled="true" name="CORS-Vulnerable">
    <AllowOrigins>
        <!-- VULNERABILITY: Global asterisk -->
        <Origin>*</Origin>
    </AllowOrigins>
    <AllowMethods>GET, PUT, POST, DELETE</AllowMethods>
    <AllowHeaders>origin, x-requested-with, accept, content-type</AllowHeaders>
    <ExposeHeaders>*</ExposeHeaders>
    <!-- VULNERABILITY: AllowCredentials true with Origin * (Simulated) -->
    <AllowCredentials>true</AllowCredentials>
    <GeneratePreflightResponse>true</GeneratePreflightResponse>
</CORS>
EOF

cat << 'EOF' > apigee-app3/apiproxy/proxies/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ProxyEndpoint name="default">
    <PreFlow name="PreFlow">
        <Request><Step><Name>CORS-Vulnerable</Name></Step></Request>
    </PreFlow>
    <HTTPProxyConnection>
        <BasePath>/catalog</BasePath>
        <VirtualHost>secure</VirtualHost>
    </HTTPProxyConnection>
    <RouteRule name="default"><TargetEndpoint>default</TargetEndpoint></RouteRule>
</ProxyEndpoint>
EOF

cat << EOF > apigee-app3/apiproxy/targets/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<TargetEndpoint name="default">
    <HTTPTargetConnection><URL>${APP_URL}</URL></HTTPTargetConnection>
</TargetEndpoint>
EOF

cd apigee-app3 && zip -r ../Public-Catalog-Cors-API-proxy.zip apiproxy && cd ..
echo "App 3 Completed! Bundle: Public-Catalog-Cors-API-proxy.zip"
