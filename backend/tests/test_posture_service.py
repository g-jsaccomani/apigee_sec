"""
Unit tests for Apigee Advanced API Security posture assessment services and models.
Executes under `ANTIGRAVITY_ENV=local` to verify mock data generation and model serialization.
"""

import os
import unittest
from backend.config import Config
from backend.models.posture_models import (
    AssessmentScope,
    BatchComputePostureRequest,
    BatchComputePostureResponse,
    PostureAssessmentMetric,
    PostureAssessmentResult,
)
from backend.services.apigee_client import ApigeeClient
from backend.services.posture_service import PostureService
from backend.app import ApplicationRouter


class TestPostureService(unittest.TestCase):
    """
    Test suite for posture assessment service and related declarative models.
    """

    def setUp(self) -> None:
        os.environ["ANTIGRAVITY_ENV"] = "local"
        self.config = Config()
        self.client = ApigeeClient(config=self.config)
        self.service = PostureService(client=self.client, config=self.config)
        self.router = ApplicationRouter(config=self.config)

    def test_config_local_mode(self) -> None:
        """Verify configuration correctly identifies local execution mode."""
        self.assertTrue(self.config.is_local_mode())
        self.assertEqual(self.config.ANTIGRAVITY_ENV.lower(), "local")
        self.assertEqual(self.config.PORT, 8080)
        self.assertEqual(self.config.FLAG_DURATION_HOURS, 72)

    def test_posture_model_serialization(self) -> None:
        """Verify model serialization and deserialization across dictionary conversions."""
        scope = AssessmentScope(organization_id="test-org", environment_id="eval")
        req = BatchComputePostureRequest(scope=scope, page_size=25, include_details=True)

        data_dict = req.to_dict()
        self.assertEqual(data_dict["page_size"], 25)
        self.assertTrue(data_dict["include_details"])
        self.assertEqual(data_dict["scope"]["organization_id"], "test-org")

        reconstructed = BatchComputePostureRequest.from_dict(data_dict)
        self.assertEqual(reconstructed.page_size, 25)
        self.assertEqual(reconstructed.scope.organization_id, "test-org")

    def test_compute_posture_assessment_local(self) -> None:
        """Test compute_posture_assessment returns realistic mock score metrics in local mode."""
        scope = AssessmentScope(organization_id="mock-org", environment_id="eval")
        request = BatchComputePostureRequest(scope=scope)

        response = self.service.compute_posture_assessment(request)

        self.assertIsInstance(response, BatchComputePostureResponse)
        self.assertEqual(response.overall_score, 90.0)
        self.assertEqual(response.risk_level, "LOW")
        self.assertGreater(len(response.results), 0)

        first_result = response.results[0]
        self.assertIsInstance(first_result, PostureAssessmentResult)
        self.assertEqual(first_result.target_resource, "organizations/mock-org/environments/eval")
        self.assertGreater(len(first_result.metrics), 0)

        # Check expected core metrics
        metric_ids = {m.metric_id for m in first_result.metrics}
        self.assertIn("risk_assessment_v2_score", metric_ids)
        self.assertIn("verify_api_key_coverage", metric_ids)
        self.assertIn("oauth_v2_coverage", metric_ids)

    def test_health_endpoint_dispatch(self) -> None:
        """Test application health route dispatching."""
        status_code, response_payload = self.router.dispatch("GET", "/health")
        self.assertEqual(status_code, 200)
        self.assertEqual(response_payload.get("status"), "OK")
        self.assertEqual(response_payload.get("service"), "api-spr-backend")
        self.assertEqual(response_payload.get("environment"), "local")

    def test_posture_endpoint_dispatch(self) -> None:
        """Test POST `/api/v1/security-posture/assessments` application routing."""
        req_body = {
            "scope": {
                "organization_id": "route-org",
                "environment_id": "eval",
            },
            "page_size": 10,
        }
        status_code, response_payload = self.router.dispatch(
            "POST",
            "/api/v1/security-posture/assessments",
            body=req_body,
        )
        self.assertEqual(status_code, 200)
        self.assertEqual(response_payload.get("overall_score"), 90.0)
        self.assertEqual(response_payload.get("risk_level"), "LOW")
        self.assertIn("results", response_payload)


if __name__ == "__main__":
    unittest.main()
