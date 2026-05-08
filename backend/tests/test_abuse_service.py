"""
Unit tests for Apigee Advanced API Security abuse detection and incident reporting services.
Executes under `ANTIGRAVITY_ENV=local` to verify mock incident datasets and filtering logic.
"""

import os
import unittest
from backend.config import Config
from backend.models.incident_models import (
    SecurityIncident,
    SecurityIncidentActor,
    SecurityIncidentsRequest,
    SecurityIncidentsResponse,
)
from backend.services.apigee_client import ApigeeClient
from backend.services.abuse_detection_service import AbuseDetectionService
from backend.app import ApplicationRouter


class TestAbuseDetectionService(unittest.TestCase):
    """
    Test suite for abuse detection service and declarative security incident models.
    """

    def setUp(self) -> None:
        os.environ["ANTIGRAVITY_ENV"] = "local"
        self.config = Config()
        self.client = ApigeeClient(config=self.config)
        self.service = AbuseDetectionService(client=self.client, config=self.config)
        self.router = ApplicationRouter(config=self.config)

    def test_incident_model_serialization(self) -> None:
        """Verify incident model dictionary serialization and deserialization."""
        actor = SecurityIncidentActor(
            ip_address="198.51.100.42",
            user_agent="Test-Agent/1.0",
            region="us-east1",
        )
        incident = SecurityIncident(
            incident_id="test-inc-001",
            environment="eval",
            proxy_name="test-proxy",
            incident_type="PROMPT_INJECTION",
            severity="CRITICAL",
            status="ACTIVE",
            actor=actor,
            enforcement_mode="FLAG",
            event_count=50,
        )

        data_dict = incident.to_dict()
        self.assertEqual(data_dict["incident_id"], "test-inc-001")
        self.assertEqual(data_dict["actor"]["ip_address"], "198.51.100.42")
        self.assertEqual(data_dict["enforcement_mode"], "FLAG")

        reconstructed = SecurityIncident.from_dict(data_dict)
        self.assertEqual(reconstructed.incident_id, "test-inc-001")
        self.assertEqual(reconstructed.actor.ip_address, "198.51.100.42")

    def test_get_active_incidents_local(self) -> None:
        """Test get_active_incidents returns mock incidents in local mode."""
        response = self.service.get_active_incidents(environment="eval", limit=100)

        self.assertIsInstance(response, SecurityIncidentsResponse)
        self.assertEqual(response.total_count, 3)
        self.assertEqual(len(response.incidents), 3)

        inc_ids = {i.incident_id for i in response.incidents}
        self.assertIn("inc-2026-0730-001", inc_ids)
        self.assertIn("inc-2026-0730-002", inc_ids)
        self.assertIn("inc-2026-0730-003", inc_ids)

        # Verify XFF IP telemetry preservation
        for inc in response.incidents:
            self.assertNotEqual(inc.actor.ip_address, "(not set)")
            self.assertNotEqual(inc.actor.ip_address, "0.0.0.0")

        # Verify progressive enforcement mode (at least one Flag mode incident)
        enforcement_modes = {i.enforcement_mode for i in response.incidents}
        self.assertIn("FLAG", enforcement_modes)

    def test_get_active_incidents_filter_status(self) -> None:
        """Test status filtering for security incident retrieval."""
        response_active = self.service.get_active_incidents(
            environment="eval",
            status="ACTIVE",
        )
        for inc in response_active.incidents:
            self.assertEqual(inc.status, "ACTIVE")

        response_mitigated = self.service.get_active_incidents(
            environment="eval",
            status="MITIGATED",
        )
        for inc in response_mitigated.incidents:
            self.assertEqual(inc.status, "MITIGATED")

    def test_incidents_endpoint_dispatch(self) -> None:
        """Test GET `/api/v1/security-incidents/active` application routing."""
        status_code, response_payload = self.router.dispatch(
            "GET",
            "/api/v1/security-incidents/active",
            params={"environment": "eval", "limit": "2"},
        )
        self.assertEqual(status_code, 200)
        self.assertIn("incidents", response_payload)
        self.assertLessEqual(len(response_payload["incidents"]), 2)


if __name__ == "__main__":
    unittest.main()
