"""
HTTP client for Apigee Advanced API Security APIs.

Supports Google Application Default Credentials (ADC) for production/cloud environments
and automatically degrades to deterministic mock responses when running in local mode.
"""

import json
import urllib.parse
import urllib.request
from typing import Any, Callable, Dict, Optional
from backend.config import Config, get_config


class ApigeeClientError(Exception):
    """
    Raised when an Apigee API call fails or returns a non-200 status code.
    """
    def __init__(self, message: str, status_code: Optional[int] = None) -> None:
        super().__init__(message)
        self.status_code = status_code


class ApigeeClient:
    """
    HTTP client wrapper for Google Apigee API Security endpoints.
    """

    def __init__(self, config: Optional[Config] = None) -> None:
        self.config: Config = config or get_config()
        self.mock_post_handlers: Dict[str, Callable[[str, Dict[str, Any]], Dict[str, Any]]] = {}
        self.mock_get_handlers: Dict[str, Callable[[str, Optional[Dict[str, Any]]], Dict[str, Any]]] = {}
        self._setup_default_mocks()

    def _setup_default_mocks(self) -> None:
        """
        Configure default mock handlers for local mode execution.
        """
        self.register_mock_post(
            "securityAssessmentResults:batchCompute",
            self._default_mock_batch_compute,
        )
        self.register_mock_get(
            "securityIncidents",
            self._default_mock_security_incidents,
        )

    def register_mock_post(
        self,
        endpoint_keyword: str,
        handler: Callable[[str, Dict[str, Any]], Dict[str, Any]],
    ) -> None:
        """Register a mock handler for POST requests matching a keyword in the URL."""
        self.mock_post_handlers[endpoint_keyword] = handler

    def register_mock_get(
        self,
        endpoint_keyword: str,
        handler: Callable[[str, Optional[Dict[str, Any]]], Dict[str, Any]],
    ) -> None:
        """Register a mock handler for GET requests matching a keyword in the URL."""
        self.mock_get_handlers[endpoint_keyword] = handler

    def get_authorization_header(self) -> Dict[str, str]:
        """
        Retrieve Authorization header using Google Application Default Credentials (ADC).
        """
        if self.config.is_local_mode():
            return {"Authorization": "Bearer mock-local-adc-token"}

        try:
            import google.auth  # type: ignore
            from google.auth.transport.requests import Request  # type: ignore

            credentials, _ = google.auth.default(
                scopes=["https://www.googleapis.com/auth/cloud-platform"]
            )
            credentials.refresh(Request())
            return {"Authorization": f"Bearer {credentials.token}"}
        except Exception as exc:
            raise ApigeeClientError(
                f"Failed to acquire Application Default Credentials: {exc}"
            ) from exc

    def post(
        self,
        url: str,
        json_payload: Dict[str, Any],
        params: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Execute an HTTP POST request against an Apigee endpoint.
        In local mode, routes to registered mock handlers without network calls.
        """
        if self.config.is_local_mode():
            for keyword, handler in self.mock_post_handlers.items():
                if keyword in url:
                    return handler(url, json_payload)
            return {"status": "mock_success", "url": url}

        headers = self.get_authorization_header()
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"

        full_url = url
        if params:
            full_url = f"{url}?{urllib.parse.urlencode(params)}"

        data_bytes = json.dumps(json_payload).encode("utf-8")
        req = urllib.request.Request(full_url, data=data_bytes, headers=headers, method="POST")

        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                body = response.read().decode("utf-8")
                return json.loads(body) if body else {}
        except Exception as exc:
            raise ApigeeClientError(f"POST request to {full_url} failed: {exc}") from exc

    def get(
        self,
        url: str,
        params: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Execute an HTTP GET request against an Apigee endpoint.
        In local mode, routes to registered mock handlers without network calls.
        """
        if self.config.is_local_mode():
            for keyword, handler in self.mock_get_handlers.items():
                if keyword in url:
                    return handler(url, params)
            return {"status": "mock_success", "url": url}

        headers = self.get_authorization_header()
        headers["Accept"] = "application/json"

        full_url = url
        if params:
            full_url = f"{url}?{urllib.parse.urlencode(params)}"

        req = urllib.request.Request(full_url, headers=headers, method="GET")

        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                body = response.read().decode("utf-8")
                return json.loads(body) if body else {}
        except Exception as exc:
            raise ApigeeClientError(f"GET request to {full_url} failed: {exc}") from exc

    def _default_mock_batch_compute(
        self,
        url: str,
        payload: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Realistic default mock payload for `/securityAssessmentResults:batchCompute`.
        """
        scope_data = payload.get("scope", {})
        org_id = scope_data.get("organization_id", self.config.APIGEE_ORG_ID)
        env_id = scope_data.get("environment_id", self.config.APIGEE_ENV)
        target = f"organizations/{org_id}/environments/{env_id}"

        return {
            "overall_score": 90.0,
            "risk_level": "LOW",
            "next_page_token": None,
            "results": [
                {
                    "assessment_id": "assess-2026-0730-001",
                    "target_resource": target,
                    "overall_score": 90.0,
                    "risk_level": "LOW",
                    "assessed_at": "2026-07-30T13:38:06Z",
                    "metrics": [
                        {
                            "metric_id": "risk_assessment_v2_score",
                            "category": "risk_assessment",
                            "score": 92.5,
                            "status": "PASS",
                            "description": "Risk Assessment v2 policies active across assessed proxies.",
                        },
                        {
                            "metric_id": "verify_api_key_coverage",
                            "category": "authentication",
                            "score": 100.0,
                            "status": "PASS",
                            "description": "VerifyAPIKey shared flow enforced on external endpoints.",
                        },
                        {
                            "metric_id": "oauth_v2_coverage",
                            "category": "authentication",
                            "score": 95.0,
                            "status": "PASS",
                            "description": "OAuthV2 token validation enabled for sensitive APIs.",
                        },
                        {
                            "metric_id": "json_threat_protection_coverage",
                            "category": "threat_protection",
                            "score": 85.0,
                            "status": "PASS",
                            "description": "JSONThreatProtection active; 2 internal proxies pending configuration.",
                        },
                        {
                            "metric_id": "ai_model_armor_coverage",
                            "category": "risk_assessment",
                            "score": 88.0,
                            "status": "PASS",
                            "description": "LLM/Generative AI prompt sanitization and response filtering enabled.",
                        },
                    ],
                }
            ],
        }

    def _default_mock_security_incidents(
        self,
        url: str,
        params: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Realistic default mock payload for `/securityIncidents`.
        """
        params = params or {}
        env_id = params.get("environment", self.config.APIGEE_ENV)

        incidents = [
            {
                "incident_id": "inc-2026-0730-001",
                "environment": env_id,
                "proxy_name": "llm-gateway-proxy",
                "incident_type": "PROMPT_INJECTION",
                "severity": "CRITICAL",
                "status": "ACTIVE",
                "actor": {
                    "ip_address": "198.51.100.42",
                    "user_agent": "Mozilla/5.0 (AI-Agent-Tester)",
                    "region": "us-east1",
                },
                "enforcement_mode": "FLAG",
                "first_observed": "2026-07-29T10:15:00Z",
                "last_observed": "2026-07-30T13:30:00Z",
                "event_count": 142,
                "description": (
                    "Detected adversarial prompt injection attempts targeting Generative AI endpoint. "
                    "Action currently in Flag mode for 72-hour evaluation."
                ),
            },
            {
                "incident_id": "inc-2026-0730-002",
                "environment": env_id,
                "proxy_name": "orders-api-v1",
                "incident_type": "ABUSE_DETECTION",
                "severity": "HIGH",
                "status": "ACTIVE",
                "actor": {
                    "ip_address": "203.0.113.88",
                    "user_agent": "python-requests/2.31.0",
                    "region": "sa-east1",
                },
                "enforcement_mode": "DENY",
                "first_observed": "2026-07-28T08:00:00Z",
                "last_observed": "2026-07-30T12:45:00Z",
                "event_count": 3890,
                "description": "High-frequency scraping and credential stuffing behavior detected by Cloud Armor and Apigee Risk Assessment v2.",
            },
            {
                "incident_id": "inc-2026-0730-003",
                "environment": env_id,
                "proxy_name": "payments-api-v2",
                "incident_type": "DODS_SPIKE",
                "severity": "MEDIUM",
                "status": "MITIGATED",
                "actor": {
                    "ip_address": "192.0.2.15",
                    "user_agent": "Go-http-client/1.1",
                    "region": "eu-west1",
                },
                "enforcement_mode": "DENY",
                "first_observed": "2026-07-30T09:00:00Z",
                "last_observed": "2026-07-30T09:15:00Z",
                "event_count": 512,
                "description": "SpikeArrest and Cloud Armor rate limiting triggered on transaction endpoint. Traffic mitigated.",
            },
        ]

        status_filter = params.get("status")
        if status_filter:
            incidents = [
                i for i in incidents if i["status"].upper() == str(status_filter).upper()
            ]

        limit = int(params.get("limit", 100))
        incidents = incidents[:limit]

        return {
            "incidents": incidents,
            "total_count": len(incidents),
            "next_page_token": None,
        }
