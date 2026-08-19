#!/bin/bash
# ==============================================================================
# Script: setup_apigee_brownfield.sh
# Objective: Execute Brownfield legacy / vulnerable environment setup steps.
# Usage: ./setup_apigee_brownfield.sh [STEP_NUMBER]
# ==============================================================================
set -e
STEP=${1:-"all"}
SCRIPTS_DIR="/Users/jsaccomani/Documents/Jetsky/My Projects/apigee_sec/lab/ApiGee_Brownfield/scripts"

echo "=============================================================================="
echo "🟤 ASPR: Brownfield Lab Execution (Step: $STEP)"
echo "=============================================================================="

if [ "$STEP" == "all" ]; then
  echo "Executing complete Brownfield pipeline..."
  bash "$SCRIPTS_DIR/01_Setup_Legacy_Env.sh" || true
  bash "$SCRIPTS_DIR/02_Create_Legacy_Apps.sh" || true
  bash "$SCRIPTS_DIR/03_Deploy_Legacy_APIs.sh" || true
  bash "$SCRIPTS_DIR/05_Activate_Advanced_Security.sh" || true
  bash "$SCRIPTS_DIR/06_Enable_Advanced_Security_ML.sh" || true
  bash "$SCRIPTS_DIR/07_Generate_Security_Report.sh" || true
else
  case "$STEP" in
    1) bash "$SCRIPTS_DIR/01_Setup_Legacy_Env.sh" ;;
    2) bash "$SCRIPTS_DIR/02_Create_Legacy_Apps.sh" ;;
    3) bash "$SCRIPTS_DIR/03_Deploy_Legacy_APIs.sh" ;;
    4) bash "$SCRIPTS_DIR/04_Traffic_Simulator.sh" ;;
    5) bash "$SCRIPTS_DIR/05_Activate_Advanced_Security.sh" ;;
    6) bash "$SCRIPTS_DIR/06_Enable_Advanced_Security_ML.sh" ;;
    7) bash "$SCRIPTS_DIR/07_Generate_Security_Report.sh" ;;
    *) echo "Unknown step $STEP. Use 1-7 or 'all'." ;;
  esac
fi
