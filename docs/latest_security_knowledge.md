# Live API Security Knowledge Base & Threat Intel Feed
**Last Updated:** `2026-08-08T00:24:35Z` | **Version:** `2026.08-LATEST`

---

## 1. Tracked Security Frameworks & Standards
* **OWASP API Security Top 10 (2023)** (BOLA, Broken Auth, BOPLA, Resource Consumption, BFLA, SSRF, Misconfig, Inventory, Unsafe Consumption)
* **OWASP Top 10 for LLM / GenAI (2025/2026)** (Prompt Injection, Model Armor, DLP De-identification)
* **NIST SP 800-207 Zero Trust Architecture** (End-to-End mTLS, ephemeral OAuth 2.1 tokens)
* **CIS Google Cloud Platform Foundations Benchmark v3.0**

---

## 2. Google Cloud Armor WAF Rule Expressions (OWASP CRS v33-stable)

| Threat Category | Preconfigured WAF Expression | Default Paranoia Level |
| :--- | :--- | :--- |
| **SQL Injection (SQLi)** | `evaluatePreconfiguredExpr('sqli-v33-stable', 1)` | Level 1 (Zero False Positives) |
| **Cross-Site Scripting (XSS)** | `evaluatePreconfiguredExpr('xss-v33-stable')` | Level 1 |
| **Remote Code Execution (RCE)**| `evaluatePreconfiguredExpr('rce-v33-stable')` | Level 1 |
| **Local File Inclusion (LFI)** | `evaluatePreconfiguredExpr('lfi-v33-stable')` | Level 1 |
| **Scanner / Probe Detection** | `evaluatePreconfiguredExpr('scannerdetection-v33-stable')` | Level 1 |

---

## 3. Emerging Threats & Remediation Guidance

### Warning CVE-2024-XXXX - HTTP/2 Rapid Reset & Request Smuggling (Severity: **HIGH**, CVSS: `8.5`)
- **Impacted Component:** `Envoy / Apigee Gateway Target Proxy`
- **Recommended Remediation:** Apply Cloud Armor L7 Adaptive Protection and SpikeArrest (30ps) to mitigate frame floods.

### Warning CWE-918 - Server-Side Request Forgery (SSRF) (Severity: **CRITICAL**, CVSS: `9.1`)
- **Impacted Component:** `TargetEndpoint Forwarding`
- **Recommended Remediation:** Impose target URL whitelisting in JavaScript policy and restrict outbound IP ranges in VPC Service Controls.

### Warning CWE-862 - Broken Object Level Authorization (BOLA) (Severity: **HIGH**, CVSS: `8.8`)
- **Impacted Component:** `REST Resource URI Mapping`
- **Recommended Remediation:** Validate JWT subject claims (`sub`, user/tenant ID) against the URI path parameter `{user_id}`.

---

## 4. ASPR Deterministic Execution Guardrails
1. **72 Hours in FLAG / PREVIEW Mode**: Every newly injected blocking rule (`deny-403`) or rate limit must operate in preview/monitor mode before promotion to `DENY`.
2. **12-Week Baseline Telemetry**: ML-driven anomaly detection models require 12 weeks of continuous traffic telemetry.
3. **FaultRule Error Masking via AssignMessage**: Apigee proxies must catch all backend exceptions and respond with sanitized JSON, preventing internal stack trace leaks.
