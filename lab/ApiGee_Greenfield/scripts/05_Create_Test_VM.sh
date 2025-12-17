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
# Phase 5 (Alternative): Create a Test VM for Internal Traffic Generation
# Since Apigee is peered internally on your VPC, it does not have a public IP
# by default. This script creates a tiny VM inside your VPC so you can SSH
# into it and run the traffic simulator internally.
# =========================================================================

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi
PROJECT_ID=$(gcloud config get-value project)
ZONE="us-central1-a"
NETWORK="default"
VM_NAME="apigee-traffic-tester"

echo "=== 1. Creating internal test VM ==="
# Ensure IAP SSH firewall rule exists
gcloud compute firewall-rules create allow-iap-ssh --network default --allow tcp:22 --source-ranges 35.235.240.0/20 --quiet 2>/dev/null || true

# Ensure Cloud NAT exists on the default network so the VM can download apache2-utils
gcloud compute routers create router-default --network default --region us-central1 || true
gcloud compute routers nats create nat-default --router router-default --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges --region us-central1 || true

gcloud compute instances create $VM_NAME \
  --zone=$ZONE \
  --machine-type=e2-micro \
    --no-address \
    --shielded-secure-boot \
  --network=$NETWORK \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --project=$PROJECT_ID || echo "VM already exists."

echo "=== 2. Instructions to generate traffic ==="
echo "The VM '$VM_NAME' has been created internally."
echo "You can now run ./06_Traffic_Simulator.sh directly from your machine."
echo "It will automatically find your Apigee IP and orchestrate the attack remotely using this VM."
