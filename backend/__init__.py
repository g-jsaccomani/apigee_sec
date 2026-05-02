"""
API Security Posture Review (API-SPR) Backend Application.

This package provides:
- Declarative models representing Apigee security posture and abuse detection datasets.
- HTTP client layer with Google Application Default Credentials (ADC) and local mock fallback.
- Backend services for `/securityAssessmentResults:batchCompute` and `/securityIncidents`.
- REST API application routes for security posture assessment and incident monitoring.
"""

__version__ = "1.0.0"
