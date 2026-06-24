# Apigee API Gateway Security & OWASP API Security Top 10 (2026 Guide)

This document establishes the defense-in-depth architecture and technical controls for securing APIs on **Google Cloud Apigee X / Hybrid**, systematically mitigating vulnerabilities categorized under the **OWASP API Security Top 10 (2023)**.

---

## 1. Perimeter Hardening (Google Cloud Armor WAF + Adaptive Protection)

- **Northbound / Southbound Edge Cloud Armor Integration**:
  - Implement Google Cloud Armor fronting Apigee (via External HTTP(S) Load Balancer + PSC NEG) configured with:
    - **OWASP ModSecurity Core Rule Set (CRS 3.3+)**: Comprehensive protection against SQLi, XSS, RCE, and LFI.
    - **Adaptive Protection (ML L7 DDoS)**: Automated anomaly detection and volumetric layer 7 flood mitigation.
    - **Rate Limiting & Bot Management**: Client IP throttling, rate-based bans, and reCAPTCHA Enterprise credential stuffing defense.

---

## 2. OWASP API Security Top 10 Mitigation Controls

| OWASP API Top 10 Category | Recommended Apigee Policy | Technical Controls & Implementation |
| :--- | :--- | :--- |
| **API1: Broken Object Level Authorization (BOLA)** | `OAuthV2` / `VerifyJWT` + Context Extraction | Verify at the Gateway that the resource identifier in the URI strictly matches the authenticated subject (`sub` in JWT). |
| **API2: Broken Authentication** | `OAuthV2` / `VerifyAPIKey` + Southbound mTLS | Require OAuth 2.0 (Authorization Code / Client Credentials with PKCE), frequent token rotation, and prohibit keys in query strings. |
| **API3: Broken Object Property Level Auth (BOPLA)**| `JSONThreatProtection` + `OASValidation` | Enforce strict OpenAPI 3.0/3.1 contract validation, stripping unapproved request/response fields and limiting payload depth. |
| **API4: Unrestricted Resource Consumption** | `SpikeArrest` + `Quota` + `MessageSizeQuota` | Configure `SpikeArrest` (e.g. 30ps) for burst protection, `Quota` per developer app, and Cloud Armor rate-based IP ban. |
| **API5: Broken Function Level Authorization (BFLA)**| `AccessControl` + RBAC Claims | Validate authorization claims (scopes/roles) in JWT before routing administrative HTTP verbs (`DELETE`, `PUT`, `/admin/*`). |
| **API8: Security Misconfiguration** | `AssignMessage` (Security Headers & FaultRules) | Inject standard HTTP security headers (`HSTS`, `X-Content-Type-Options`, `X-Frame-Options`, `CSP`) and sanitize error envelopes. |

---

## 3. Southbound Security & Zero Trust Architecture (mTLS & Private DNS)

- **Southbound Mutual TLS (mTLS) to Target Microservices**:
  - All communication between Apigee and target backends (GKE, Cloud Run, Compute Engine) must enforce **bidirectional mTLS** with certificates managed in Google Certificate Authority Service (CAS).
- **VPC Service Controls & Private Service Connect (PSC)**:
  - Isolate backend traffic through private endpoints via PSC without traversing the public internet.

---

## 4. Advanced Threat Detection & SecOps Integration

- **Apigee Advanced API Security**:
  - Activate **API Abuse Detection** to uncover anomalous traffic patterns and credential stuffing using Google machine learning models.
- **SecOps SIEM & Chronicle Export**:
  - Stream structured API access logs and security alerts via `MessageLogging` or Pub/Sub into Google SecOps (Chronicle SIEM).
