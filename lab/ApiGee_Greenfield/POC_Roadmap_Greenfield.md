# Apigee API Security & Governance POC

## The Vision
In this **Greenfield** journey, we execute a complete security POC in Apigee, deploying vulnerable services, performing simulated attacks, and using the **Advanced API Security** and **API Hub** dashboards to detect misconfigurations and malicious traffic (bots, anomalies, abuse).

All scripts are saved in your workspace: `lab/ApiGee_Greenfield/scripts/`

---

## Prerequisites & Permissions

Before running the scripts, you must ensure that your accounts have the correct permissions. We use **Service Account Impersonation** for security best practices.

### 1. User Account (Personal GCP Account)
- **Required Role:** `roles/iam.serviceAccountTokenCreator` on the specific Apigee Service Account.

### 2. Apigee Service Account
- **Required Roles:** `roles/editor`, `roles/run.admin`, `roles/serviceusage.serviceUsageAdmin`, `roles/compute.networkAdmin`, `roles/servicenetworking.networksAdmin`, `roles/cloudkms.admin`, `roles/apigee.admin`, `roles/iap.tunnelResourceAccessor`.

### 3. Default Compute Service Account
- **Required Roles:** `roles/cloudbuild.builds.builder`.

### 4. Network & Organization Policies
- **IAP SSH Firewall Rule**: The VPC network must have an active firewall rule allowing `tcp:22` from `35.235.240.0/20`.
- **External IP Restrictions**: If blocked, scripts deploy Private VMs, Private GKE nodes, and Cloud NATs to ensure compliance.

---

## Step-by-Step Execution

### Phase 0: Connect to GCP
**Action:** Execute `scripts/00_Init_Connection.sh`
- Runs `gcloud auth login`, `gcloud config set project`, and sets up Service Account impersonation.

### Phase 1: Base Preparation (Infrastructure)
**Action:** Execute `scripts/01_Setup_Apigee_Env.sh`
- Checks for missing APIs, VPC Peering, and KMS keys, applying fixes if needed.

### Phase 2: API Hub Provisioning (Governance)
**Action:** Execute `scripts/02_Setup_API_Hub.sh`
- Enables API Hub service, registers Host Project, creates instance.

### Phase 3: Runtime Provisioning (Instance)
**Action:** Execute `scripts/03_Setup_Apigee_Runtime.sh`
- Verifies Org, activates Advanced API Security, creates Instance, Environment, and Environment Group.

### Phase 4: Vulnerable Scenario Deployment (Apps 1 to 5)
**Action:** Execute `scripts/04_Setup_APIs.sh`
- Deploys 5 vulnerable backend services (GKE, Cloud Run, App Engine) and their respective Apigee Proxies.
- `App001` (Leaks data without VerifyAPIKey)
- `App002` (Lacks SpikeArrest, vulnerable to DDoS)
- `App003` (Incorrectly configured CORS)
- `App004` (Does not block giant JSON payloads)
- `App005` (Leaks admin headers and GKE Stack Traces)

### Phase 5: Test VM Creation
**Action:** Execute `scripts/05_Create_Test_VM.sh`
- Generates an internal VPC machine to generate traffic from.

### Phase 6: Malicious Traffic Simulation (Attack)
**Action:** Execute `scripts/06_Traffic_Simulator.sh`
- Triggers CURL bursts simulating DoS, giant payloads, and bot traffic.
**Action:** (When done) Execute `scripts/07_Stop_Traffic_Simulator.sh`

### Phase 7: Enable ML & Bot Detection
**Action:** Execute `scripts/08_Enable_Advanced_Security_ML.sh`
- Configures Apigee's machine learning models to detect abuse and misconfigurations retroactively.

### Phase 8: Deploy External Load Balancer and WAF
**Action:** Execute `scripts/09_Deploy_External_LB_and_WAF.sh`
- (Optional) Deploys a global HTTP(S) Load Balancer and Cloud Armor WAF to protect the Apigee gateway from external attacks.

### Phase 9: Security Dashboard Analysis
Wait 15 to 30 minutes after the traffic simulation.
1. Access the **Apigee Console** in Google Cloud.
2. Navigate to the menu **Analyze > API Security**.
3. **Evaluate the "Security Reports" Dashboard:** Check Bot Detection and Traffic Patterns.
4. **Evaluate the "Configuration" Dashboard:** View Misconfigurations.
5. Navigate to the **API Hub** to observe API cataloging.

### Phase 10 (Optional Challenge): Mitigation
1. Identify Bot attacks via Advanced API Security.
2. Extract the rules (IPs / Patterns).
3. Use the Apigee **Security Actions** module or integrate with **Google Cloud Armor** to temporarily ban the attacking IP.
