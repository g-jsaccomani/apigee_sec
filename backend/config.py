"""
Configuration loader for API Security Posture Review (API-SPR) backend.

Loads environment variables from OS environment or `.env` file with safe defaults,
and provides helper methods to determine execution mode (e.g. local vs. production).
"""

import os
from pathlib import Path
from typing import Any, Dict


def _load_env_file() -> None:
    """
    Load environment variables from `.env` if present.

    Attempts to use `python-dotenv` if installed. Falls back to a lightweight
    parser that scans the current directory and project root for `.env` files.
    """
    try:
        from dotenv import load_dotenv  # type: ignore
        load_dotenv()
        return
    except ImportError:
        pass

    # Fallback lightweight parser if python-dotenv is not installed
    search_paths = [
        Path.cwd() / ".env",
        Path(__file__).resolve().parent.parent / ".env",
    ]
    for env_path in search_paths:
        if env_path.exists() and env_path.is_file():
            try:
                with open(env_path, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if not line or line.startswith("#") or "=" not in line:
                            continue
                        key, _, value = line.partition("=")
                        key = key.strip()
                        value = value.strip().strip("'\"")
                        if key and key not in os.environ:
                            os.environ[key] = value
                break
            except Exception:
                # Ignore errors reading optional env file
                pass


_load_env_file()


class Config:
    """
    Application configuration values and environment inspection helpers.
    """

    def __init__(self) -> None:
        self.ANTIGRAVITY_ENV: str = os.getenv("ANTIGRAVITY_ENV", "local").strip()
        self.GCP_PROJECT_ID: str = os.getenv("GCP_PROJECT_ID", "your-project-id").strip()
        self.APIGEE_ORG_ID: str = os.getenv("APIGEE_ORG_ID", "your-org-id").strip()
        self.APIGEE_ENV: str = os.getenv("APIGEE_ENV", "eval").strip()
        self.FLAG_DURATION_HOURS: int = int(os.getenv("FLAG_DURATION_HOURS", "72"))
        self.PORT: int = int(os.getenv("PORT", "8080"))
        self.APIGEE_BASE_URL: str = os.getenv(
            "APIGEE_BASE_URL", "https://apigee.googleapis.com/v1"
        ).rstrip("/")

    def is_local_mode(self) -> bool:
        """
        Check if the backend is operating in local execution mode.
        In local mode, services return realistic mock data without making network calls.
        """
        return self.ANTIGRAVITY_ENV.lower() == "local"

    def to_dict(self) -> Dict[str, Any]:
        """
        Serialize configuration to a dictionary representation.
        """
        return {
            "ANTIGRAVITY_ENV": self.ANTIGRAVITY_ENV,
            "GCP_PROJECT_ID": self.GCP_PROJECT_ID,
            "APIGEE_ORG_ID": self.APIGEE_ORG_ID,
            "APIGEE_ENV": self.APIGEE_ENV,
            "FLAG_DURATION_HOURS": self.FLAG_DURATION_HOURS,
            "PORT": self.PORT,
            "APIGEE_BASE_URL": self.APIGEE_BASE_URL,
            "is_local_mode": self.is_local_mode(),
        }


def get_config() -> Config:
    """
    Retrieve a new Config instance loaded from the current environment.
    """
    return Config()


# Default configuration singleton
config = get_config()
