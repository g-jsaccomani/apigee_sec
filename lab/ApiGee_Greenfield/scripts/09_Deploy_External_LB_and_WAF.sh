#!/bin/bash
set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi

PROJECT_ID=$(gcloud config get-value project)
REGION="us-east1"
TOKEN=$(gcloud auth print-access-token)

echo "========================================="
echo "🛡️ Deploying Cloud Armor & Load Balancer"
echo "   (Focus: Visibility and Preview Mode) "
echo "========================================="

echo "1. Fetching Apigee PSC Service Attachment..."
ATTACHMENT=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/instances" | grep '"serviceAttachment":' | head -1 | awk -F'"' '{print $4}')
if [ -z "$ATTACHMENT" ]; then
  echo "❌ Error: Could not find Apigee Service Attachment."
  exit 1
fi
echo "Found: $ATTACHMENT"

echo "2. Creating Private Service Connect NEG..."
gcloud compute network-endpoint-groups create apigee-neg \
    --network-endpoint-type=private-service-connect \
    --psc-target-service=$ATTACHMENT \
    --region=$REGION \
    --project=$PROJECT_ID || echo "NEG already exists."

echo "3. Creating Cloud Armor Security Policy (PREVIEW MODE)..."
gcloud compute security-policies create apigee-waf-policy \
    --description="WAF Policy for Apigee Greenfield (Log Only)" \
    --project=$PROJECT_ID || echo "Policy already exists."

# Add OWASP rules in PREVIEW mode so we only log, not block
gcloud compute security-policies rules create 1000 \
    --security-policy=apigee-waf-policy \
    --expression="evaluatePreconfiguredExpr('sqli-v33-stable')" \
    --action=deny-403 \
    --preview \
    --project=$PROJECT_ID || echo "Rule 1000 already exists."

gcloud compute security-policies rules create 2000 \
    --security-policy=apigee-waf-policy \
    --expression="evaluatePreconfiguredExpr('xss-v33-stable')" \
    --action=deny-403 \
    --preview \
    --project=$PROJECT_ID || echo "Rule 2000 already exists."

echo "4. Creating Backend Service and attaching NEG & WAF..."
gcloud compute backend-services create apigee-backend \
    --load-balancing-scheme=EXTERNAL_MANAGED \
    --protocol=HTTPS \
    --global \
    --project=$PROJECT_ID || echo "Backend service already exists."

gcloud compute backend-services add-backend apigee-backend \
    --network-endpoint-group=apigee-neg \
    --network-endpoint-group-region=$REGION \
    --global \
    --project=$PROJECT_ID || echo "Backend already added."

gcloud compute backend-services update apigee-backend \
    --security-policy=apigee-waf-policy \
    --global \
    --project=$PROJECT_ID || echo "WAF Policy already attached."

echo "5. Creating URL Map and Target Proxy..."
gcloud compute url-maps create apigee-lb \
    --default-service=apigee-backend \
    --global \
    --project=$PROJECT_ID || echo "URL Map already exists."

# Note: For HTTPs, we need an SSL certificate. Using HTTP Target Proxy for POC speed.
gcloud compute target-http-proxies create apigee-http-proxy \
    --url-map=apigee-lb \
    --project=$PROJECT_ID || echo "Target Proxy already exists."

echo "6. Creating Global Forwarding Rule (Public IP)..."
gcloud compute forwarding-rules create apigee-public-ip \
    --load-balancing-scheme=EXTERNAL_MANAGED \
    --network-tier=PREMIUM \
    --global \
    --target-http-proxy=apigee-http-proxy \
    --ports=80 \
    --project=$PROJECT_ID || echo "Forwarding Rule already exists."

PUBLIC_IP=$(gcloud compute forwarding-rules describe apigee-public-ip --global --format="value(IPAddress)")

echo "========================================="
echo "✅ Infrastructure Provisioned!"
echo "Apigee is now exposed via External Load Balancer: http://$PUBLIC_IP"
echo "Cloud Armor is attached in PREVIEW mode. It will analyze traffic and generate telemetry, but will NOT block anything."
echo "========================================="
