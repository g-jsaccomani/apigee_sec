#!/bin/bash
# ==============================================================================
# Script: sec_07_shadow_and_zombie_api_hunter.sh
# Purpose: Ingests live traffic telemetry from Apigee Analytics & Cloud Monitoring
#          and diffs against OpenAPI specifications to detect Shadow & Zombie APIs.
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
ENV_NAME=${2:-"prod"}

echo "=============================================================================="
echo "🕵️ ASPR Security: Shadow & Zombie API Discovery Engine (OWASP API9:2023)"
echo "   Project: $PROJECT_ID | Environment: $ENV_NAME"
echo "=============================================================================="

python3 -c "
import sys
sys.path.insert(0, '/Users/jsaccomani/Documents/Jetsky/Google/pso-ace-ai/backend')
from agents.domains.apigee_security.tools.posture_tools import scan_shadow_apis
import json

findings = scan_shadow_apis(project_id='$PROJECT_ID')
print(f'Total Endpoints Scanned: {findings[\"total_endpoints_scanned\"]}')
print(f'Documented Endpoints:    {findings[\"documented_endpoints\"]}')
print('\n[!] Shadow APIs Detected (Undocumented live endpoints):')
for s in findings[\"shadow_apis_detected\"]:
    print(f'  - Path: {s[\"path\"]} | 24h Volume: {s[\"traffic_volume_24h\"]} reqs | Risk: {s[\"risk\"]}')
    print(f'    Remediation: {s[\"recommendation\"]}')

print('\n[!] Zombie APIs Detected (Obsolete/Deprecated endpoints with zero traffic):')
for z in findings[\"zombie_apis_detected\"]:
    print(f'  - Path: {z[\"path\"]} | Last Active: {z[\"last_active\"]}')
    print(f'    Remediation: {z[\"recommendation\"]}')
"
