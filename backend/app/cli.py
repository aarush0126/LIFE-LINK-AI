from __future__ import annotations

import argparse
import getpass
import re
import sys
from uuid import uuid4

from pydantic import EmailStr, TypeAdapter, ValidationError
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.config import get_settings
from app.db import create_database_engine, create_session_factory
from app.domain import RoleName
from app.models import AuditEvent, Institution, Role, User
from app.schemas import InstitutionCreate
from app.security import hash_password
from app.seed import seed_roles, seed_synthetic_data


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="LIFE-LINK AI API administration")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("seed", help="Insert fictional institutions and resources.")
    commands.add_parser("seed-roles", help="Insert or update the system role catalog only.")
    institution = commands.add_parser(
        "create-institution",
        help="Create the initial, unverified institution record for administrator bootstrap.",
    )
    institution.add_argument("--code", required=True)
    institution.add_argument("--name", required=True)
    institution.add_argument("--institution-type", required=True)
    institution.add_argument("--city", required=True)
    institution.add_argument("--state", required=True)
    admin = commands.add_parser(
        "create-admin",
        help="Interactively provision the first network administrator.",
    )
    admin.add_argument("--email", required=True)
    admin.add_argument("--institution-code", default="DEMO-NETWORK")
    return parser.parse_args()


def _read_password() -> str:
    while True:
        password = getpass.getpass("Administrator password (12+ chars): ")
        confirmation = getpass.getpass("Confirm password: ")
        if password != confirmation:
            print("Passwords did not match.", file=sys.stderr)
            continue
        if len(password) < 12 or len(password) > 128:
            print("Password must contain 12–128 characters.", file=sys.stderr)
            continue
        if not (
            re.search(r"[a-z]", password)
            and re.search(r"[A-Z]", password)
            and re.search(r"\d", password)
            and re.search(r"[^\w]", password)
        ):
            print(
                "Password must include lowercase, uppercase, numeric, and symbol characters.",
                file=sys.stderr,
            )
            continue
        return password


def _create_admin(session: Session, email: str, institution_code: str) -> None:
    try:
        normalized_email = str(TypeAdapter(EmailStr).validate_python(email)).lower()
    except ValidationError as error:
        raise SystemExit(f"Invalid administrator email: {error}") from None
    institution = session.scalar(
        select(Institution).where(
            Institution.institution_code == institution_code,
            Institution.is_active.is_(True),
        )
    )
    if institution is None:
        raise SystemExit("Institution code is unavailable. Run the synthetic seed command first.")
    existing_admin_count = session.scalar(
        select(func.count(User.id))
        .join(User.role)
        .where(Role.name == RoleName.NETWORK_ADMINISTRATOR.value)
    )
    if existing_admin_count:
        raise SystemExit(
            "A network administrator was already provisioned; "
            "use the approved account provisioning process."
        )
    if session.scalar(select(User.id).where(User.email == normalized_email)) is not None:
        raise SystemExit("An account with this email already exists.")
    role = session.scalar(select(Role).where(Role.name == RoleName.NETWORK_ADMINISTRATOR.value))
    if role is None:
        raise SystemExit("Role catalog is unavailable. Run the synthetic seed command first.")
    name = input("Administrator name: ").strip()
    if len(name) < 2 or len(name) > 160:
        raise SystemExit("Administrator name must contain 2–160 characters.")
    password = _read_password()
    user = User(
        email=normalized_email,
        full_name=name,
        department="Network administration",
        password_hash=hash_password(password),
        institution_id=institution.id,
        role_id=role.id,
        is_active=True,
        is_verified=True,
    )
    session.add(user)
    session.flush()
    session.add(
        AuditEvent(
            actor_user_id=user.id,
            actor_role=role.name,
            institution_id=institution.id,
            action="initial_network_administrator_provisioned",
            entity_type="user",
            entity_id=str(user.id),
            request_id=str(uuid4()),
            event_metadata={"provisioning": "interactive_cli"},
        )
    )
    session.commit()
    print(f"Network administrator account provisioned for {normalized_email}.")


def _create_institution(
    session: Session,
    *,
    code: str,
    name: str,
    institution_type: str,
    city: str,
    state: str,
) -> None:
    try:
        body = InstitutionCreate(
            institution_code=code,
            name=name,
            institution_type=institution_type,
            city=city,
            state=state,
        )
    except ValidationError as error:
        raise SystemExit(f"Invalid institution details: {error}") from None
    if (
        session.scalar(
            select(Institution.id).where(Institution.institution_code == body.institution_code)
        )
        is not None
    ):
        raise SystemExit("An institution with this code already exists.")
    institution = Institution(
        institution_code=body.institution_code,
        name=body.name.strip(),
        institution_type=body.institution_type.strip(),
        city=body.city.strip(),
        state=body.state.strip(),
        is_verified=False,
        is_active=True,
        is_demo=False,
    )
    session.add(institution)
    session.flush()
    session.add(
        AuditEvent(
            actor_role="system",
            institution_id=institution.id,
            action="institution_bootstrapped",
            entity_type="institution",
            entity_id=str(institution.id),
            request_id=str(uuid4()),
            event_metadata={"is_demo": False, "is_verified": False},
        )
    )
    session.commit()
    print(
        f"Institution {institution.institution_code} created as unverified. "
        "Complete institutional verification before operational use."
    )


def main() -> None:
    args = _parse_args()
    settings = get_settings()
    engine = create_database_engine(settings)
    factory = create_session_factory(engine)
    try:
        if args.command == "seed":
            if settings.app_env == "production":
                raise SystemExit("Synthetic demo data seeding is disabled in production.")
            seed_synthetic_data(factory)
            print("Synthetic LIFE-LINK AI reference data seeded.")
        elif args.command == "seed-roles":
            seed_roles(factory)
            print("System role catalog seeded.")
        elif args.command == "create-institution":
            with factory() as session:
                _create_institution(
                    session,
                    code=args.code,
                    name=args.name,
                    institution_type=args.institution_type,
                    city=args.city,
                    state=args.state,
                )
        elif args.command == "create-admin":
            with factory() as session:
                _create_admin(session, args.email, args.institution_code)
    finally:
        engine.dispose()


if __name__ == "__main__":
    main()
