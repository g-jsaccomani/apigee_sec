"""
Models representing Apigee Advanced API Security posture assessment requests and responses
for `/securityAssessmentResults:batchCompute`.
"""

from typing import List, Optional
from backend.models.base import BaseModel, Field


class AssessmentScope(BaseModel):
    """
    Defines the organization, environment, and proxy scope for security posture evaluation.
    """
    organization_id: str = Field(default="your-org-id")
    environment_id: str = Field(default="eval")
    proxy_names: Optional[List[str]] = Field(default_factory=list)


class PostureAssessmentMetric(BaseModel):
    """
    Individual security metric evaluation result within an assessment.
    """
    metric_id: str = Field(default="")
    category: str = Field(default="authentication")
    score: float = Field(default=0.0)
    status: str = Field(default="PASS")
    description: str = Field(default="")


class PostureAssessmentResult(BaseModel):
    """
    Comprehensive posture assessment result for a target resource.
    """
    assessment_id: str = Field(default="")
    target_resource: str = Field(default="")
    overall_score: float = Field(default=100.0)
    risk_level: str = Field(default="LOW")
    metrics: List[PostureAssessmentMetric] = Field(default_factory=list)
    assessed_at: str = Field(default="")


class BatchComputePostureRequest(BaseModel):
    """
    Request body for POST `/securityAssessmentResults:batchCompute`.
    """
    scope: AssessmentScope = Field(default_factory=AssessmentScope)
    page_size: int = Field(default=50)
    page_token: Optional[str] = Field(default=None)
    include_details: bool = Field(default=True)


class BatchComputePostureResponse(BaseModel):
    """
    Response body from POST `/securityAssessmentResults:batchCompute`.
    """
    results: List[PostureAssessmentResult] = Field(default_factory=list)
    overall_score: float = Field(default=100.0)
    risk_level: str = Field(default="LOW")
    next_page_token: Optional[str] = Field(default=None)
