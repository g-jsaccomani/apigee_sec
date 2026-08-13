#!/bin/bash
# ==============================================================================
# Script: sec_13_api_red_team_simulator.sh
# Purpose: Shell wrapper to execute ASPR Autonomous Red Teaming and Fuzzing suite.
# ==============================================================================
set -e

TARGET_HOST=${1:-"https://api.boticario.com.br"}
PROJECT_ID=${2:-$(gcloud config get-value project 2>/dev/null || echo "apigee-boticario")}

echo "=============================================================================="
echo "🎯 ASPR Security: Executing Autonomous Red Teaming & Fuzzing Suite"
echo "   Target Host: $TARGET_HOST | Project: $PROJECT_ID"
echo "=============================================================================="

python3 "/Users/jsaccomani/Documents/Jetsky/My Projects/apigee_sec/scripts/sec_13_api_red_team_simulator.py" "$TARGET_HOST" "$PROJECT_ID"
