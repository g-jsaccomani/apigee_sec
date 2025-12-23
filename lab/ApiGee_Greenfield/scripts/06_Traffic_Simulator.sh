#!/bin/bash

function _finish_report {
    local exit_code=$?
    echo -e "\n========================================="
    if [ $exit_code -eq 0 ]; then
        echo "✅ All steps completed SUCCESSFULLY."
    else
        echo "❌ Script FAILED."
    fi
    echo "========================================="
}
trap _finish_report EXIT

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi

PROJECT_ID=$(gcloud config get-value project)
VM_NAME="apigee-traffic-tester"
ZONE="us-central1-a"

echo "========================================="
echo "🔍 Scanning for Apigee Instances..."
echo "========================================="

TOKEN=$(gcloud auth print-access-token)
INSTANCES_JSON=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/instances")

declare -a INSTANCE_NAMES
declare -a INSTANCE_IPS

COUNT=0
while read -r name host; do
  if [ -n "$name" ] && [ "$name" != "null" ]; then
    INSTANCE_NAMES[$COUNT]=$name
    INSTANCE_IPS[$COUNT]=$host
    COUNT=$((COUNT+1))
  fi
done < <(echo "$INSTANCES_JSON" | grep -E '"name"|"host"' | sed 's/"//g; s/,//g' | awk '{print $2}' | paste - -)

if [ $COUNT -eq 0 ]; then
  echo "❌ No Apigee instances found in project $PROJECT_ID!"
  exit 1
fi

echo "Available Apigee Instances:"
for i in "${!INSTANCE_NAMES[@]}"; do
  echo " [$i] ${INSTANCE_NAMES[$i]} (IP: ${INSTANCE_IPS[$i]})"
done

echo ""
# Use /dev/tty to read input when piped/executed
read -p "Enter the number of the instance to target [0]: " SELECTION </dev/tty
SELECTION=${SELECTION:-0}

if [ -z "${INSTANCE_NAMES[$SELECTION]}" ]; then
  echo "❌ Invalid selection."
  exit 1
fi

TARGET_IP="${INSTANCE_IPS[$SELECTION]}"
TARGET_NAME="${INSTANCE_NAMES[$SELECTION]}"

echo ""
echo "Select Simulation Mode:"
echo " [1] One-shot Execution (Fast, runs once)"
echo " [2] Continuous Background Execution (Runs forever every ~5s to generate steady insights)"
read -p "Choice [1]: " RUN_MODE </dev/tty
RUN_MODE=${RUN_MODE:-1}

echo "🎯 Selected: $TARGET_NAME ($TARGET_IP)"
echo "🚀 Connecting to internal VM ($VM_NAME) via IAP SSH to execute traffic simulation..."

if [ "$RUN_MODE" -eq 2 ]; then
  echo "📡 Configuring continuous background simulation..."
  gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --quiet --tunnel-through-iap --command="bash -s" << REMOTE_EOF
cat << INNER_EOF > /tmp/continuous_attack.sh
#!/bin/bash
echo "Starting continuous background simulation..."
CURL_CMD="curl -s -o /dev/null -w \"%{http_code} \" -k --resolve api.poc-apigee.com:443:$TARGET_IP https://api.poc-apigee.com"

while true; do
  \${CURL_CMD}/user-profile
  \${CURL_CMD}/data-processor -X GET
  
  LARGE_JSON=\\\$(printf '{"data":"%0.sA" {1..10000}}')
  curl -s -o /dev/null -w "%{http_code} " -X POST -H "Content-Type: application/json" -d "\\\$LARGE_JSON" -k --resolve api.poc-apigee.com:443:$TARGET_IP https://api.poc-apigee.com/bulk-ingestion
  
  curl -s -o /dev/null -w "%{http_code} " -X OPTIONS -H "Origin: https://malicious-attacker.com" -H "Access-Control-Request-Method: GET" -k --resolve api.poc-apigee.com:443:$TARGET_IP https://api.poc-apigee.com/catalog
  
  sleep 5
done
INNER_EOF
chmod +x /tmp/continuous_attack.sh
nohup /tmp/continuous_attack.sh > /tmp/attack_logs.txt 2>&1 &
echo "✅ Continuous traffic simulation is now RUNNING IN THE BACKGROUND on $VM_NAME!"
echo "You can check logs on the VM at: /tmp/attack_logs.txt"
REMOTE_EOF
else
  # ONE SHOT
  gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --quiet --tunnel-through-iap --command="bash -s" << REMOTE_EOF
echo "========================================="
echo "Starting Malicious Traffic Simulation"
echo "========================================="

CURL_CMD="curl -s -o /dev/null -w \"%{http_code} \" -k --resolve api.poc-apigee.com:443:$TARGET_IP https://api.poc-apigee.com"

echo "[1/4] Simulation: Open Access (Data Leakage)"
for i in {1..20}; do
  \${CURL_CMD}/user-profile
done
echo ""

echo "[2/4] Simulation: Resource Exhaustion (DoS)"
for i in {1..100}; do
  \${CURL_CMD}/data-processor -X GET &
done
wait
echo "Done."

echo "[3/4] Simulation: Malicious Payload / Injection"
LARGE_JSON=\$(printf '{"data":"%0.sA" {1..50000}}')
curl -s -o /dev/null -w "%{http_code} " -X POST -H "Content-Type: application/json" -d "\$LARGE_JSON" -k --resolve api.poc-apigee.com:443:$TARGET_IP https://api.poc-apigee.com/bulk-ingestion
echo ""

echo "[4/4] Simulation: Malicious CORS"
curl -s -i -X OPTIONS -H "Origin: https://malicious-attacker.com" -H "Access-Control-Request-Method: GET" -k --resolve api.poc-apigee.com:443:$TARGET_IP https://api.poc-apigee.com/catalog | grep "Access-Control-Allow-Origin" || true

echo ""
echo "✅ Traffic generated successfully from inside the VPC!"
REMOTE_EOF
fi

echo ""
echo "🎉 Attack simulation configuration completed!"
echo "Wait 15 to 30 minutes for data to appear in the Advanced API Security dashboards."
