#!/bin/bash
function _finish_report {
    local exit_code=$?
    echo -e "\n========================================="
    if [ $exit_code -eq 0 ]; then
        echo "✅ Brownfield Environment provisioned SUCCESSFULLY."
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
INSTANCE_NAME="apigee-instance"
ENV_NAME="env-brownfield"
ENV_GROUP_NAME="brownfield-envgroup"
HOSTNAME="legacy.poc-apigee.com"

TOKEN=$(gcloud auth print-access-token)

function wait_for_operation() {
    local OP_JSON=$1
    local OP_NAME=$(echo "$OP_JSON" | grep '"name":' | head -1 | awk -F'"' '{print $4}')
    if [ -z "$OP_NAME" ]; then
        return 0
    fi
    echo "Waiting for operation $OP_NAME to complete..."
    while true; do
        STATUS=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/$OP_NAME")
        if echo "$STATUS" | grep -q '"done": true'; then
            echo "Operation completed!"
            break
        fi
        sleep 5
    done
}

echo "=== 1. Checking / Creating Brownfield Environment ==="
ENV_EXISTS=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments/$ENV_NAME" | grep '"name":' || true)

if [ -z "$ENV_EXISTS" ]; then
  echo "Creating Environment '$ENV_NAME'..."
  OP_ENV=$(curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "'"$ENV_NAME"'"
    }')
  wait_for_operation "$OP_ENV"
else
  echo "Environment '$ENV_NAME' already exists."
fi

echo "=== 2. Attaching Environment to Instance ==="
ATTACHMENTS=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/instances/$INSTANCE_NAME/attachments")
if echo "$ATTACHMENTS" | grep -q "$ENV_NAME"; then
  echo "Environment '$ENV_NAME' already attached to instance '$INSTANCE_NAME'."
else
  echo "Attaching '$ENV_NAME' to instance '$INSTANCE_NAME'..."
  OP_ATTACH=$(curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/instances/$INSTANCE_NAME/attachments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "environment": "'"$ENV_NAME"'"
    }')
  wait_for_operation "$OP_ATTACH"
fi

echo "=== 3. Checking / Creating Environment Group ==="
ENVGROUP_EXISTS=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/envgroups/$ENV_GROUP_NAME" | grep '"name":' || true)

if [ -z "$ENVGROUP_EXISTS" ]; then
  echo "Creating Environment Group '$ENV_GROUP_NAME' with hostname '$HOSTNAME'..."
  OP_GRP=$(curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/envgroups" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "'"$ENV_GROUP_NAME"'",
      "hostnames": ["'"$HOSTNAME"'"]
    }')
  wait_for_operation "$OP_GRP"
else
  echo "Environment Group '$ENV_GROUP_NAME' already exists."
fi

echo "=== 4. Attaching Environment to Group ==="
GROUP_ATTACHMENTS=$(curl -s -H "Authorization: Bearer $TOKEN" "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/envgroups/$ENV_GROUP_NAME/attachments")
if echo "$GROUP_ATTACHMENTS" | grep -q "$ENV_NAME"; then
  echo "Environment '$ENV_NAME' already attached to group '$ENV_GROUP_NAME'."
else
  echo "Attaching '$ENV_NAME' to group '$ENV_GROUP_NAME'..."
  OP_GRP_ATTACH=$(curl -s -X POST "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/envgroups/$ENV_GROUP_NAME/attachments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "environment": "'"$ENV_NAME"'"
    }')
  wait_for_operation "$OP_GRP_ATTACH"
fi

echo "========================================================================="
echo "Legacy Environment Provisioned!"
echo "Apigee typically takes 2-5 minutes to propagate new Environments and Groups."
echo "========================================================================="
