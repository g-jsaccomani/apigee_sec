#!/bin/bash
# ==============================================================================
# Script: deploy_to_gcp.sh
# Purpose: One-click build and deployment of the ASPR Agent to Google Cloud Run.
# Usage: ./deploy_to_gcp.sh [PROJECT_ID] [REGION]
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
REGION=${2:-"us-east1"}
REPO_NAME="aspr-agent-repo"
IMAGE_NAME="aspr-agent:latest"
IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}"

echo "=============================================================================="
echo "🚀 ASPR: Building & Deploying Autonomous Agent to Google Cloud Run"
echo "   Project: $PROJECT_ID | Region: $REGION"
echo "   Image:   $IMAGE_URI"
echo "=============================================================================="

# 1. Enable Cloud Build and Artifact Registry
echo "1. Enabling Cloud Build and Artifact Registry APIs..."
gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com --project="$PROJECT_ID"

# 2. Create Artifact Registry Repository if not exists
echo "2. Ensuring Artifact Registry repository exists..."
gcloud artifacts repositories create "$REPO_NAME" \
  --repository-format=docker \
  --location="$REGION" \
  --description="ASPR Agent Container Repository" \
  --project="$PROJECT_ID" 2>/dev/null || echo "Repository '$REPO_NAME' already exists."

# 3. Build Container Image via Cloud Build
echo "3. Submenterpriseng Cloud Build job to build container..."
cd "/Users/jsaccomani/Documents/Jetsky/My Projects/apigee_sec"
gcloud builds submit --tag "$IMAGE_URI" --project="$PROJECT_ID"

# 4. Deploy Container to Cloud Run
echo "4. Deploying ASPR Agent to Google Cloud Run..."
gcloud run deploy aspr-security-agent \
  --image="$IMAGE_URI" \
  --platform=managed \
  --region="$REGION" \
  --allow-unauthenticated \
  --set-env-vars="APIGEE_PROJECT_ID=$PROJECT_ID,DEFAULT_WAF_POLICY_NAME=apigee-waap-policy" \
  --project="$PROJECT_ID"

SERVICE_URL=$(gcloud run services describe aspr-security-agent --platform=managed --region="$REGION" --format="value(status.url)" --project="$PROJECT_ID")

echo "=============================================================================="
echo "✅ ASPR Agent Service Successfully Deployed!"
echo "🌐 Service Endpoint URL: $SERVICE_URL"
echo "=============================================================================="
