"""
Service implementing Apigee Advanced API Security posture assessment batch computation.
"""

from typing import Optional
from backend.config import Config, get_config
from backend.models.posture_models import (
    BatchComputePostureRequest,
    BatchComputePostureResponse,
)
from backend.services.apigee_client import ApigeeClient


class PostureService:
    """
    Manages security posture assessment requests against Google Cloud Apigee APIs.
    """

    def __init__(
        self,
        client: Optional[ApigeeClient] = None,
        config: Optional[Config] = None,
    ) -> None:
        self.config: Config = config or get_config()
        self.client: ApigeeClient = client or ApigeeClient(config=self.config)

    def compute_posture_assessment(
        self,
        request: BatchComputePostureRequest,
    ) -> BatchComputePostureResponse:
        """
        Execute POST `/securityAssessmentResults:batchCompute` for the configured scope.

        In local mode (`ANTIGRAVITY_ENV=local`), returns realistic mock posture evaluation scores (0-100%).
        """
        org_id = request.scope.organization_id or self.config.APIGEE_ORG_ID
        env_id = request.scope.environment_id or self.config.APIGEE_ENV

        endpoint_url = (
            f"{self.config.APIGEE_BASE_URL}/organizations/{org_id}/"
            f"environments/{env_id}/securityAssessmentResults:batchCompute"
        )

        payload = request.to_dict()
        response_data = self.client.post(endpoint_url, json_payload=payload)

        return BatchComputePostureResponse.from_dict(response_data)
