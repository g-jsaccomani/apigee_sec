#!/bin/bash
# ==============================================================================
# Script: audit_openapi_specs.sh
# Objective: Audit an OpenAPI specification file against OWASP API Top 10 rules.
# Usage: ./audit_openapi_specs.sh [SPEC_PATH] [FORMAT]
# ==============================================================================
set -e

SPEC_PATH=${1:-"lab/ApiGee_Greenfield/specs/openapi-v1.yaml"}
FORMAT=${2:-"text"}
REPO_ROOT="/Users/jsaccomani/Documents/Jetsky/My Projects/apigee_sec"

if [ ! -f "$SPEC_PATH" ] && [ -f "$REPO_ROOT/$SPEC_PATH" ]; then
  SPEC_PATH="$REPO_ROOT/$SPEC_PATH"
fi

echo "=============================================================================="
echo "🔍 ASPR: Auditing OpenAPI Specification"
echo "   File:   $SPEC_PATH"
echo "   Format: $FORMAT"
echo "=============================================================================="

python3 "$REPO_ROOT/audit/audit_openapi.py" --spec "$SPEC_PATH" --format "$FORMAT"
