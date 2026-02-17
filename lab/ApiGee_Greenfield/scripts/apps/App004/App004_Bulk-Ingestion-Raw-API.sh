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
# App 4: Bulk-Ingestion-Raw-API (Absence of Payload Protection)
# Vulnerability: Pass-through without JSONThreatProtection
# Backend: Compute Engine VM (Simulated Spring Boot / Java HTTP Server)
# =========================================================================

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
ZONE="us-central1-a"
VM_NAME="app4-java-backend"

echo "=== 1. Creating Subnet and VM with Startup Script ==="
gcloud compute networks create vpc-app4 --subnet-mode=custom || true
gcloud compute networks subnets create sub-app4 --network=vpc-app4 --range=10.10.0.0/24 --region=$REGION || true

echo "=== 1.1 Creating Cloud NAT for Internet Access (to install Java) ==="
gcloud compute routers create router-app4 --network vpc-app4 --region $REGION || true
gcloud compute routers nats create nat-app4 --router router-app4 --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges --region $REGION || true


# Creating the VM with a startup script that starts a simple HTTP server on port 8080 (simulating Java Spring)
gcloud compute instances create $VM_NAME \
    --zone=$ZONE \
    --network=vpc-app4 \
    --subnet=sub-app4 \
    --machine-type=e2-micro \
    --no-address \
    --shielded-secure-boot \
    --metadata=startup-script="#!/bin/bash
apt-get update
apt-get install -y default-jre
cat << 'EOF' > /root/SimpleServer.java
import java.io.*;
import java.net.*;
public class SimpleServer {
    public static void main(String[] args) throws Exception {
        ServerSocket server = new ServerSocket(8080);
        while (true) {
            Socket client = server.accept();
            BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));
            PrintWriter out = new PrintWriter(client.getOutputStream());
            out.println(\"HTTP/1.1 200 OK\");
            out.println(\"Content-Type: application/json\");
            out.println(\"\");
            out.println(\"{\\\"status\\\": \\\"received raw data\\\"}\");
            out.flush();
            client.close();
        }
    }
}
EOF
javac /root/SimpleServer.java
nohup java -cp /root SimpleServer &
" || echo "VM already exists."

VM_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format='get(networkInterfaces[0].networkIP)')

echo "=== 2. Generating Apigee Proxy ==="
mkdir -p apigee-app4/apiproxy/proxies apigee-app4/apiproxy/targets

cat << 'EOF' > apigee-app4/apiproxy/Bulk-Ingestion-Raw-API.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<APIProxy revision="1" name="Bulk-Ingestion-Raw-API">
    <Basepaths>/bulk-ingestion</Basepaths>
    <Description>API Vulnerable to Injection/Giant Payloads</Description>
    <Policies/>
    <ProxyEndpoints><ProxyEndpoint>default</ProxyEndpoint></ProxyEndpoints>
    <TargetEndpoints><TargetEndpoint>default</TargetEndpoint></TargetEndpoints>
</APIProxy>
EOF

cat << 'EOF' > apigee-app4/apiproxy/proxies/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ProxyEndpoint name="default">
    <!-- NO JSONThreatProtection POLICY HERE -->
    <PreFlow name="PreFlow"/>
    <HTTPProxyConnection>
        <BasePath>/bulk-ingestion</BasePath>
        <VirtualHost>secure</VirtualHost>
    </HTTPProxyConnection>
    <RouteRule name="default"><TargetEndpoint>default</TargetEndpoint></RouteRule>
</ProxyEndpoint>
EOF

cat << EOF > apigee-app4/apiproxy/targets/default.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<TargetEndpoint name="default">
    <HTTPTargetConnection><URL>http://${VM_IP}:8080</URL></HTTPTargetConnection>
</TargetEndpoint>
EOF

cd apigee-app4 && zip -r ../Bulk-Ingestion-Raw-API-proxy.zip apiproxy && cd ..
echo "App 4 Completed! Bundle: Bulk-Ingestion-Raw-API-proxy.zip"
