import re

with open('../POC_Roadmap_Advanced_API_Security.md', 'r') as f:
    content = f.read()

# Replace Phase numbers and Script references
content = content.replace("## Phase 1b: API Hub Provisioning (Governance)", "## Phase 2: API Hub Provisioning (Governance)")
content = content.replace("scripts/01b_Setup_API_Hub.sh", "scripts/02_Setup_API_Hub.sh")

content = content.replace("## Phase 2: Runtime Provisioning (Instance)", "## Phase 3: Runtime Provisioning (Instance)")
content = content.replace("scripts/02_Setup_Apigee_Runtime.sh", "scripts/03_Setup_Apigee_Runtime.sh")

content = content.replace("## Phase 3: Vulnerable Scenario Deployment (Apps 1 to 5)", "## Phase 4: Vulnerable Scenario Deployment (Apps 1 to 5)")

content = content.replace("## Phase 4: Malicious Traffic Simulation (Attack)", "## Phase 5: Malicious Traffic Simulation (Attack)")
content = content.replace("scripts/03_Traffic_Simulator.sh", "scripts/04_Traffic_Simulator.sh\n- (Optional) You can also use `scripts/05_Create_Test_VM.sh` to generate traffic from an internal VPC machine if you haven't exposed Apigee externally.")

content = content.replace("## Phase 5: Security Dashboard Analysis", "## Phase 6: Security Dashboard Analysis")

content = content.replace("## Phase 6 (Optional Challenge): Mitigation", "## Phase 7 (Optional Challenge): Mitigation")

with open('../POC_Roadmap_Advanced_API_Security.md', 'w') as f:
    f.write(content)

