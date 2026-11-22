from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_ROOT = Path(__file__).resolve().parents[1]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BACKEND_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    app_name: str = "LIFE-LINK AI API"
    app_env: Literal["development", "test", "staging", "production"] = "development"
    database_url: str | None = None
    jwt_secret_key: SecretStr | None = None
    jwt_algorithm: Literal["HS256"] = "HS256"
    access_token_minutes: int = 10
    refresh_token_days: int = 7
    allow_self_registration: bool = False
    cors_origins: list[str] = [
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:8080",
        "http://localhost:8765",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:8765",
    ]

    def validate_runtime(self) -> None:
        if not self.database_url:
            raise RuntimeError("DATABASE_URL must be configured before starting the API.")
        if not self.jwt_secret_key:
            raise RuntimeError("JWT_SECRET_KEY must be configured before starting the API.")
        if len(self.jwt_secret_key.get_secret_value()) < 32:
            raise RuntimeError("JWT_SECRET_KEY must contain at least 32 characters.")
        if self.app_env == "production" and not self.database_url.startswith(
            "postgresql+psycopg://"
        ):
            raise RuntimeError("Production deployments require PostgreSQL.")

    @property
    def signing_key(self) -> str:
        self.validate_runtime()
        if self.jwt_secret_key is None:
            raise RuntimeError("JWT_SECRET_KEY must be configured before signing tokens.")
        return self.jwt_secret_key.get_secret_value()


@lru_cache
def get_settings() -> Settings:
    return Settings()
