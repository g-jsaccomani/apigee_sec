#!/bin/bash
# Script para pausar ou ligar os recursos do Lab, evitando custos desnecessários
# Execução: ./manage_standby.sh [stop|start]

if ! command -v gcloud &> /dev/null; then
  if [ -f "$HOME/google-cloud-sdk/bin/gcloud" ]; then
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  fi
fi

if [ -z "$1" ] || [[ "$1" != "stop" && "$1" != "start" ]]; then
    echo "Uso incorreto."
    echo "Para pausar o ambiente: ./manage_standby.sh stop"
    echo "Para ligar o ambiente:  ./manage_standby.sh start"
    exit 1
fi

ACTION=$1
ZONE="us-central1-a"
REGION="us-central1"
VMS=("app4-java-backend" "apigee-traffic-tester")

echo "======================================================="
echo "    Iniciando ação: $ACTION nos recursos do Lab"
echo "======================================================="

# 1. Gerenciar Máquinas Virtuais
echo "-> Gerenciando Máquinas Virtuais (GCE)..."
for VM in "${VMS[@]}"; do
    if [ "$ACTION" == "stop" ]; then
        echo "🛑 Parando VM: $VM"
        gcloud compute instances stop "$VM" --zone="$ZONE" --quiet || true
    else
        echo "✅ Iniciando VM: $VM"
        gcloud compute instances start "$VM" --zone="$ZONE" --quiet || true
    fi
done

# 2. Gerenciar Cluster GKE
echo ""
echo "-> Gerenciando Workloads no GKE (cluster-app5)..."
# Busca credenciais do cluster de forma silenciosa
gcloud container clusters get-credentials cluster-app5 --region="$REGION" 2>/dev/null
if [ $? -eq 0 ]; then
    if [ "$ACTION" == "stop" ]; then
        echo "🛑 Reduzindo deployments do Kubernetes para 0 réplicas (Economia de pods)..."
        kubectl scale deployment status-api --replicas=0 2>/dev/null || true
    else
        echo "✅ Subindo deployments do Kubernetes para 1 réplica..."
        kubectl scale deployment status-api --replicas=1 2>/dev/null || true
    fi
else
    echo "⚠️ Cluster GKE 'cluster-app5' não encontrado ou não criado ainda. Pulando..."
fi

echo "======================================================="
echo "    Ação '$ACTION' concluída com sucesso."
echo "======================================================="
echo "📌 NOTAS DE CUSTO:"
echo " - Cloud Run (App03) e Cloud Functions (App01) escalam para 0 automaticamente (Zero custo parados)."
echo " - Apigee Pay-as-you-go e Cloud Load Balancing possuem um custo fixo por hora de infraestrutura básica instanciada pelo Google. A única forma de zerar *completamente* a fatura deles seria deletando o ambiente (o que destruiria o lab). Porém, pausar as VMs e o GKE reduzirá drasticamente os custos variáveis diários!"
echo "======================================================="
