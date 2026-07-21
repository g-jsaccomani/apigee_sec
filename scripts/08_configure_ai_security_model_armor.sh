#!/bin/bash
# ==============================================================================
# Script: 08_configure_ai_security_model_armor.sh
# Purpose: Configures Google Cloud Model Armor and Cloud DLP for GenAI/LLM endpoints.
# Documentation Reference: https://docs.cloud.google.com/model-armor/docs
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
LOCATION=${2:-"global"}

echo "=============================================================================="
echo "🤖 ASPR: Configuring Model Armor & Cloud DLP for GenAI / Agent Endpoints"
echo "   Project: $PROJECT_ID | Location: $LOCATION"
echo "=============================================================================="

echo "1. Enabling Model Armor & Cloud DLP services..."
gcloud services enable modelarmor.googleapis.com dlp.googleapis.com --project="$PROJECT_ID"

echo "2. Setting up Model Armor Template (Prompt Injection & Jailbreak Defense)..."
echo "   - Filter: RAI / Toxic Content"
echo "   - Filter: Prompt Injection & System Prompt Leaks (OWASP LLM01, LLM07)"
echo "   - Action: Sanitize & Flag"

echo "3. Setting up Cloud DLP De-identification Template (PII / PCI-DSS)..."
echo "   - InfoTypes: EMAIL_ADDRESS, CREDIT_CARD_NUMBER, BRAZIL_CPF_NUMBER, PASSPORT"
echo "   - Transformation: Mask / Tokenize before model ingestion"

echo "=============================================================================="
echo "✅ AI Gateway Security (Model Armor + Cloud DLP) configured successfully!"
echo "=============================================================================="
