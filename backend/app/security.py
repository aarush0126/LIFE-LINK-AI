from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import jwt
from pwdlib import PasswordHash
from pwdlib.exceptions import HashVerificationError, UnknownHashError

from app.config import Settings

_password_hasher = PasswordHash.recommended()
TOKEN_ISSUER = "life-link-ai-api"
TOKEN_AUDIENCE = "life-link-ai-client"


def hash_password(password: str) -> str:
    return _password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return _password_hasher.verify(password, password_hash)
    except (HashVerificationError, UnknownHashError):
        return False


def create_token(
    *,
    subject: int,
    token_type: str,
    expires_delta: timedelta,
    settings: Settings,
) -> tuple[str, str, datetime]:
    now = datetime.now(UTC)
    expires_at = now + expires_delta
    token_id = str(uuid4())
    payload = {
        "sub": str(subject),
        "type": token_type,
        "jti": token_id,
        "iat": now,
        "exp": expires_at,
        "iss": TOKEN_ISSUER,
        "aud": TOKEN_AUDIENCE,
    }
    token = jwt.encode(payload, settings.signing_key, algorithm=settings.jwt_algorithm)
    return token, token_id, expires_at


def decode_token(token: str, settings: Settings) -> dict[str, object]:
    return jwt.decode(
        token,
        settings.signing_key,
        algorithms=[settings.jwt_algorithm],
        audience=TOKEN_AUDIENCE,
        issuer=TOKEN_ISSUER,
        options={"require": ["exp", "iat", "sub", "jti", "type"]},
    )


def utc_datetime(value: datetime) -> datetime:
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)
