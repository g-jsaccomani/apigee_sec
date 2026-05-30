"""
ASPR Comprehensive Script Orchestration & In-Flight Synthesis Suite.
Maps Agent Tool Invocations to built-in security scripts, Red Teaming Simulator,
Security Command Center (SCC) Tier Verification, and dynamic in-flight synthesis engine.
"""

import os
import subprocess
import json
from typing import Dict, Any, List, Optional
from datetime import datetime

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../"))
SCRIPTS_DIR = os.path.join(REPO_ROOT, "scripts")

# Import in-flight script engine
import sys
sys.path.insert(0, SCRIPTS_DIR)
from in_flight_script_engine import (
    synthesize_and_save_in_flight_script,
    execute_in_flight_script,
    list_all_security_scripts
)

# Import Red Team & SCC modules
from sec_13_api_red_team_simulator import run_adversarial_red_team_suite
from sec_14_scc_integration_and_remediation import (
    check_scc_tier_and_activation,
    fetch_scc_security_findings,
    auto_remediate_scc_finding,
    run_scc_audit_and_auto_remediation_pipeline
)
from sec_15_generate_api_threat_model import generate_threat_model_report

def _execute_production_script(script_name: str, args: Optional[List[str]] = None, dry_run: bool = False) -> Dict[str, Any]:
    """Helper to safely execute or dry-run a modular script in scripts/."""
    script_path = os.path.join(SCRIPTS_DIR, script_name)
    if not os.path.exists(script_path):
        return {
            "status": "ERROR",
            "message": f"Script not found at: {script_path}",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
    
    cmd = ["bash", script_path] + (args or []) if script_name.endswith(".sh") else ["python3", script_path] + (args or [])
    cmd_str = " ".join(cmd)
    
    if dry_run:
        return {
            "status": "DRY_RUN",
            "script": script_name,
            "command": cmd_str,
            "message": "Pre-flight validation passed. Ready to execute.",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        
    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=300
        )
        return {
            "status": "SUCCESS" if result.returncode == 0 else "FAILED",
            "returncode": result.returncode,
            "script": script_name,
            "stdout": result.stdout[-3000:] if len(result.stdout) > 3000 else result.stdout,
            "stderr": result.stderr[-1000:] if len(result.stderr) > 1000 else result.stderr,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
    except Exception as e:
        return {
            "status": "EXCEPTION",
            "script": script_name,
            "error": str(e),
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }

# --- Core Security Scripts (01 to 09) ---
def check_prerequisites_and_auth(project_id: str = "apigee-boticario", dry_run: bool = False) -> Dict[str, Any]:
    return _execute_production_script("01_check_prerequisites_and_auth.sh", [project_id], dry_run=dry_run)

def enable_gcp_apis(project_id: str = "apigee-boticario", dry_run: bool = False) -> Dict[str, Any]:
    return _execute_production_script("02_enable_gcp_apis.sh", [project_id], dry_run=dry_run)

def setup_api_hub_catalog(project_id: str = "apigee-boticario", location: str = "us-central1", dry_run: bool = False) -> Dict[str, Any]:
    return _execute_production_script("04_setup_api_hub_catalog.sh", [project_id, location], dry_run=dry_run)

def deploy_waap_perimeter_and_waf(project_id: str = "apigee-boticario", region: str = "us-east1", preview_mode: bool = True, dry_run: bool = False) -> Dict[str, Any]:
    preview_str = "true" if preview_mode else "false"
    return _execute_production_script("05_deploy_waap_perimeter_and_waf.sh", [project_id, region, preview_str], dry_run=dry_run)

def activate_advanced_api_security(project_id: str = "apigee-boticario", env_name: str = "prod", dry_run: bool = False) -> Dict[str, Any]:
    return _execute_production_script("06_activate_advanced_api_security_ml.sh", [project_id, env_name], dry_run=dry_run)

def audit_api_security_health(project_id: str = "apigee-boticario", env_name: str = "prod", format_type: str = "markdown", dry_run: bool = False) -> Dict[str, Any]:
    return _execute_production_script("09_audit_api_security_health.sh", [project_id, env_name, format_type], dry_run=dry_run)

# --- Deep Specialized Security Tools ---
def tune_cloud_armor_crs(project_id: str = "apigee-boticario", policy_name: str = "apigee-waap-policy", paranoia_level: int = 1, preview_mode: bool = True) -> Dict[str, Any]:
    preview_str = "true" if preview_mode else "false"
    return _execute_production_script("sec_01_cloud_armor_crs_tuning.sh", [project_id, policy_name, str(paranoia_level), preview_str])

def configure_recaptcha_bot_defense(project_id: str = "apigee-boticario", key_name: str = "waap-recaptcha-key") -> Dict[str, Any]:
    return _execute_production_script("sec_02_recaptcha_enterprise_bot_defense.sh", [project_id, key_name])

def configure_rate_limiting_and_ban(project_id: str = "apigee-boticario", policy_name: str = "apigee-waap-policy", rate_threshold: int = 100, ban_duration: int = 600) -> Dict[str, Any]:
    return _execute_production_script("sec_03_rate_limiting_and_ban_policies.sh", [project_id, policy_name, str(rate_threshold), str(ban_duration)])

def detect_perimeter_bypass(project_id: str = "apigee-boticario") -> Dict[str, Any]:
    return _execute_production_script("sec_04_perimeter_bypass_detector.sh", [project_id])

def inject_security_action(project_id: str = "apigee-boticario", env_name: str = "prod", action_type: str = "RATE_LIMIT", target: str = "*", enforce_mode: str = "FLAG") -> Dict[str, Any]:
    return _execute_production_script("sec_06_inject_security_actions.sh", [project_id, env_name, action_type, target, enforce_mode])

def hunt_shadow_and_zombie_apis(project_id: str = "apigee-boticario", env_name: str = "prod") -> Dict[str, Any]:
    return _execute_production_script("sec_07_shadow_and_zombie_api_hunter.sh", [project_id, env_name])

def setup_southbound_mtls_keystores(project_id: str = "apigee-boticario", env_name: str = "prod") -> Dict[str, Any]:
    return _execute_production_script("sec_08_setup_southbound_mtls.sh", [project_id, env_name])

# --- Red Team Tool (On-Demand) ---
def run_red_team_simulator(target_host: str = "https://api.boticario.com.br", project_id: str = "apigee-boticario") -> Dict[str, Any]:
    """On-demand Red Team fuzzing suite returning the Defense Efficacy Certificate."""
    return run_adversarial_red_team_suite(target_host=target_host, project_id=project_id)

# --- SCC Verification & Remediation Tools ---
def verify_scc_activation_and_tier(project_id: str = "apigee-boticario") -> Dict[str, Any]:
    """Verifies if Google Security Command Center (SCC) is active and which Tier is provisioned (Premium/Enterprise required)."""
    return check_scc_tier_and_activation(project_id=project_id)

def query_scc_findings(project_id: str = "apigee-boticario") -> Dict[str, Any]:
    """Queries active API security findings from Google Security Command Center."""
    return run_scc_audit_and_auto_remediation_pipeline(project_id=project_id, auto_remediate=False)

def remediate_scc_finding_item(finding_id: str, project_id: str = "apigee-boticario", dry_run: bool = False) -> Dict[str, Any]:
    """Executes automated remediation playbook for a specific SCC finding."""
    return auto_remediate_scc_finding(finding_id=finding_id, project_id=project_id, dry_run=dry_run)

# --- In-Flight Synthesis & Threat Intel Tools ---
def synthesize_custom_in_flight_script(script_name: str, script_code: str, description: str = "Custom in-flight security script") -> Dict[str, Any]:
    return synthesize_and_save_in_flight_script(script_name=script_name, script_content=script_code, description=description)

def execute_custom_in_flight_script(script_name: str, args: Optional[List[str]] = None, dry_run: bool = False) -> Dict[str, Any]:
    return execute_in_flight_script(script_name=script_name, args=args, dry_run=dry_run)

def list_security_scripts_inventory() -> Dict[str, Any]:
    return list_all_security_scripts()

def update_threat_intel_knowledge() -> Dict[str, Any]:
    return _execute_production_script("update_security_knowledge_sources.py", [])

def generate_api_threat_model(api_name: str = "PaymentGatewayProxy", base_url: str = "https://api.boticario.com.br/v1/payments", data_classification: str = "CONFIDENCIAL / PII / PCI-DSS", project_id: str = "apigee-boticario") -> Dict[str, Any]:
    """Generates a structured STRIDE & OWASP API Top 10 Threat Model for a target API."""
    return generate_threat_model_report(api_name=api_name, base_url=base_url, data_classification=data_classification, project_id=project_id)
