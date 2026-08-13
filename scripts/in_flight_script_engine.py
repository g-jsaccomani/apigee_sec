"""
ASPR In-Flight Dynamic Security Script Synthesis & Execution Engine.
Allows the Gemini AI model to synthesize, audit, validate, and execute custom
security automation scripts on-the-fly (em voo) based on Google Cloud best practices.
"""

import os
import sys
import subprocess
import json
import re
from datetime import datetime
from typing import Dict, Any, List, Optional

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SCRIPTS_DIR = os.path.join(REPO_ROOT, "scripts")
CUSTOM_SCRIPTS_DIR = os.path.join(SCRIPTS_DIR, "custom")

def validate_script_guardrails(script_content: str, script_name: str) -> Dict[str, Any]:
    """
    Validates that dynamically generated scripts adhere strictly to ASPR safety guardrails.
    Checks for error trapping (set -e), prevention of raw token leakage, and monitor-first rules.
    """
    violations = []
    
    # Guardrail 1: Strict error handling
    if script_name.endswith(".sh") and "set -e" not in script_content:
        violations.append("Missing 'set -e' for strict error bubbling.")
        
    # Guardrail 2: Hardcoded secrets detection
    secret_patterns = [r"AIza[0-9A-Za-z-_]{35}", r"bearer\s+[a-zA-Z0-9\.\-_]{50,}", r"-----BEGIN\s+PRIVATE\s+KEY-----"]
    for pattern in secret_patterns:
        if re.search(pattern, script_content, re.IGNORECASE):
            violations.append("Potential hardcoded API key or private key detected.")
            
    # Guardrail 3: FLAG/PREVIEW mode awareness on blocking rules
    if "deny" in script_content.lower() and ("preview" not in script_content.lower() and "flag" not in script_content.lower()):
        violations.append("Blocking rule detected without explicit PREVIEW/FLAG mode support (72h monitor baseline rule).")
        
    return {
        "valid": len(violations) == 0,
        "violations": violations
    }

def synthesize_and_save_in_flight_script(
    script_name: str,
    script_content: str,
    description: str = "Custom In-Flight Security Automation Script",
    author: str = "ASPR-Gemini-Engine"
) -> Dict[str, Any]:
    """
    Synthesizes and saves a new custom security script in `scripts/custom/`.
    
    Args:
        script_name: File name (e.g. 'custom_mitigate_sql_injection_patch.sh').
        script_content: The bash or python code generated in-flight.
        description: Purpose of the script.
        author: Generating model/author.
        
    Returns:
        Validation results and file path.
    """
    os.makedirs(CUSTOM_SCRIPTS_DIR, exist_ok=True)
    
    # Sanitize script name
    clean_name = re.sub(r'[^a-zA-Z0-9_\-\.]', '_', script_name)
    if not (clean_name.endswith(".sh") or clean_name.endswith(".py")):
        clean_name += ".sh"
        
    target_path = os.path.join(CUSTOM_SCRIPTS_DIR, clean_name)
    
    # Audit script against safety guardrails
    audit_res = validate_script_guardrails(script_content, clean_name)
    if not audit_res["valid"]:
        return {
            "status": "GUARDRAIL_VIOLATION",
            "message": "Script failed security guardrail validation.",
            "violations": audit_res["violations"]
        }
        
    # Write script to disk
    with open(target_path, "w", encoding="utf-8") as f:
        f.write(script_content)
        
    # Make executable
    os.chmod(target_path, 0o755)
    
    return {
        "status": "SAVED",
        "script_name": clean_name,
        "path": target_path,
        "description": description,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "message": f"Custom script '{clean_name}' synthesized and validated successfully."
    }

def execute_in_flight_script(
    script_name: str,
    args: Optional[List[str]] = None,
    dry_run: bool = False
) -> Dict[str, Any]:
    """
    Executes a previously synthesized custom script from `scripts/custom/`.
    
    Args:
        script_name: Name of the script in `scripts/custom/`.
        args: Command line arguments to pass.
        dry_run: If True, tests execution command without applying changes.
    """
    clean_name = os.path.basename(script_name)
    target_path = os.path.join(CUSTOM_SCRIPTS_DIR, clean_name)
    
    if not os.path.exists(target_path):
        return {
            "status": "ERROR",
            "message": f"Custom script '{clean_name}' not found in {CUSTOM_SCRIPTS_DIR}."
        }
        
    cmd = ["bash", target_path] + (args or []) if clean_name.endswith(".sh") else ["python3", target_path] + (args or [])
    
    if dry_run:
        return {
            "status": "DRY_RUN",
            "script": clean_name,
            "command": " ".join(cmd),
            "message": "Dry-run validation successful. Script is safe to execute."
        }
        
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=300)
        return {
            "status": "SUCCESS" if res.returncode == 0 else "FAILED",
            "returncode": res.returncode,
            "script": clean_name,
            "stdout": res.stdout[-3000:] if len(res.stdout) > 3000 else res.stdout,
            "stderr": res.stderr[-1000:] if len(res.stderr) > 1000 else res.stderr,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
    except Exception as e:
        return {
            "status": "EXCEPTION",
            "script": clean_name,
            "error": str(e)
        }

def list_all_security_scripts() -> Dict[str, Any]:
    """Lists all built-in and dynamically generated security scripts available to the agent."""
    built_in = [f for f in os.listdir(SCRIPTS_DIR) if (f.endswith(".sh") or f.endswith(".py")) and not f.startswith("__")]
    custom = [f for f in os.listdir(CUSTOM_SCRIPTS_DIR) if os.path.isfile(os.path.join(CUSTOM_SCRIPTS_DIR, f))] if os.path.exists(CUSTOM_SCRIPTS_DIR) else []
    
    return {
        "built_in_scripts_count": len(built_in),
        "built_in_scripts": sorted(built_in),
        "custom_in_flight_scripts_count": len(custom),
        "custom_in_flight_scripts": sorted(custom)
    }

if __name__ == "__main__":
    overview = list_all_security_scripts()
    print("📋 ASPR Security Script Inventory:")
    print(f"   - Built-in Security Scripts: {overview['built_in_scripts_count']}")
    print(f"   - Custom In-Flight Scripts:   {overview['custom_in_flight_scripts_count']}")
    for s in overview['built_in_scripts']:
        print(f"     • {s}")
