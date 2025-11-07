# Operational Instructions - ASPR (API Security Posture & Remediation)

## Repository Core Purpose
This repository (`apigee_sec`) is the single source of truth for **ASPR (API Security Posture & Remediation Super Agent)**.
ASPR is an enterprise-grade autonomous AI security agent built on Google GenAI / Gemini for Apigee X/Hybrid, Google Cloud Armor WAF, reCAPTCHA Enterprise, Google Cloud Model Armor, and Google Security Command Center (SCC).

## Architecture Preferences & Engineering Standards
1. **Core Agent Code Location**: The production ASPR Agent code resides in `agent/` (`aspr_agent.py`, `system_prompt.md`, `lab_orchestration_tools.py`).
2. **Production Scripts Location**: All built-in security automation scripts reside in `scripts/` (numbered `01_` through `09_` and `sec_*`).
3. **In-Flight Script Engine**: Dynamically synthesized scripts must be generated via `in_flight_script_engine.py` and saved exclusively in `scripts/custom/`.
4. **Cloud Run Deployment**: The Serverless Cloud Run service and REST API Gateway reside in `deploy/` (`app.py`, `Dockerfile`, `deploy_to_gcp.sh`, `terraform/main.tf`).
5. **Static Contract Auditing**: OpenAPI 3.0/3.1 static contract rule checks reside in `audit/` (`audit_openapi.py`, `rules.py`).
6. **Reference Hands-on Labs**: Testbed Greenfield and Brownfield environments reside in `lab/` (`ApiGee_Greenfield/`, `ApiGee_Brownfield/`).

## Mandatory Security Guardrails
- **72-Hour Monitor Baseline Rule**: Any newly injected WAF blocking rule (`deny-403`), rate limit, or security action MUST initially be provisioned in `PREVIEW = true` or `FLAG` mode for a minimum of 72 hours before promotion to `DENY`.
- **12-Week ML Abuse Baseline**: ML-driven anomaly models require 12 weeks of continuous telemetry ingestion.
- **Zero Information Leakage**: Error handlers must NEVER expose raw backend 500 stack traces; mandate global FaultRules with `AssignMessage`.
- **Zero Hardcoded Secrets**: Never hardcode API keys, service account credentials, or OAuth tokens in source code or scripts.
- **SCC Tier Verification**: Always verify that `securitycenter.googleapis.com` is enabled and that the provisioned tier is Premium or Enterprise before querying SCC findings.

## Testing & Validation
- Validate Python syntax with `python3 -m py_compile` before commenterpriseng changes.
- Ensure scripts in `scripts/` are executable (`chmod +x`).
