"""
Models representing Apigee Advanced API Security abuse detection and security incident reports
for GET `/securityIncidents`.
"""

from typing import List, Optional
from backend.models.base import BaseModel, Field


class SecurityIncidentActor(BaseModel):
    """
    Source telemetry details for the actor triggering a security incident.
    Preserves X-Forwarded-For (XFF) header IPs for accurate telemetry.
    """
    ip_address: str = Field(default="0.0.0.0")
    user_agent: Optional[str] = Field(default=None)
    region: Optional[str] = Field(default=None)


class SecurityIncident(BaseModel):
    """
    Represents an active or historical security incident detected by Apigee Advanced API Security
    and Google Cloud Armor.
    """
    incident_id: str = Field(default="")
    environment: str = Field(default="eval")
    proxy_name: str = Field(default="")
    incident_type: str = Field(default="ABUSE_DETECTION")
    severity: str = Field(default="MEDIUM")
    status: str = Field(default="ACTIVE")
    actor: SecurityIncidentActor = Field(default_factory=SecurityIncidentActor)
    enforcement_mode: str = Field(default="FLAG")
    first_observed: str = Field(default="")
    last_observed: str = Field(default="")
    event_count: int = Field(default=1)
    description: str = Field(default="")


class SecurityIncidentsRequest(BaseModel):
    """
    Request filter parameters for GET `/securityIncidents`.
    """
    environment: str = Field(default="eval")
    status: Optional[str] = Field(default=None)
    limit: int = Field(default=100)
    page_token: Optional[str] = Field(default=None)


class SecurityIncidentsResponse(BaseModel):
    """
    Response payload for GET `/securityIncidents`.
    """
    incidents: List[SecurityIncident] = Field(default_factory=list)
    total_count: int = Field(default=0)
    next_page_token: Optional[str] = Field(default=None)
