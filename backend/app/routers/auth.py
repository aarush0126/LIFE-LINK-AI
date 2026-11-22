from datetime import UTC, datetime, timedelta

import jwt
from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select, update
from sqlalchemy.orm import Session, joinedload

from app.audit import record_audit
from app.config import Settings
from app.db import get_db
from app.dependencies import get_current_user, get_settings
from app.domain import RoleName
from app.models import Institution, RefreshSession, Role, User
from app.presenters import present_user
from app.schemas import (
    RegistrationInput,
    RegistrationResponse,
    TokenRequest,
    TokenResponse,
    UserPublic,
)
from app.security import create_token, decode_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["Authentication"])


def _unauthorized() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail={
            "code": "invalid_credentials",
            "message": "Email or password is invalid, or the account is not active.",
        },
        headers={"WWW-Authenticate": "Bearer"},
    )


def _issue_tokens(
    session: Session,
    user: User,
    settings: Settings,
) -> dict[str, object]:
    access_token, _, _ = create_token(
        subject=user.id,
        token_type="access",
        expires_delta=timedelta(minutes=settings.access_token_minutes),
        settings=settings,
    )
    refresh_token, refresh_jti, refresh_expiration = create_token(
        subject=user.id,
        token_type="refresh",
        expires_delta=timedelta(days=settings.refresh_token_days),
        settings=settings,
    )
    session.add(
        RefreshSession(
            user_id=user.id,
            token_jti=refresh_jti,
            expires_at=refresh_expiration,
        )
    )
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "expires_in": settings.access_token_minutes * 60,
        "user": present_user(user),
    }


@router.post(
    "/register",
    response_model=RegistrationResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
def register(
    body: RegistrationInput,
    request: Request,
    session: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict[str, object]:
    if not settings.allow_self_registration:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "registration_disabled",
                "message": "Self-registration is disabled for this environment.",
            },
        )
    institution = session.get(Institution, body.institution_id)
    if institution is None or not institution.is_active:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "code": "invalid_institution",
                "message": "Select an active institution from the registry.",
            },
        )
    role = session.scalar(select(Role).where(Role.name == RoleName.PENDING_REVIEW.value))
    if role is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "code": "roles_not_seeded",
                "message": "The service is not ready to accept registrations.",
            },
        )
    normalized_email = str(body.email).strip().lower()
    if session.scalar(select(User.id).where(User.email == normalized_email)) is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "account_conflict",
                "message": "An account with this email already exists.",
            },
        )
    user = User(
        email=normalized_email,
        full_name=body.full_name.strip(),
        department=body.department.strip(),
        password_hash=hash_password(body.password),
        institution_id=institution.id,
        role_id=role.id,
        is_active=False,
        is_verified=False,
    )
    session.add(user)
    session.flush()
    record_audit(
        session,
        request,
        action="registration_requested",
        entity_type="user",
        entity_id=str(user.id),
        metadata={"role": role.name, "institution_id": institution.id},
    )
    session.commit()
    return {
        "message": "Registration submitted for authorized institutional review.",
        "user_id": user.id,
        "status": "pending_review",
    }


@router.post("/token", response_model=TokenResponse)
def create_session(
    request: Request,
    credentials: OAuth2PasswordRequestForm = Depends(),
    session: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict[str, object]:
    email = credentials.username.strip().lower()
    user = session.scalar(
        select(User)
        .options(joinedload(User.role), joinedload(User.institution))
        .where(User.email == email)
    )
    if (
        user is None
        or not verify_password(credentials.password, user.password_hash)
        or not user.is_active
        or not user.is_verified
    ):
        raise _unauthorized()
    tokens = _issue_tokens(session, user, settings)
    record_audit(
        session,
        request,
        actor=user,
        action="session_created",
        entity_type="user",
        entity_id=str(user.id),
    )
    session.commit()
    return tokens


@router.post("/refresh", response_model=TokenResponse)
def refresh_session(
    body: TokenRequest,
    session: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict[str, object]:
    try:
        payload = decode_token(body.refresh_token, settings)
        if payload.get("type") != "refresh":
            raise _unauthorized()
        user_id = int(str(payload["sub"]))
        token_jti = str(payload["jti"])
    except (jwt.InvalidTokenError, KeyError, TypeError, ValueError):
        raise _unauthorized() from None

    user = session.scalar(
        select(User)
        .options(joinedload(User.role), joinedload(User.institution))
        .where(User.id == user_id)
    )
    if user is None or not user.is_active or not user.is_verified:
        raise _unauthorized()

    now = datetime.now(UTC)
    result = session.execute(
        update(RefreshSession)
        .where(
            RefreshSession.token_jti == token_jti,
            RefreshSession.user_id == user_id,
            RefreshSession.revoked_at.is_(None),
        )
        .values(revoked_at=now)
    )
    if result.rowcount != 1:
        session.rollback()
        raise _unauthorized()
    tokens = _issue_tokens(session, user, settings)
    session.commit()
    return tokens


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(
    request: Request,
    body: TokenRequest | None = None,
    session: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Response:
    if body is not None:
        try:
            payload = decode_token(body.refresh_token, request.app.state.settings)
        except jwt.InvalidTokenError:
            raise _unauthorized() from None
        if payload.get("type") != "refresh" or str(payload.get("sub")) != str(user.id):
            raise _unauthorized()
        token_jti = str(payload["jti"])
        session.execute(
            update(RefreshSession)
            .where(
                RefreshSession.token_jti == token_jti,
                RefreshSession.user_id == user.id,
                RefreshSession.revoked_at.is_(None),
            )
            .values(revoked_at=datetime.now(UTC))
        )
    record_audit(
        session,
        request,
        actor=user,
        action="session_ended",
        entity_type="user",
        entity_id=str(user.id),
    )
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/me", response_model=UserPublic)
def get_profile(user: User = Depends(get_current_user)) -> dict[str, object]:
    return present_user(user)
