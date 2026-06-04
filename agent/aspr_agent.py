import os
import sys
import json
from google import genai
from google.genai import types

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
    setup_southbound_mtls_keystores,
    verify_scc_activation_and_tier,
    query_scc_findings,
    remediate_scc_finding_item,
    run_red_team_simulator,
    synthesize_custom_in_flight_script,
    execute_custom_in_flight_script,
    list_security_scripts_inventory,
    update_threat_intel_knowledge
)

# --- Tool Wrappers for Agent Calling ---

def check_environment_and_iam_tool(project_id: str = "apigee-boticario") -> str:
    """Checks gcloud authentication, active project configuration, and required IAM roles."""
    return json.dumps(check_prerequisites_and_auth(project_id=project_id))

def enable_apis_tool(project_id: str = "apigee-boticario") -> str:
    """Enables required GCP security APIs."""
    return json.dumps(enable_gcp_apis(project_id=project_id))

def activate_api_hub_tool(project_id: str = "apigee-boticario", location: str = "us-central1") -> str:
    """Provisions GCP API Hub instance and registers host project."""
    return json.dumps(setup_api_hub_catalog(project_id=project_id, location=location))

def deploy_waap_waf_tool(project_id: str = "apigee-boticario", region: str = "us-east1", preview_mode: bool = True) -> str:
    """Deploys External HTTPS LB with Cloud Armor WAF in PREVIEW mode."""
    return json.dumps(deploy_waap_perimeter_and_waf(project_id=project_id, region=region, preview_mode=preview_mode))

def activate_advanced_security_tool(project_id: str = "apigee-boticario", env_name: str = "prod") -> str:
    """Activates Apigee Advanced API Security add-on and enables ML abuse detection."""
    return json.dumps(activate_advanced_api_security(project_id=project_id, env_name=env_name))

def audit_security_health_tool(project_id: str = "apigee-boticario", env_name: str = "prod") -> str:
    """Audits API security posture, checks perimeter bypass (-35pt penalty), and outputs Health Score report."""
    return json.dumps(audit_api_security_health(project_id=project_id, env_name=env_name))

def tune_cloud_armor_crs_tool(project_id: str = "apigee-boticario", policy_name: str = "apigee-waap-policy", paranoia_level: int = 1, preview_mode: bool = True) -> str:
    """Tunes SQLi Paranoia Levels 1-4, XSS, RCE, LFI, and Protocol attacks in Cloud Armor."""
    return json.dumps(tune_cloud_armor_crs(project_id=project_id, policy_name=policy_name, paranoia_level=paranoia_level, preview_mode=preview_mode))

def configure_recaptcha_bot_defense_tool(project_id: str = "apigee-boticario", key_name: str = "waap-recaptcha-key") -> str:
    """Configures reCAPTCHA Enterprise bot mitigation & credential stuffing defense."""
    return json.dumps(configure_recaptcha_bot_defense(project_id=project_id, key_name=key_name))

def configure_rate_limiting_and_ban_tool(project_id: str = "apigee-boticario", policy_name: str = "apigee-waap-policy", rate_threshold: int = 100, ban_duration: int = 600) -> str:
    """Configures advanced Rate-based ban and IP throttling in Cloud Armor."""
    return json.dumps(configure_rate_limiting_and_ban(project_id=project_id, policy_name=policy_name, rate_threshold=rate_threshold, ban_duration=ban_duration))

def detect_perimeter_bypass_tool(project_id: str = "apigee-boticario") -> str:
    """Audits whether Apigee is directly exposed to the internet bypassing Cloud Armor."""
    return json.dumps(detect_perimeter_bypass(project_id=project_id))

def inject_security_action_tool(project_id: str = "apigee-boticario", env_name: str = "prod", action_type: str = "RATE_LIMIT", target: str = "*", enforce_mode: str = "FLAG") -> str:
    """Injects real-time Apigee Security Actions in FLAG (72h monitor) or DENY mode."""
    return json.dumps(inject_security_action(project_id=project_id, env_name=env_name, action_type=action_type, target=target, enforce_mode=enforce_mode))

def hunt_shadow_and_zombie_apis_tool(project_id: str = "apigee-boticario", env_name: str = "prod") -> str:
    """Scans live runtime traffic against OpenAPI specs to discover Shadow and Zombie APIs."""
    return json.dumps(hunt_shadow_and_zombie_apis(project_id=project_id, env_name=env_name))

def setup_southbound_mtls_tool(project_id: str = "apigee-boticario", env_name: str = "prod") -> str:
    """Configures mutual TLS Keystores and Truststores for secure backend connectivity."""
    return json.dumps(setup_southbound_mtls_keystores(project_id=project_id, env_name=env_name))

# --- SCC Verification & Remediation Tools ---
def verify_scc_activation_tool(project_id: str = "apigee-boticario") -> str:
    """Proactively checks if Security Command Center (SCC) is enabled and verifies if the tier is Premium or Enterprise."""
    print(f"[*] ASPR Agent verifying SCC activation and tier for: {project_id}")
    return json.dumps(verify_scc_activation_and_tier(project_id=project_id))

def query_scc_findings_tool(project_id: str = "apigee-boticario") -> str:
    """Queries active API security findings from Google Security Command Center (SCC)."""
    print(f"[*] ASPR Agent querying Security Command Center for: {project_id}")
    return json.dumps(query_scc_findings(project_id=project_id))

def remediate_scc_finding_tool(finding_id: str, project_id: str = "apigee-boticario", dry_run: bool = False) -> str:
    """Executes automated remediation playbook for a specific SCC finding."""
    print(f"[*] ASPR Agent executing auto-remediation for SCC finding: {finding_id}")
    return json.dumps(remediate_scc_finding_item(finding_id=finding_id, project_id=project_id, dry_run=dry_run))

# --- On-Demand Red Team Tool ---
def run_red_team_simulation_tool(target_host: str = "https://api.boticario.com.br", project_id: str = "apigee-boticario") -> str:
    """On-demand Red Team fuzzing suite returning the Defense Efficacy Certificate."""
    print(f"[*] ASPR Agent executing on-demand Red Team Simulator against: {target_host}")
    return json.dumps(run_red_team_simulator(target_host=target_host, project_id=project_id))

# --- In-Flight Synthesis & Threat Intel Tools ---
def synthesize_custom_in_flight_script_tool(script_name: str, script_code: str, description: str = "Custom in-flight security script") -> str:
    """Synthesizes and saves a custom security script in `scripts/custom/` with guardrail validation."""
    print(f"[*] ASPR Agent synthesizing custom in-flight script: {script_name}")
    return json.dumps(synthesize_custom_in_flight_script(script_name=script_name, script_code=script_code, description=description))

def execute_custom_in_flight_script_tool(script_name: str, dry_run: bool = False) -> str:
    """Executes a custom in-flight script from `scripts/custom/`."""
    print(f"[*] ASPR Agent executing custom in-flight script: {script_name} (dry_run={dry_run})")
    return json.dumps(execute_custom_in_flight_script(script_name=script_name, dry_run=dry_run))

def list_security_scripts_inventory_tool() -> str:
    """Lists full inventory of all 28+ built-in and dynamically generated security scripts."""
    return json.dumps(list_security_scripts_inventory())

def refresh_threat_intel_tool() -> str:
    """Updates live threat intelligence feeds (CVEs, WAF signatures, and OWASP rules)."""
    return json.dumps(update_threat_intel_knowledge())

def generate_api_threat_model_tool(api_name: str = "PaymentGatewayProxy", base_url: str = "https://api.boticario.com.br/v1/payments", data_classification: str = "CONFIDENCIAL / PII / PCI-DSS", project_id: str = "apigee-boticario") -> str:
    """Generates a structured STRIDE & OWASP API Top 10 Threat Model for a target API."""
    print(f"[*] ASPR Agent generating Threat Model for API: {api_name}")
    from lab_orchestration_tools import generate_api_threat_model
    return json.dumps(generate_api_threat_model(api_name=api_name, base_url=base_url, data_classification=data_classification, project_id=project_id))

class ASPRAgent:
    def __init__(self):
        self.api_key = os.environ.get("GEMINI_API_KEY")
        if not self.api_key:
            print("Error: GEMINI_API_KEY environment variable not set.")
            sys.exit(1)
        
        self.client = genai.Client(api_key=self.api_key)
        
        prompt_path = os.path.join(os.path.dirname(__file__), "system_prompt.md")
        with open(prompt_path, "r", encoding="utf-8") as f:
            self.system_instruction = f.read()

        self.tools = [
            check_environment_and_iam_tool,
            enable_apis_tool,
            activate_api_hub_tool,
            deploy_waap_waf_tool,
            activate_advanced_security_tool,
            audit_security_health_tool,
            tune_cloud_armor_crs_tool,
            configure_recaptcha_bot_defense_tool,
            configure_rate_limiting_and_ban_tool,
            detect_perimeter_bypass_tool,
            inject_security_action_tool,
            hunt_shadow_and_zombie_apis_tool,
            setup_southbound_mtls_tool,
            verify_scc_activation_tool,
            query_scc_findings_tool,
            remediate_scc_finding_tool,
            run_red_team_simulation_tool,
            synthesize_custom_in_flight_script_tool,
            execute_custom_in_flight_script_tool,
            list_security_scripts_inventory_tool,
            refresh_threat_intel_tool,
            generate_api_threat_model_tool
        ]
        
        self.config = types.GenerateContentConfig(
            system_instruction=self.system_instruction,
            tools=self.tools,
            temperature=0.2,
        )

    def run(self, user_prompt: str):
        print(f"\n🚀 ASPR Security Super Agent Initialized. Processing intent...\n")
        chat = self.client.chats.create(model="gemini-2.5-pro", config=self.config)
        response = chat.send_message(user_prompt)
        print("\n=======================================================")
        print("📊 ASPR SECURITY ADVISORY & EXECUTION REPORT")
        print("=======================================================\n")
        print(response.text)
        print("\n=======================================================")

if __name__ == "__main__":
    agent = ASPRAgent()
    prompt = "Verifique se o meu ambiente no projeto apigee-boticario possui o módulo do Security Command Center (SCC) ativo e qual é a versão/tier necessária para segurança de APIs."
    if len(sys.argv) > 1:
        prompt = " ".join(sys.argv[1:])
    agent.run(prompt)
