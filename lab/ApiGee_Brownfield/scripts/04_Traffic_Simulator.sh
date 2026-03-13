#!/bin/bash
set -e
export PATH="$HOME/google-cloud-sdk/bin:$PATH"
PROJECT_ID=$(gcloud config get-value project)
VM_NAME="apigee-traffic-tester"
ZONE="us-central1-a"
TARGET_IP=$(gcloud compute instances describe apigee-traffic-tester --zone=$ZONE --format='value(networkInterfaces[0].networkIP)' | cut -d'.' -f1,2,3).114
# Note: we assume Apigee is .114 based on greenfield, but we should actually fetch it.
TOKEN=$(gcloud auth print-access-token)
APIGEE_IP=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/instances" | grep '"host":' | head -1 | awk -F'"' '{print $4}')
if [ -z "$APIGEE_IP" ]; then APIGEE_IP="10.7.201.114"; fi

echo "========================================="
echo "💥 Starting Brownfield Traffic Simulator"
echo "========================================="
echo "Deploying continuous attack script to internal VM..."

gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --quiet --tunnel-through-iap --command="bash -s" << REMOTE_EOF
cat << 'INNER_EOF' > /tmp/brownfield_attack.sh
#!/bin/bash
echo "Starting continuous background simulation against legacy API..."
CURL_CMD="curl -s -o /dev/null -w "%{http_code} " -k --resolve legacy.poc-apigee.com:443:$APIGEE_IP https://legacy.poc-apigee.com"

while true; do
  # 1. Normal traffic (but without API key, which is a misconfiguration)
  \$CURL_CMD/legacy/echo
  
  # 2. Large Payload (Anomaly)
  LARGE_JSON=\\$(printf '{"data":"%0.sA" {1..15000}}')
  curl -s -o /dev/null -w "%{http_code} " -X POST -H "Content-Type: application/json" -d "\\$LARGE_JSON" -k --resolve legacy.poc-apigee.com:443:$APIGEE_IP https://legacy.poc-apigee.com/legacy/post
  
  # 3. Method enumeration / scraping bot behavior
  curl -s -o /dev/null -w "%{http_code} " -A "ScraperBot/1.0" -k --resolve legacy.poc-apigee.com:443:$APIGEE_IP https://legacy.poc-apigee.com/legacy/shadow-endpoint
  
  sleep 4
done
INNER_EOF
chmod +x /tmp/brownfield_attack.sh
pkill -f brownfield_attack.sh || true
nohup /tmp/brownfield_attack.sh > /tmp/brownfield_attack_logs.txt 2>&1 &
echo "✅ Brownfield attack is RUNNING in the background!"
REMOTE_EOF
