"""
API Security Posture Review (API-SPR) - OpenAPI Auditing Rule Engine.

Implements automated audit rules for OpenAPI 3.0/3.1 specifications:
  - HUB-001: API Hub Cataloging metadata check.
  - SEC-001: Declared Security Schemes check (OAuth2, OIDC, API Key).
  - SEC-002: Applied Security check (global or operation-level security).
"""

from dataclasses import dataclass, field
from typing import Any, Dict, List


@dataclass
class RuleResult:
    """
    Represents the evaluation result of a single audit rule.
    """

    rule_id: str
    name: str
    passed: bool
    message: str
    details: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        """
        Serializes the rule evaluation result into a JSON-serializable dictionary.
        """
        return {
            "rule_id": self.rule_id,
            "name": self.name,
            "passed": self.passed,
            "message": self.message,
            "details": self.details,
        }


def check_hub_001_api_hub_cataloging(spec: Dict[str, Any]) -> RuleResult:
    """
    Rule HUB-001 (API Hub Cataloging):
    Verifies the specification has 'x-api-hub-category' (or 'x-apigee-category' / 'tags')
    in the root 'info' object for enterprise cataloging.
    """
    info = spec.get("info")
    if not isinstance(info, dict):
        return RuleResult(
            rule_id="HUB-001",
            name="API Hub Cataloging",
            passed=False,
            message="Missing required 'info' root object in OpenAPI specification.",
            details=[],
        )

    found_keys: List[str] = []
    if info.get("x-api-hub-category"):
        found_keys.append("info.x-api-hub-category")
    if info.get("x-apigee-category"):
        found_keys.append("info.x-apigee-category")
    if info.get("tags"):
        found_keys.append("info.tags")
    # Also support root-level tags array for enterprise cataloging compatibility
    root_tags = spec.get("tags")
    if root_tags and isinstance(root_tags, list) and len(root_tags) > 0:
        found_keys.append("root.tags")

    if found_keys:
        return RuleResult(
            rule_id="HUB-001",
            name="API Hub Cataloging",
            passed=True,
            message="Enterprise cataloging metadata is present.",
            details=[f"Found cataloging metadata: {', '.join(found_keys)}"],
        )

    return RuleResult(
        rule_id="HUB-001",
        name="API Hub Cataloging",
        passed=False,
        message="Missing required enterprise cataloging metadata in root info object (expected 'x-api-hub-category', 'x-apigee-category', or 'tags').",
        details=["Checked keys: info.x-api-hub-category, info.x-apigee-category, info.tags, root tags"],
    )


def check_sec_001_declared_security_schemes(spec: Dict[str, Any]) -> RuleResult:
    """
    Rule SEC-001 (Declared Security Schemes):
    Verifies components.securitySchemes (or securityDefinitions) explicitly declares
    OAuth2, OIDC, or API Key authentication schemes.
    """
    security_schemes: Dict[str, Any] = {}
    components = spec.get("components")
    if isinstance(components, dict):
        schemes = components.get("securitySchemes")
        if isinstance(schemes, dict):
            security_schemes.update(schemes)

    # Legacy Swagger 2.0 / mixed spec support
    legacy_schemes = spec.get("securityDefinitions")
    if isinstance(legacy_schemes, dict):
        security_schemes.update(legacy_schemes)

    if not security_schemes:
        return RuleResult(
            rule_id="SEC-001",
            name="Declared Security Schemes",
            passed=False,
            message="No security schemes declared in 'components.securitySchemes' or 'securityDefinitions'.",
            details=[],
        )

    valid_schemes_found: List[str] = []
    invalid_schemes: List[str] = []

    for name, scheme_def in security_schemes.items():
        if not isinstance(scheme_def, dict):
            invalid_schemes.append(str(name))
            continue

        scheme_type = str(scheme_def.get("type", "")).lower()
        http_scheme = str(scheme_def.get("scheme", "")).lower()

        is_oauth2 = scheme_type == "oauth2"
        is_oidc = scheme_type in ("openidconnect", "open_id_connect", "oidc")
        is_apikey = scheme_type == "apikey"
        is_http_auth = scheme_type == "http" and http_scheme in (
            "bearer",
            "apikey",
            "basic",
            "digest",
            "oauth",
            "openidconnect",
        )
        is_legacy_basic = scheme_type == "basic"

        if is_oauth2 or is_oidc or is_apikey or is_http_auth or is_legacy_basic:
            valid_schemes_found.append(f"{name} ({scheme_type})")
        else:
            invalid_schemes.append(f"{name} ({scheme_type})")

    if valid_schemes_found:
        return RuleResult(
            rule_id="SEC-001",
            name="Declared Security Schemes",
            passed=True,
            message="Explicitly declared OAuth2, OIDC, or API Key security schemes found.",
            details=valid_schemes_found,
        )

    return RuleResult(
        rule_id="SEC-001",
        name="Declared Security Schemes",
        passed=False,
        message="No OAuth2, OIDC, or API Key authentication schemes declared in components.securitySchemes.",
        details=[
            f"Checked schemes: {', '.join(invalid_schemes)}"
            if invalid_schemes
            else "No valid security schemes found."
        ],
    )


def check_sec_002_applied_security(spec: Dict[str, Any]) -> RuleResult:
    """
    Rule SEC-002 (Applied Security):
    Verifies either a global security array is present or every operation
    (GET/POST/PUT/DELETE/etc.) defines a non-empty security array
    (no anonymous/shadow endpoints).
    """
    global_sec = spec.get("security")
    has_global_security = isinstance(global_sec, list) and len(global_sec) > 0

    paths = spec.get("paths", {})
    if not isinstance(paths, dict) or not paths:
        if has_global_security:
            return RuleResult(
                rule_id="SEC-002",
                name="Applied Security",
                passed=True,
                message="Global security array is defined.",
                details=["Global security present; no paths defined in specification."],
            )
        return RuleResult(
            rule_id="SEC-002",
            name="Applied Security",
            passed=False,
            message="No global security array defined and no operations found.",
            details=[],
        )

    http_methods = {"get", "post", "put", "delete", "patch", "options", "head", "trace"}
    unsecured_endpoints: List[str] = []
    secured_endpoints: List[str] = []

    for path_str, path_item in paths.items():
        if not isinstance(path_item, dict):
            continue
        for method, operation in path_item.items():
            if method.lower() not in http_methods:
                continue
            if not isinstance(operation, dict):
                continue

            method_upper = method.upper()
            op_label = f"{method_upper} {path_str}"

            if "security" in operation:
                op_sec = operation.get("security")
                if isinstance(op_sec, list) and len(op_sec) > 0:
                    secured_endpoints.append(f"{op_label} (operation-level security)")
                else:
                    unsecured_endpoints.append(
                        f"{op_label} (explicit empty security array overrides global security)"
                    )
            else:
                if has_global_security:
                    secured_endpoints.append(f"{op_label} (inherited global security)")
                else:
                    unsecured_endpoints.append(
                        f"{op_label} (missing security array and no global security)"
                    )

    if unsecured_endpoints:
        return RuleResult(
            rule_id="SEC-002",
            name="Applied Security",
            passed=False,
            message=f"Found {len(unsecured_endpoints)} unauthenticated operation(s) (shadow/anonymous endpoints).",
            details=unsecured_endpoints,
        )

    return RuleResult(
        rule_id="SEC-002",
        name="Applied Security",
        passed=True,
        message="All operations are secured with an applied security scheme.",
        details=[f"Total secured operations checked: {len(secured_endpoints)}"],
    )


class OpenAPIRuleEngine:
    """
    Rule engine executing OpenAPI security and enterprise cataloging audit rules.
    """

    @staticmethod
    def evaluate(spec: Dict[str, Any]) -> List[RuleResult]:
        """
        Evaluates the specification dictionary against all API-SPR rules.
        """
        return [
            check_hub_001_api_hub_cataloging(spec),
            check_sec_001_declared_security_schemes(spec),
            check_sec_002_applied_security(spec),
        ]
