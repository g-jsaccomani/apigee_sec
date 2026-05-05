"""
Main application exposing REST routes for API Security Posture Review (API-SPR) backend.
Exposes endpoints using FastAPI/Starlette async patterns when available, with a lightweight
fallback router for standalone testing and minimal environments.
"""

from typing import Any, Dict, Optional, Tuple
from backend.config import Config, get_config
from backend.models.posture_models import BatchComputePostureRequest
from backend.services.posture_service import PostureService
from backend.services.abuse_detection_service import AbuseDetectionService

try:
    from fastapi import FastAPI, HTTPException, status
    from fastapi.responses import JSONResponse
    FASTAPI_AVAILABLE = True
except ImportError:
    FASTAPI_AVAILABLE = False


class ApplicationRouter:
    """
    Core application logic and request dispatching for API Security Posture Review routes.
    """

    def __init__(self, config: Optional[Config] = None) -> None:
        self.config: Config = config or get_config()
        self.posture_service = PostureService(config=self.config)
        self.abuse_service = AbuseDetectionService(config=self.config)

    def handle_health(self) -> Tuple[int, Dict[str, Any]]:
        """
        Handle GET `/health`.
        """
        return 200, {
            "status": "OK",
            "service": "api-spr-backend",
            "environment": self.config.ANTIGRAVITY_ENV,
            "version": "1.0.0",
        }

    def handle_posture_assessment(
        self, body: Optional[Dict[str, Any]] = None
    ) -> Tuple[int, Dict[str, Any]]:
        """
        Handle POST `/api/v1/security-posture/assessments`.
        """
        payload = body or {}
        try:
            req_model = BatchComputePostureRequest.from_dict(payload)
            res_model = self.posture_service.compute_posture_assessment(req_model)
            return 200, res_model.to_dict()
        except Exception as exc:
            return 500, {"error": f"Failed to compute posture assessment: {exc}"}

    def handle_active_incidents(
        self, params: Optional[Dict[str, Any]] = None
    ) -> Tuple[int, Dict[str, Any]]:
        """
        Handle GET `/api/v1/security-incidents/active`.
        """
        params = params or {}
        try:
            environment = params.get("environment", self.config.APIGEE_ENV)
            status_filter = params.get("status")
            limit = int(params.get("limit", 100))
            page_token = params.get("page_token")

            res_model = self.abuse_service.get_active_incidents(
                environment=environment,
                status=status_filter,
                limit=limit,
                page_token=page_token,
            )
            return 200, res_model.to_dict()
        except Exception as exc:
            return 500, {"error": f"Failed to retrieve active incidents: {exc}"}

    def dispatch(
        self,
        method: str,
        path: str,
        body: Optional[Dict[str, Any]] = None,
        params: Optional[Dict[str, Any]] = None,
    ) -> Tuple[int, Dict[str, Any]]:
        """
        Dispatch an HTTP method and path to the corresponding route handler.
        """
        normalized_path = path.rstrip("/")
        if method.upper() == "GET" and normalized_path == "/health":
            return self.handle_health()
        elif method.upper() == "POST" and normalized_path == "/api/v1/security-posture/assessments":
            return self.handle_posture_assessment(body=body)
        elif method.upper() == "GET" and normalized_path == "/api/v1/security-incidents/active":
            return self.handle_active_incidents(params=params)

        return 404, {"error": "Endpoint not found"}


def create_app(config: Optional[Config] = None) -> Any:
    """
    Factory function returning an application instance.
    Returns a FastAPI app instance if installed, otherwise returns an ApplicationRouter instance.
    """
    router = ApplicationRouter(config=config)

    if not FASTAPI_AVAILABLE:
        return router

    app = FastAPI(
        title="API Security Posture Review (API-SPR) Backend",
        version="1.0.0",
        description="Backend API for Apigee Advanced API Security posture evaluations and incident monitoring.",
    )

    @app.get("/health")
    async def health_endpoint() -> JSONResponse:
        code, payload = router.handle_health()
        return JSONResponse(status_code=code, content=payload)

    @app.post("/api/v1/security-posture/assessments")
    async def assessments_endpoint(payload: Dict[str, Any]) -> JSONResponse:
        code, resp_data = router.handle_posture_assessment(body=payload)
        return JSONResponse(status_code=code, content=resp_data)

    @app.get("/api/v1/security-incidents/active")
    async def incidents_endpoint(
        environment: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 100,
        page_token: Optional[str] = None,
    ) -> JSONResponse:
        params = {
            "environment": environment,
            "status": status,
            "limit": limit,
            "page_token": page_token,
        }
        code, resp_data = router.handle_active_incidents(params=params)
        return JSONResponse(status_code=code, content=resp_data)

    # Attach router for direct testing if needed
    app.state.router = router  # type: ignore

    return app


# Default application instance
app = create_app()
