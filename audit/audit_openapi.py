"""
API Security Posture Review (API-SPR) - OpenAPI Specification Audit CLI.

CLI tool to evaluate OpenAPI 3.0/3.1 specifications (.yaml/.json) against
enterprise API security and cataloging rules.
"""

import argparse
import json
import os
import sys
from typing import Any, Dict, List, Optional

import yaml

from audit.rules import OpenAPIRuleEngine, RuleResult


def load_spec(filepath: str) -> Dict[str, Any]:
    """
    Loads and parses an OpenAPI specification file (.yaml, .yml, or .json).
    """
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Specification file not found: '{filepath}'")

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Try YAML safe_load first (which also supports JSON syntax)
    try:
        data = yaml.safe_load(content)
        if isinstance(data, dict):
            return data
    except Exception as yaml_err:
        # Fallback to json.loads if YAML parsing fails
        try:
            data = json.loads(content)
            if isinstance(data, dict):
                return data
        except Exception:
            raise ValueError(
                f"Failed to parse specification file '{filepath}' as YAML or JSON: {yaml_err}"
            )

    raise ValueError(f"Specification file '{filepath}' did not parse into a dictionary.")


def format_text_report(spec_path: str, results: List[RuleResult]) -> str:
    """
    Formats rule evaluation results as a clean ASCII text report.
    """
    all_passed = all(r.passed for r in results)
    status_str = "PASS" if all_passed else "FAIL"
    lines = [
        "=" * 80,
        "API Security Posture Review (API-SPR) - OpenAPI Audit Report",
        "=" * 80,
        f"Specification File: {spec_path}",
        f"Overall Status:     {status_str}",
        "-" * 80,
        "Rule Evaluation Results:",
    ]
    for r in results:
        badge = "[PASS]" if r.passed else "[FAIL]"
        lines.append(f"{badge} {r.rule_id}: {r.name}")
        lines.append(f"       Message: {r.message}")
        if r.details:
            lines.append("       Details:")
            for item in r.details:
                lines.append(f"         - {item}")
        lines.append("-" * 80)
    lines.append("=" * 80)
    return "\n".join(lines)


def format_markdown_report(spec_path: str, results: List[RuleResult]) -> str:
    """
    Formats rule evaluation results as a clean GitHub-style Markdown report.
    """
    all_passed = all(r.passed for r in results)
    status_str = "**PASS**" if all_passed else "**FAIL**"
    lines = [
        "# API Security Posture Review (API-SPR) - OpenAPI Audit Report",
        "",
        f"- **Specification:** `{spec_path}`",
        f"- **Overall Status:** {status_str}",
        "",
        "## Audit Rules Summary",
        "",
        "| Rule ID | Rule Name | Status | Message | Details |",
        "|---|---|---|---|---|",
    ]
    for r in results:
        status_badge = "PASS" if r.passed else "FAIL"
        details_str = "; ".join(r.details) if r.details else "-"
        lines.append(
            f"| `{r.rule_id}` | {r.name} | **{status_badge}** | {r.message} | {details_str} |"
        )
    return "\n".join(lines)


def format_json_report(spec_path: str, results: List[RuleResult]) -> str:
    """
    Formats rule evaluation results as a structured JSON object.
    """
    all_passed = all(r.passed for r in results)
    report = {
        "specification": spec_path,
        "overall_status": "PASS" if all_passed else "FAIL",
        "all_passed": all_passed,
        "rules": [r.to_dict() for r in results],
    }
    return json.dumps(report, indent=2)


def main(argv: Optional[List[str]] = None) -> int:
    """
    Main entrypoint for the OpenAPI audit CLI script.
    """
    parser = argparse.ArgumentParser(
        description="OpenAPI Auditing Suite for API Security Posture Review (API-SPR)."
    )
    parser.add_argument(
        "--spec",
        required=True,
        help="Path to the OpenAPI specification file (.yaml, .yml, .json).",
    )
    parser.add_argument(
        "--format",
        choices=["text", "markdown", "json"],
        default="text",
        help="Output format for the audit report (default: text).",
    )
    parser.add_argument(
        "--expect-failure",
        action="store_true",
        help="Invert exit code expectation for testing negative cases (exits 0 if audit fails, 1 if audit passes).",
    )

    args = parser.parse_args(argv)

    try:
        spec_data = load_spec(args.spec)
    except Exception as e:
        print(f"Error loading specification: {e}", file=sys.stderr)
        return 2

    results = OpenAPIRuleEngine.evaluate(spec_data)
    all_passed = all(r.passed for r in results)

    if args.format == "json":
        print(format_json_report(args.spec, results))
    elif args.format == "markdown":
        print(format_markdown_report(args.spec, results))
    else:
        print(format_text_report(args.spec, results))

    if args.expect_failure:
        return 0 if not all_passed else 1

    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
