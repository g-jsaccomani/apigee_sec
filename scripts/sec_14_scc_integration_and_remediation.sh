#!/bin/bash
# ==============================================================================
# Script: sec_14_scc_integration_and_remediation.sh
# Purpose: Shell wrapper for SCC API finding ingestion and auto-remediation.
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}

echo "=============================================================================="
echo "🛡️ ASPR Security: Google Security Command Center (SCC) Integration"
echo "   Project: $PROJECT_ID | Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "=============================================================================="

python3 "/Users/jsaccomani/Documents/Jetsky/My Projects/apigee_sec/scripts/sec_14_scc_integration_and_remediation.py" "$PROJECT_ID"
