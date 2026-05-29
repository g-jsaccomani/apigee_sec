"""
Service implementing Apigee Advanced API Security incident and abuse detection monitoring.
"""

from typing import Optional
from backend.config import Config, get_config
from backend.models.incident_models import (
    SecurityIncidentsRequest,
    SecurityIncidentsResponse,
)
from backend.services.apigee_client import ApigeeClient


class AbuseDetectionService:
    """
    Retrieves active security incidents and abuse detection reports from Apigee Advanced API Security.
    """

    def __init__(
        self,
        client: Optional[ApigeeClient] = None,
        config: Optional[Config] = None,
    ) -> None:
        self.config: Config = config or get_config()
        self.client: ApigeeClient = client or ApigeeClient(config=self.config)

    def get_active_incidents(
        self,
        environment: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 100,
        page_token: Optional[str] = None,
    ) -> SecurityIncidentsResponse:
        """
        Execute GET `/securityIncidents` for the specified environment.

        In local mode (`ANTIGRAVITY_ENV=local`), returns realistic mock abuse detection reports.
        """
        env_id = environment or self.config.APIGEE_ENV
        org_id = self.config.APIGEE_ORG_ID

        endpoint_url = (
            f"{self.config.APIGEE_BASE_URL}/organizations/{org_id}/"
            f"environments/{env_id}/securityIncidents"
        )

        request_model = SecurityIncidentsRequest(
            environment=env_id,
            status=status,
            limit=limit,
            page_token=page_token,
        )

        params = {
            "environment": request_model.environment,
            "limit": request_model.limit,
        }
        if request_model.status:
            params["status"] = request_model.status
        if request_model.page_token:
            params["page_token"] = request_model.page_token

        response_data = self.client.get(endpoint_url, params=params)

        return SecurityIncidentsResponse.from_dict(response_data)
