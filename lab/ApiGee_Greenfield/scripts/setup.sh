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

set -e

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi

PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
NETWORK_NAME="apigee-custom-vpc"
SUBNET_NAME="apigee-custom-subnet"
CLUSTER_NAME="apigee-autopilot-cluster"
REPO_NAME="vulnerable-backend-repo"
IMAGE_NAME="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/vulnerable-backend:v1"

echo "=== Configurando VPC e Sub-rede ==="
# Cria a VPC
gcloud compute networks create ${NETWORK_NAME} --subnet-mode=custom || echo "VPC já existe"

# Cria a Sub-rede
gcloud compute networks subnets create ${SUBNET_NAME} \
    --network=${NETWORK_NAME} \
    --range=10.0.0.0/24 \
    --region=${REGION} || echo "Sub-rede já existe"

echo "=== Criando Cluster GKE Autopilot ==="
gcloud container clusters create-auto ${CLUSTER_NAME} \
    --region=${REGION} \
    --network=${NETWORK_NAME} \
    --subnetwork=${SUBNET_NAME} \
    --project=${PROJECT_ID} || echo "Cluster já existe ou em criação"

echo "=== Autenticando Docker e Criando Repositório ==="
gcloud services enable container.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com
gcloud artifacts repositories create ${REPO_NAME} \
    --repository-format=docker \
    --location=${REGION} \
    --description="Docker repository for vulnerable backend" || echo "Repositório já existe"

echo "=== Construindo e Enviando a Imagem Docker ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR/../app"
gcloud builds submit --tag ${IMAGE_NAME} .
cd "$SCRIPT_DIR"

echo "=== Obtendo Credenciais do Cluster ==="
gcloud container clusters get-credentials ${CLUSTER_NAME} --region=${REGION} --project=${PROJECT_ID} || true

echo "=== Aplicando Deployment no GKE ==="
# Substituir a imagem no deployment.yaml e aplicar
sed -e "s|\${IMAGE_NAME}|${IMAGE_NAME}|g" "$SCRIPT_DIR/../k8s/deployment.yaml" | kubectl apply -f -

echo "Script concluído! O backend deve estar rodando no GKE."
