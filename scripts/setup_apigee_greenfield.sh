#!/bin/bash
# ==============================================================================
# Script: setup_apigee_greenfield.sh
# Objective: Execute Greenfield lab setup steps.
# Usage: ./setup_apigee_greenfield.sh [STEP_NUMBER]
# ==============================================================================
set -e
STEP=${1:-"all"}
SCRIPTS_DIR="/Users/jsaccomani/Documents/Jetsky/My Projects/apigee_sec/lab/ApiGee_Greenfield/scripts"

echo "=============================================================================="
echo "🟢 ASPR: Greenfield Lab Execution (Step: $STEP)"
echo "=============================================================================="

if [ "$STEP" == "all" ]; then
  echo "Executing complete Greenfield pipeline..."
  bash "$SCRIPTS_DIR/00_Init_Connection.sh" || true
  bash "$SCRIPTS_DIR/01_Setup_Apigee_Env.sh" || true
  bash "$SCRIPTS_DIR/02_Setup_API_Hub.sh" || true
  bash "$SCRIPTS_DIR/03_Setup_Apigee_Runtime.sh" || true
  bash "$SCRIPTS_DIR/04_Setup_APIs.sh" || true
  bash "$SCRIPTS_DIR/08_Enable_Advanced_Security_ML.sh" || true
  bash "$SCRIPTS_DIR/09_Deploy_External_LB_and_WAF.sh" || true
else
  case "$STEP" in
    0) bash "$SCRIPTS_DIR/00_Init_Connection.sh" ;;
    1) bash "$SCRIPTS_DIR/01_Setup_Apigee_Env.sh" ;;
    2) bash "$SCRIPTS_DIR/02_Setup_API_Hub.sh" ;;
    3) bash "$SCRIPTS_DIR/03_Setup_Apigee_Runtime.sh" ;;
    4) bash "$SCRIPTS_DIR/04_Setup_APIs.sh" ;;
    5) bash "$SCRIPTS_DIR/05_Create_Test_VM.sh" ;;
    6) bash "$SCRIPTS_DIR/06_Traffic_Simulator.sh" ;;
    7) bash "$SCRIPTS_DIR/07_Stop_Traffic_Simulator.sh" ;;
    8) bash "$SCRIPTS_DIR/08_Enable_Advanced_Security_ML.sh" ;;
    9) bash "$SCRIPTS_DIR/09_Deploy_External_LB_and_WAF.sh" ;;
    *) echo "Unknown step $STEP. Use 0-9 or 'all'." ;;
  esac
fi
