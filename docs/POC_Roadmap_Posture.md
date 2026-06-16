# Apigee API Security Posture & Governance (ASPM)

## The Vision: Multi-Cloud API Security Posture Review
In the modern enterprise, APIs are not just in one place. They are distributed across **GCP, AWS, Azure, Cloudflare, Akamai, and Azion**. 
Security teams struggle with a lack of visibility. They don't know what APIs exist, where they are deployed, and if they comply with security frameworks like the **OWASP API Security Top 10**.

This scenario focuses on **API Security Posture Management (ASPM)** using Google Cloud **API Hub**.

## The Architecture
Instead of migrating all traffic to Apigee immediately, we bring the **Intelligence and Governance** to Google Cloud.
1. We collect OpenAPI Specifications (OAS) from various vendors (AWS, Azure, Azion).
2. We ingest them into API Hub, tagging them with their respective Cloud provider.
3. We run a Posture Review (Linting & Governance) to analyze the specs against security frameworks.
4. We generate a centralized dashboard showing which external APIs are non-compliant, vulnerable to data exposure, or lacking authentication.

## Execution Steps

### Phase 1: The Multi-Cloud Catalog
- **Action:** Run `scripts/01_push_to_api_hub.sh`
- This script programmatically registers APIs into API Hub.
- These APIs will be explicitly registered to create a centralized view of your APIs (Greenfield and Brownfield).

### Phase 2: Spec Ingestion & Linting
- **Action:** (Manual or via pipeline) Upload OpenAPI specs for these external APIs. Some specs will be highly secure, while others will have intentional OWASP vulnerabilities (e.g., missing OAuth, exposed PII, unconstrained inputs).

### Phase 3: The Posture Review Dashboard
- **Action:** Navigate to the API Hub Dashboard.
- Demonstrate how a CISO or Security Architect can filter by API and instantly see the Compliance Score and Security Posture of their entire footprint, planning remediation strategically.
