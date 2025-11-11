"""
ASPR Enterprise Web Service & API Gateway.
Exposes the ASPR Agent capabilities over REST/JSON endpoints for Cloud Run deployment,
Eventarc Pub/Sub triggers, and interactive client integration.
"""

import os
import sys
import json
from typing import Dict, Any, Optional
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel

# Add script paths
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(REPO_ROOT, "agent"))
sys.path.insert(0, os.path.join(REPO_ROOT, "scripts"))

from lab_orchestration_tools import (
    check_prerequisites_and_auth,
    enable_gcp_apis,
    setup_api_hub_catalog,
    deploy_waap_perimeter_and_waf,
    activate_advanced_api_security,
    audit_api_security_health,
    tune_cloud_armor_crs,
    configure_recaptcha_bot_defense,
    configure_rate_limiting_and_ban,
    detect_perimeter_bypass,
    inject_security_action,
    hunt_shadow_and_zombie_apis,
    verify_scc_activation_and_tier,
    query_scc_findings,
    remediate_scc_finding_item,
    run_red_team_simulator,
    update_threat_intel_knowledge
)

app = FastAPI(
    title="ASPR - API Security Posture & Remediation Service",
    description="Autonomous AI Agent Service for Google Cloud Apigee, Cloud Armor WAF & SCC Integration",
    version="1.0.0"
)

class ProjectRequest(BaseModel):
    project_id: str = "apigee-boticario"
    environment: Optional[str] = "prod"

class WAAPDeployRequest(BaseModel):
    project_id: str = "apigee-boticario"
    region: str = "us-east1"
    preview_mode: bool = True

class SCCRemediateRequest(BaseModel):
    project_id: str = "apigee-boticario"
    finding_id: str
    dry_run: bool = False

class RedTeamRequest(BaseModel):
    project_id: str = "apigee-boticario"
    target_host: str = "https://api.boticario.com.br"

class ChatRequest(BaseModel):
    prompt: str
    project_id: str = "apigee-boticario"

@app.get("/")
def health_check():
    return {
        "service": "ASPR - API Security Posture & Remediation Agent",
        "status": "HEALTHY",
        "version": "1.0.0",
        "capabilities": [
            "Perimeter Bypass Audit",
            "Cloud Armor WAF Tuning (CRS 3.3)",
            "reCAPTCHA Enterprise Bot Management",
            "Apigee Advanced API Security ML",
            "Google SCC Auto-Remediation",
            "On-Demand Red Team Fuzzing",
            "In-Flight Script Engine"
        ]
    }

@app.post("/api/aspr/audit")
def run_posture_audit(req: ProjectRequest):
    return audit_api_security_health(project_id=req.project_id, env_name=req.environment or "prod")

@app.post("/api/aspr/waap/deploy")
def deploy_waap(req: WAAPDeployRequest):
    return deploy_waap_perimeter_and_waf(project_id=req.project_id, region=req.region, preview_mode=req.preview_mode)

@app.get("/api/aspr/scc/verify/{project_id}")
def verify_scc(project_id: str):
    return verify_scc_activation_and_tier(project_id=project_id)

@app.get("/api/aspr/scc/findings/{project_id}")
def list_scc_findings(project_id: str):
    return query_scc_findings(project_id=project_id)

@app.post("/api/aspr/scc/remediate")
def remediate_scc_finding(req: SCCRemediateRequest):
    return remediate_scc_finding_item(finding_id=req.finding_id, project_id=req.project_id, dry_run=req.dry_run)

@app.post("/api/aspr/redteam/run")
def run_red_team(req: RedTeamRequest):
    return run_red_team_simulator(target_host=req.target_host, project_id=req.project_id)

class ThreatModelRequest(BaseModel):
    api_name: str = "PaymentGatewayProxy"
    base_url: str = "https://api.boticario.com.br/v1/payments"
    data_classification: str = "CONFIDENCIAL / PII / PCI-DSS"
    project_id: str = "apigee-boticario"

@app.post("/api/aspr/intel/update")
def update_threat_intel():
    return update_threat_intel_knowledge()

@app.post("/api/aspr/threat-model/generate")
def generate_threat_model(req: ThreatModelRequest):
    from lab_orchestration_tools import generate_api_threat_model
    return generate_api_threat_model(api_name=req.api_name, base_url=req.base_url, data_classification=req.data_classification, project_id=req.project_id)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
