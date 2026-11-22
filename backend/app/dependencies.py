from __future__ import annotations

from collections.abc import Callable

import jwt
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.config import Settings
from app.db import get_db
from app.models import User
from app.security import decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")


def get_settings(request: Request) -> Settings:
    return request.app.state.settings


def get_current_user(
    token: str = Depends(oauth2_scheme),
    session: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> User:
    credentials_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail={"code": "invalid_credentials", "message": "Authentication is required."},
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(token, settings)
        if payload.get("type") != "access":
            raise credentials_error
        user_id = int(str(payload["sub"]))
    except (jwt.InvalidTokenError, KeyError, TypeError, ValueError):
        raise credentials_error from None

    user = session.scalar(
        select(User)
        .options(joinedload(User.role), joinedload(User.institution))
        .where(User.id == user_id)
    )
    if user is None or not user.is_active or not user.is_verified:
        raise credentials_error
    return user


def require_permission(permission: str) -> Callable[..., User]:
    def permission_dependency(
        user: User = Depends(get_current_user),
    ) -> User:
        if permission not in user.role.permissions:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "code": "permission_denied",
                    "message": "Your assigned role does not permit this action.",
                },
            )
        return user

    return permission_dependency


def require_roles(*roles: str) -> Callable[..., User]:
    def role_dependency(
        user: User = Depends(get_current_user),
    ) -> User:
        if user.role.name not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "code": "permission_denied",
                    "message": "Your assigned role does not permit this action.",
                },
            )
        return user

    return role_dependency
