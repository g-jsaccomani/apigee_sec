#!/bin/bash

function _finish_report {
    local exit_code=$?
    echo -e "\n========================================="
    if [ $exit_code -eq 0 ]; then
        echo "✅ Background traffic stopped SUCCESSFULLY."
    else
        echo "❌ Failed to stop traffic."
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
echo "🛑 Stopping Continuous Traffic Simulator..."
echo "========================================="

echo "🚀 Connecting to internal VM ($VM_NAME) via IAP SSH..."

gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --quiet --tunnel-through-iap --command="bash -s" << REMOTE_EOF
echo "Finding and killing the continuous_attack.sh process..."
pkill -f "continuous_attack.sh" || echo "No running simulation found."
rm -f /tmp/continuous_attack.sh
rm -f /tmp/attack_logs.txt
echo "✅ All background traffic simulations have been terminated."
REMOTE_EOF

