#!/bin/bash
TOKEN=$(gcloud auth print-access-token)
PROJECT_ID=$(gcloud config get-value project)
INSTANCE_NAME="apigee-instance"
ENV_NAME="env-brownfield"
OPERATION_ID="1209890a-6a68-45a6-a145-458c1ece6d47"

echo "Waiting for environment creation to finish..."
while true; do
  STATUS=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/operations/$OPERATION_ID" | grep '"done":' || true)
  if echo "$STATUS" | grep -q "true"; then
    echo "Operation finished!"
    break
  fi
  echo "Still waiting..."
  sleep 5
done

echo "Attaching '$ENV_NAME' to instance '$INSTANCE_NAME'..."
curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/instances/$INSTANCE_NAME/attachments" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "environment": "'"$ENV_NAME"'"
  }'
