# ASPR Operational CLI Cheat Sheet & Runbook

Quick command reference for executing ASPR security playbooks across Google Cloud Apigee X, Cloud Armor, and Security Command Center.

---

## 1. Pre-flight Authentication & Baseline

```bash
# Verify active Google Cloud identity and required IAM administrative roles
bash scripts/01_check_prerequisites_and_auth.sh apigee-boticario

# Enable all required Google Cloud Security & Network APIs
bash scripts/02_enable_gcp_apis.sh apigee-boticario

# Provision Apigee Organization and Environment
bash scripts/03_provision_apigee_org_and_env.sh apigee-boticario prod
```

---

## 2. WAAP Perimeter & Cloud Armor WAF

```bash
# Deploy Global External HTTPS Load Balancer with Cloud Armor WAF (PREVIEW Mode)
bash scripts/05_deploy_waap_perimeter_and_waf.sh apigee-boticario us-east1 true

# Fine-tune OWASP ModSecurity CRS 3.3 Paranoia Levels (1 through 4)
bash scripts/sec_01_cloud_armor_crs_tuning.sh apigee-boticario apigee-waap-policy 1 true

# Associate reCAPTCHA Enterprise Bot Defense Keys
bash scripts/sec_02_recaptcha_enterprise_bot_defense.sh apigee-boticario

# Enforce Rate-Based Banning (100 req / 60 seconds with 600s quarantine)
bash scripts/sec_03_rate_limiting_and_ban_policies.sh apigee-boticario apigee-waap-policy 100 600

# Audit for Perimeter Ingress Bypasses (-35 point penalty)
bash scripts/sec_04_perimeter_bypass_detector.sh apigee-boticario
```

---

## 3. Gateway Hardening & Machine Learning Abuse Defense

```bash
# Activate Apigee Advanced API Security ML Abuse Detection Models
bash scripts/06_activate_advanced_api_security_ml.sh apigee-boticario prod

# Deploy Production Hardened Proxy with SpikeArrest (30ps) & AssignMessage FaultRules
bash scripts/07_deploy_hardened_api_proxy.sh apigee-boticario prod

# Configure Generative AI Defense with Google Model Armor & Cloud DLP
bash scripts/08_configure_ai_security_model_armor.sh apigee-boticario

# Inject Real-time Security Action (72h FLAG monitor mode)
bash scripts/sec_06_inject_security_actions.sh apigee-boticario prod RATE_LIMIT * FLAG

# Discover Shadow and Zombie APIs against OpenAPI Specs
bash scripts/sec_07_shadow_and_zombie_api_hunter.sh apigee-boticario prod

# Configure Southbound Mutual TLS (mTLS) with Target Microservices
bash scripts/sec_08_setup_southbound_mtls.sh apigee-boticario prod
```

---

## 4. Posture Auditing, Red Teaming & Threat Modeling

```bash
# Run Comprehensive Posture Health Audit (outputs composite Health Score)
bash scripts/09_audit_api_security_health.sh apigee-boticario prod

# Check Security Command Center Tier (Premium/Enterprise) and Auto-Remediate Findings
python3 scripts/sec_14_scc_integration_and_remediation.py apigee-boticario

# Run On-Demand Red Team Fuzzing Simulator (Generates Defense Efficacy Certificate)
python3 scripts/sec_13_api_red_team_simulator.py https://api.boticario.com.br apigee-boticario

# Generate Automated STRIDE & OWASP API Top 10 Threat Model
python3 scripts/sec_15_generate_api_threat_model.py PaymentGatewayProxy https://api.boticario.com.br/v1/payments apigee-boticario
```

---

## 5. Serverless Cloud Run Hosting

```bash
# Deploy ASPR Agent Engine to Google Cloud Run via Cloud Build
./deploy/deploy_to_gcp.sh apigee-boticario us-east1

# Trigger Posture Audit via Cloud Run REST API
curl -X POST https://aspr-agent-service.a.run.app/api/aspr/audit \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -H "Content-Type: application/json" \
  -d '{"project_id": "apigee-boticario", "environment": "prod"}'
```
