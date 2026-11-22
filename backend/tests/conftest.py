from collections.abc import Iterator
from dataclasses import dataclass

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import create_engine, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.config import Settings
from app.db import create_session_factory
from app.domain import RoleName
from app.main import create_app
from app.models import Base, Institution, Role, User
from app.security import hash_password
from app.seed import seed_synthetic_data

TEST_PASSWORD = "StrongDemoPassword123!"


@dataclass
class APIContext:
    client: TestClient
    institution_ids: dict[str, int]
    user_emails: dict[str, str]
    engine: Engine


def _create_user(
    session: Session,
    *,
    email: str,
    role_name: RoleName,
    institution_code: str,
) -> User:
    role = session.scalar(select(Role).where(Role.name == role_name.value))
    institution = session.scalar(
        select(Institution).where(Institution.institution_code == institution_code)
    )
    assert role is not None
    assert institution is not None
    user = User(
        email=email,
        full_name=email.split("@", maxsplit=1)[0].replace(".", " ").title(),
        department="Synthetic test account",
        password_hash=hash_password(TEST_PASSWORD),
        institution_id=institution.id,
        role_id=role.id,
        is_active=True,
        is_verified=True,
    )
    session.add(user)
    session.flush()
    return user


@pytest.fixture
def api_context() -> Iterator[APIContext]:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    factory = create_session_factory(engine)
    seed_synthetic_data(factory)
    with factory.begin() as session:
        institutions = {
            institution.institution_code: institution.id
            for institution in session.scalars(select(Institution)).all()
        }
        _create_user(
            session,
            email="network.admin@example.com",
            role_name=RoleName.NETWORK_ADMINISTRATOR,
            institution_code="DEMO-NETWORK",
        )
        _create_user(
            session,
            email="transplant.coordinator@example.com",
            role_name=RoleName.TRANSPLANT_COORDINATOR,
            institution_code="DEMO-HN-1001",
        )
        _create_user(
            session,
            email="blood.officer@example.com",
            role_name=RoleName.BLOOD_BANK_OFFICER,
            institution_code="DEMO-HN-1003",
        )
        _create_user(
            session,
            email="hospital.admin@example.com",
            role_name=RoleName.HOSPITAL_ADMINISTRATOR,
            institution_code="DEMO-HN-1001",
        )

    settings = Settings(
        app_env="test",
        database_url="sqlite://",
        jwt_secret_key=SecretStr("test-only-secret-key-with-at-least-32-chars"),
    )
    app = create_app(settings=settings, session_factory=factory)
    with TestClient(app) as client:
        yield APIContext(
            client=client,
            institution_ids=institutions,
            user_emails={
                "admin": "network.admin@example.com",
                "transplant": "transplant.coordinator@example.com",
                "blood": "blood.officer@example.com",
                "hospital": "hospital.admin@example.com",
            },
            engine=engine,
        )
    engine.dispose()


def sign_in(client: TestClient, email: str) -> tuple[str, str]:
    response = client.post(
        "/api/v1/auth/token",
        data={"username": email, "password": TEST_PASSWORD},
    )
    assert response.status_code == 200
    body = response.json()
    return body["access_token"], body["refresh_token"]


def auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}
