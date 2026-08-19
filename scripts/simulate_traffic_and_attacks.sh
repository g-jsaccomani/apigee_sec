#!/bin/bash
# ==============================================================================
# Script: simulate_traffic_and_attacks.sh
# Objective: Generate normal and anomalous attack traffic against Apigee proxies.
# Usage: ./simulate_traffic_and_attacks.sh [TARGET_ENV: greenfield|brownfield]
# ==============================================================================
set -e
TARGET_ENV=${1:-"greenfield"}

echo "=============================================================================="
echo "⚡ ASPR: Starting Traffic & Security Attack Simulation ($TARGET_ENV)"
echo "=============================================================================="

if [ "$TARGET_ENV" == "brownfield" ]; then
  bash "/Users/jsaccomani/Documents/Jetsky/My Projects/apigee_sec/lab/ApiGee_Brownfield/scripts/04_Traffic_Simulator.sh"
else
  bash "/Users/jsaccomani/Documents/Jetsky/My Projects/apigee_sec/lab/ApiGee_Greenfield/scripts/06_Traffic_Simulator.sh"
fi
