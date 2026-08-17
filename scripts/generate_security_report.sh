#!/bin/bash
# ==============================================================================
# Script: generate_security_report.sh
# Objective: Generate an API Health and Security Posture Review Report.
# Usage: ./generate_security_report.sh [PROJECT_ID] [ENV_NAME] [OUTPUT_FORMAT]
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}
ENV_NAME=${2:-"prod"}
FORMAT=${3:-"markdown"}

echo "=============================================================================="
echo "📊 ASPR: Generating API Security Posture Report"
echo "   Project:     $PROJECT_ID"
echo "   Environment: $ENV_NAME"
echo "   Timestamp:   $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "=============================================================================="

# Call python backend or posture tools to generate deterministic metrics
python3 -c "
import sys
sys.path.insert(0, '/Users/jsaccomani/Documents/Jetsky/Google/pso-ace-ai/backend')
from agents.domains.apigee_security.tools.report_tools import generate_api_health_report
import json

report = generate_api_health_report(
    organization='$PROJECT_ID',
    environment='$ENV_NAME',
    include_owasp_audit=True,
    has_cloud_armor_waf=True,
    has_direct_bypass=False,
    has_recaptcha_enterprise=True
)

if '$FORMAT' == 'json':
    print(json.dumps(report, indent=2))
else:
    print('## API Health & Security Posture Summary')
    print(f'- **Health Score:** {report[\"posture_summary\"][\"overall_health_score\"]} / 100 ({report[\"posture_summary\"][\"security_posture_status\"]})')
    print(f'- **Total Proxies:** {report[\"posture_summary\"][\"total_api_proxies\"]}')
    print(f'- **Active Endpoints:** {report[\"posture_summary\"][\"active_endpoints\"]}')
    print(f'- **Shadow APIs Detected:** {report[\"posture_summary\"][\"shadow_endpoints\"]}')
    print('\n### WAAP Perimeter Status:')
    print(f'- Cloud Armor: {report[\"waap_perimeter_health\"][\"cloud_armor_attached\"]}')
    print(f'- Direct Bypass: {report[\"waap_perimeter_health\"][\"direct_bypass_detected\"]}')
    print(f'- Adaptive Protection ML: {report[\"waap_perimeter_health\"][\"adaptive_protection_ml_l7\"]}')
    print(f'- reCAPTCHA Enterprise: {report[\"waap_perimeter_health\"][\"recaptcha_enterprise_integrated\"]}')
    print('\n### Actionable Remediation Steps:')
    for item in report[\"actionable_remediation_plan\"]:
        print(f'- [{item[\"priority\"]}] {item[\"action\"]} ({item[\"execution_mode\"]})')
"
