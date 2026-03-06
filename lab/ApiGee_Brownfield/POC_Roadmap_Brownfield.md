# Apigee Advanced API Security - Brownfield Journey

## The Vision: Brownfield Scenario
In the **Greenfield** journey, we built everything from scratch with security by design. 
In this **Brownfield** journey, we simulate a real-world enterprise scenario:
- The customer has Apigee running.
- They have legacy APIs deployed.
- They are blind to bot traffic, shadow APIs, and deep misconfigurations because Advanced API Security is "disabled".
- Our mission: Activate the module, assess the disaster, and present a strategic security posture report.

To save time and costs, we reuse the existing GCP Project and Apigee Instance, logically isolated in a new environment.

---

## Step-by-Step Execution

### Phase 1: Creating the "Legacy" Environment
- **Action:** Run `./scripts/01_Setup_Legacy_Env.sh`
- Creates `env-brownfield` and attaches it to the existing instance and `legacy.poc-apigee.com` environment group.

### Phase 2: Generating Legacy Apps
- **Action:** Run `./scripts/02_Create_Legacy_Apps.sh`
- Creates the XML configurations and zips them for our vulnerable legacy applications.

### Phase 3: Deploying the Unprotected Backends
- **Action:** Run `./scripts/03_Deploy_Legacy_APIs.sh`
- Deploys the legacy proxies. These proxies are extremely vulnerable: no API keys, no Spike Arrest, no JSON Threat protection.

### Phase 4: The "Blind" Traffic (Before Security)
- **Action:** Run `./scripts/04_Traffic_Simulator.sh`
- Deploys a background shell script to our internal VM that endlessly bombards `legacy.poc-apigee.com` with:
  1. Undocumented API calls (Shadow APIs).
  2. Giant JSON Payloads (Anomalies).
  3. Scraper Bot User-Agents.

### Phase 5: Activating Advanced API Security (The Intervention)
- **Action:** Run `./scripts/05_Activate_Advanced_Security.sh`
- Simulates the business action of buying and enabling the Advanced API Security add-on. 

### Phase 6: Enabling ML & Bot Detection
- **Action:** Run `./scripts/06_Enable_Advanced_Security_ML.sh`
- Configures Apigee's machine learning models to detect abuse and misconfigurations retroactively.

### Phase 7: Strategic Posture Analysis & Remediation
- **Action:** Run `./scripts/07_Generate_Security_Report.sh`
Following the instructions, you will demonstrate:
1. **Security Posture Dashboard:** Point out how the legacy proxy violates enterprise standards.
2. **Shadow API Discovery:** Show how Apigee found the undocumented endpoints the bots were henterpriseng.
3. **Remediation Discussion:** Discuss applying a universal Security Shared Flow to the environment and using Apigee Security Actions to ban the malicious IP.
