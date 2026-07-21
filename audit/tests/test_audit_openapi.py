"""
Unit tests for the OpenAPI Auditing Suite (API Security Posture Review - API-SPR).
"""

import json
import os
import tempfile
import unittest
from io import StringIO
from unittest.mock import patch

from audit.audit_openapi import (
    format_json_report,
    format_markdown_report,
    format_text_report,
    load_spec,
    main,
)
from audit.rules import (
    OpenAPIRuleEngine,
    check_hub_001_api_hub_cataloging,
    check_sec_001_declared_security_schemes,
    check_sec_002_applied_security,
)


class TestHUB001APIHubCataloging(unittest.TestCase):
    """
    Tests for Rule HUB-001: Enterprise API Hub cataloging metadata.
    """

    def test_valid_x_api_hub_category(self):
        spec = {"info": {"title": "Test API", "x-api-hub-category": "Financial Services"}}
        res = check_hub_001_api_hub_cataloging(spec)
        self.assertTrue(res.passed)
        self.assertEqual(res.rule_id, "HUB-001")
        self.assertIn("info.x-api-hub-category", res.details[0])

    def test_valid_x_apigee_category(self):
        spec = {"info": {"title": "Test API", "x-apigee-category": "Payments"}}
        res = check_hub_001_api_hub_cataloging(spec)
        self.assertTrue(res.passed)
        self.assertIn("info.x-apigee-category", res.details[0])

    def test_valid_info_tags(self):
        spec = {"info": {"title": "Test API", "tags": ["Enterprise", "Internal"]}}
        res = check_hub_001_api_hub_cataloging(spec)
        self.assertTrue(res.passed)

    def test_valid_root_tags(self):
        spec = {
            "info": {"title": "Test API"},
            "tags": [{"name": "Payments", "description": "Payment operations"}],
        }
        res = check_hub_001_api_hub_cataloging(spec)
        self.assertTrue(res.passed)
        self.assertIn("root.tags", res.details[0])

    def test_missing_cataloging_metadata(self):
        spec = {"info": {"title": "Test API"}}
        res = check_hub_001_api_hub_cataloging(spec)
        self.assertFalse(res.passed)
        self.assertEqual(res.rule_id, "HUB-001")

    def test_missing_info_object(self):
        spec = {}
        res = check_hub_001_api_hub_cataloging(spec)
        self.assertFalse(res.passed)
        self.assertIn("Missing required 'info' root object", res.message)


class TestSEC001DeclaredSecuritySchemes(unittest.TestCase):
    """
    Tests for Rule SEC-001: Declared authentication schemes.
    """

    def test_valid_oauth2_scheme(self):
        spec = {
            "components": {
                "securitySchemes": {
                    "OAuth2": {
                        "type": "oauth2",
                        "flows": {"clientCredentials": {"tokenUrl": "https://auth.example.com/token"}},
                    }
                }
            }
        }
        res = check_sec_001_declared_security_schemes(spec)
        self.assertTrue(res.passed)
        self.assertEqual(res.rule_id, "SEC-001")
        self.assertIn("OAuth2 (oauth2)", res.details[0])

    def test_valid_apikey_scheme(self):
        spec = {
            "components": {
                "securitySchemes": {
                    "ApiKeyAuth": {"type": "apiKey", "in": "header", "name": "X-API-Key"}
                }
            }
        }
        res = check_sec_001_declared_security_schemes(spec)
        self.assertTrue(res.passed)

    def test_valid_oidc_scheme(self):
        spec = {
            "components": {
                "securitySchemes": {
                    "OpenIDConnect": {
                        "type": "openIdConnect",
                        "openIdConnectUrl": "https://idp.example.com/.well-known/openid-configuration",
                    }
                }
            }
        }
        res = check_sec_001_declared_security_schemes(spec)
        self.assertTrue(res.passed)

    def test_valid_legacy_security_definitions(self):
        spec = {
            "securityDefinitions": {
                "LegacyOAuth": {"type": "oauth2", "flow": "application"}
            }
        }
        res = check_sec_001_declared_security_schemes(spec)
        self.assertTrue(res.passed)

    def test_missing_security_schemes(self):
        spec = {"components": {}}
        res = check_sec_001_declared_security_schemes(spec)
        self.assertFalse(res.passed)

    def test_invalid_scheme_type(self):
        spec = {
            "components": {
                "securitySchemes": {
                    "CustomScheme": {"type": "custom_unsupported_auth"}
                }
            }
        }
        res = check_sec_001_declared_security_schemes(spec)
        self.assertFalse(res.passed)


class TestSEC002AppliedSecurity(unittest.TestCase):
    """
    Tests for Rule SEC-002: Applied security and shadow endpoint detection.
    """

    def test_global_security_applied(self):
        spec = {
            "security": [{"OAuth2": []}],
            "paths": {
                "/payments": {
                    "get": {"summary": "Get payments"},
                    "post": {"summary": "Create payment"},
                }
            },
        }
        res = check_sec_002_applied_security(spec)
        self.assertTrue(res.passed)
        self.assertEqual(res.rule_id, "SEC-002")

    def test_operation_level_security_applied(self):
        spec = {
            "paths": {
                "/payments": {
                    "get": {
                        "summary": "Get payments",
                        "security": [{"ApiKeyAuth": []}],
                    }
                }
            }
        }
        res = check_sec_002_applied_security(spec)
        self.assertTrue(res.passed)

    def test_shadow_endpoint_with_empty_security_array(self):
        spec = {
            "security": [{"OAuth2": []}],
            "paths": {
                "/public/ping": {
                    "get": {
                        "summary": "Shadow unauthenticated endpoint",
                        "security": [],
                    }
                }
            },
        }
        res = check_sec_002_applied_security(spec)
        self.assertFalse(res.passed)
        self.assertIn("shadow/anonymous endpoints", res.message)
        self.assertTrue(any("GET /public/ping" in d for d in res.details))

    def test_missing_global_and_operation_security(self):
        spec = {
            "paths": {
                "/unauthenticated": {
                    "post": {"summary": "Unsecured post operation"}
                }
            }
        }
        res = check_sec_002_applied_security(spec)
        self.assertFalse(res.passed)
        self.assertTrue(any("POST /unauthenticated" in d for d in res.details))

    def test_empty_paths_with_global_security(self):
        spec = {"security": [{"OAuth2": []}], "paths": {}}
        res = check_sec_002_applied_security(spec)
        self.assertTrue(res.passed)


class TestOpenAPIRuleEngine(unittest.TestCase):
    """
    Tests for OpenAPIRuleEngine evaluation.
    """

    def test_evaluate_returns_all_rules(self):
        spec = {
            "info": {"title": "Test API", "x-api-hub-category": "Finance"},
            "components": {"securitySchemes": {"OAuth2": {"type": "oauth2"}}},
            "security": [{"OAuth2": []}],
            "paths": {"/test": {"get": {}}},
        }
        results = OpenAPIRuleEngine.evaluate(spec)
        self.assertEqual(len(results), 3)
        rule_ids = [r.rule_id for r in results]
        self.assertEqual(rule_ids, ["HUB-001", "SEC-001", "SEC-002"])
        self.assertTrue(all(r.passed for r in results))


class TestAuditOpenAPICLI(unittest.TestCase):
    """
    Tests for CLI parser, file loader, and formatters.
    """

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.valid_yaml_path = os.path.join(self.temp_dir.name, "valid.yaml")
        self.valid_json_path = os.path.join(self.temp_dir.name, "valid.json")
        self.invalid_yaml_path = os.path.join(self.temp_dir.name, "invalid.yaml")

        valid_spec = {
            "openapi": "3.0.3",
            "info": {"title": "Valid API", "x-api-hub-category": "Finance"},
            "components": {"securitySchemes": {"OAuth2": {"type": "oauth2"}}},
            "security": [{"OAuth2": []}],
            "paths": {"/test": {"get": {}}},
        }
        invalid_spec = {
            "openapi": "3.0.3",
            "info": {"title": "Shadow API"},
            "paths": {"/test": {"get": {"security": []}}},
        }

        with open(self.valid_yaml_path, "w", encoding="utf-8") as f:
            f.write(
                "openapi: '3.0.3'\n"
                "info:\n"
                "  title: Valid API\n"
                "  x-api-hub-category: Finance\n"
                "components:\n"
                "  securitySchemes:\n"
                "    OAuth2:\n"
                "      type: oauth2\n"
                "security:\n"
                "  - OAuth2: []\n"
                "paths:\n"
                "  /test:\n"
                "    get: {}\n"
            )

        with open(self.valid_json_path, "w", encoding="utf-8") as f:
            json.dump(valid_spec, f)

        with open(self.invalid_yaml_path, "w", encoding="utf-8") as f:
            f.write(
                "openapi: '3.0.3'\n"
                "info:\n"
                "  title: Shadow API\n"
                "paths:\n"
                "  /test:\n"
                "    get:\n"
                "      security: []\n"
            )

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_load_spec_yaml(self):
        data = load_spec(self.valid_yaml_path)
        self.assertIsInstance(data, dict)
        self.assertEqual(data["info"]["x-api-hub-category"], "Finance")

    def test_load_spec_json(self):
        data = load_spec(self.valid_json_path)
        self.assertIsInstance(data, dict)
        self.assertEqual(data["info"]["x-api-hub-category"], "Finance")

    def test_load_spec_not_found(self):
        with self.assertRaises(FileNotFoundError):
            load_spec(os.path.join(self.temp_dir.name, "nonexistent.yaml"))

    def test_format_text_report(self):
        data = load_spec(self.valid_yaml_path)
        results = OpenAPIRuleEngine.evaluate(data)
        text = format_text_report(self.valid_yaml_path, results)
        self.assertIn("Overall Status:     PASS", text)
        self.assertIn("[PASS] HUB-001", text)

    def test_format_markdown_report(self):
        data = load_spec(self.valid_yaml_path)
        results = OpenAPIRuleEngine.evaluate(data)
        md = format_markdown_report(self.valid_yaml_path, results)
        self.assertIn("**Overall Status:** **PASS**", md)
        self.assertIn("| `HUB-001` | API Hub Cataloging | **PASS** |", md)

    def test_format_json_report(self):
        data = load_spec(self.valid_yaml_path)
        results = OpenAPIRuleEngine.evaluate(data)
        raw = format_json_report(self.valid_yaml_path, results)
        parsed = json.loads(raw)
        self.assertTrue(parsed["all_passed"])
        self.assertEqual(len(parsed["rules"]), 3)

    def test_main_cli_valid_spec_returns_0(self):
        with patch("sys.stdout", new=StringIO()):
            code = main(["--spec", self.valid_yaml_path])
            self.assertEqual(code, 0)

    def test_main_cli_invalid_spec_returns_1(self):
        with patch("sys.stdout", new=StringIO()):
            code = main(["--spec", self.invalid_yaml_path])
            self.assertEqual(code, 1)

    def test_main_cli_expect_failure_flag_inverts_code(self):
        with patch("sys.stdout", new=StringIO()):
            code_invalid = main(["--spec", self.invalid_yaml_path, "--expect-failure"])
            self.assertEqual(code_invalid, 0)

            code_valid = main(["--spec", self.valid_yaml_path, "--expect-failure"])
            self.assertEqual(code_valid, 1)

    def test_main_cli_output_formats(self):
        with patch("sys.stdout", new=StringIO()) as fake_out:
            main(["--spec", self.valid_yaml_path, "--format", "json"])
            output = fake_out.getvalue()
            data = json.loads(output)
            self.assertEqual(data["overall_status"], "PASS")


if __name__ == "__main__":
    unittest.main()
