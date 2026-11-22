from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import or_, select
from sqlalchemy.orm import Session, joinedload

from app.audit import record_audit
from app.db import get_db
from app.dependencies import get_current_user, require_permission
from app.domain import ASSIGNABLE_ROLE_NAMES, RoleName
from app.models import FacilityCapability, Institution, ResourceType, Role, User
from app.pagination import Pagination, page_response, paginate
from app.presenters import present_institution, present_user
from app.schemas import (
    CapabilityCreate,
    InstitutionCreate,
    InstitutionPublic,
    UserPublic,
    UserRoleUpdate,
    UserStatusUpdate,
)

router = APIRouter(tags=["Hospital registry", "Users and roles"])


@router.get("/roles")
def list_roles(
    _: User = Depends(require_permission("roles:read")),
    session: Session = Depends(get_db),
) -> list[dict[str, object]]:
    roles = session.scalars(select(Role).order_by(Role.name)).all()
    return [{"name": role.name, "permissions": role.permissions} for role in roles]


@router.get("/users")
def list_users(
    pagination: Pagination = Depends(Pagination.dependency),
    role: str | None = None,
    institution_id: int | None = Query(None, gt=0),
    search: str | None = Query(None, max_length=120),
    is_active: bool | None = None,
    _: User = Depends(require_permission("users:manage")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    statement = (
        select(User)
        .join(User.role)
        .options(joinedload(User.role), joinedload(User.institution))
        .order_by(User.id)
    )
    if role:
        statement = statement.where(Role.name == role)
    if institution_id is not None:
        statement = statement.where(User.institution_id == institution_id)
    if is_active is not None:
        statement = statement.where(User.is_active.is_(is_active))
    if search:
        term = f"%{search.strip()}%"
        statement = statement.where(or_(User.email.ilike(term), User.full_name.ilike(term)))
    rows, metadata = paginate(session, statement, pagination)
    return page_response([present_user(user) for user in rows], metadata)


@router.patch("/users/{user_id}/role", response_model=UserPublic)
def update_user_role(
    user_id: int,
    body: UserRoleUpdate,
    request: Request,
    actor: User = Depends(require_permission("users:manage")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    if user_id == actor.id:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "self_role_change_denied",
                "message": "Administrators cannot change their own role.",
            },
        )
    try:
        requested_role = RoleName(body.role)
    except ValueError:
        raise HTTPException(
            status_code=422,
            detail={"code": "invalid_role", "message": "Select a defined system role."},
        ) from None
    if requested_role not in ASSIGNABLE_ROLE_NAMES:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "privileged_role_assignment_denied",
                "message": (
                    "Privileged administrator and auditor roles require out-of-band provisioning."
                ),
            },
        )
    user = session.scalar(
        select(User)
        .options(joinedload(User.role), joinedload(User.institution))
        .where(User.id == user_id)
    )
    if user is None:
        raise HTTPException(
            status_code=404, detail={"code": "user_not_found", "message": "User not found."}
        )
    if user.role.name in {
        RoleName.NETWORK_ADMINISTRATOR.value,
        RoleName.AUDITOR_COMPLIANCE_OFFICER.value,
    }:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "privileged_account_locked",
                "message": "Privileged accounts cannot be reassigned through this endpoint.",
            },
        )
    role = session.scalar(select(Role).where(Role.name == requested_role.value))
    if role is None:
        raise HTTPException(
            status_code=503,
            detail={"code": "roles_not_seeded", "message": "The role catalog is unavailable."},
        )
    previous_role = user.role.name
    user.role_id = role.id
    record_audit(
        session,
        request,
        actor=actor,
        action="user_role_changed",
        entity_type="user",
        entity_id=str(user.id),
        metadata={"from": previous_role, "to": role.name},
    )
    session.commit()
    session.refresh(user)
    return present_user(user)


@router.patch("/users/{user_id}/status", response_model=UserPublic)
def update_user_status(
    user_id: int,
    body: UserStatusUpdate,
    request: Request,
    actor: User = Depends(require_permission("users:manage")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    if user_id == actor.id:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "self_status_change_denied",
                "message": "Administrators cannot change their own account status.",
            },
        )
    if body.is_active and not body.is_verified:
        raise HTTPException(
            status_code=422,
            detail={
                "code": "verification_required",
                "message": "An account must be verified before it can be activated.",
            },
        )
    user = session.scalar(
        select(User)
        .options(joinedload(User.role), joinedload(User.institution))
        .where(User.id == user_id)
    )
    if user is None:
        raise HTTPException(
            status_code=404, detail={"code": "user_not_found", "message": "User not found."}
        )
    if user.role.name in {
        RoleName.NETWORK_ADMINISTRATOR.value,
        RoleName.AUDITOR_COMPLIANCE_OFFICER.value,
    }:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "privileged_account_locked",
                "message": "Privileged accounts cannot be changed through this endpoint.",
            },
        )
    user.is_active = body.is_active
    user.is_verified = body.is_verified
    record_audit(
        session,
        request,
        actor=actor,
        action="user_status_changed",
        entity_type="user",
        entity_id=str(user.id),
        metadata={"is_active": user.is_active, "is_verified": user.is_verified},
    )
    session.commit()
    session.refresh(user)
    return present_user(user)


@router.get("/hospitals")
def list_hospitals(
    pagination: Pagination = Depends(Pagination.dependency),
    city: str | None = Query(None, max_length=100),
    state: str | None = Query(None, max_length=100),
    search: str | None = Query(None, max_length=120),
    verified: bool | None = None,
    _: User = Depends(require_permission("hospitals:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    statement = (
        select(Institution).where(Institution.is_active.is_(True)).order_by(Institution.name)
    )
    if city:
        statement = statement.where(Institution.city.ilike(f"%{city.strip()}%"))
    if state:
        statement = statement.where(Institution.state.ilike(f"%{state.strip()}%"))
    if verified is not None:
        statement = statement.where(Institution.is_verified.is_(verified))
    if search:
        term = f"%{search.strip()}%"
        statement = statement.where(
            or_(
                Institution.name.ilike(term),
                Institution.institution_code.ilike(term),
                Institution.city.ilike(term),
                Institution.state.ilike(term),
            )
        )
    rows, metadata = paginate(session, statement, pagination)
    return page_response([present_institution(hospital) for hospital in rows], metadata)


@router.get("/hospitals/{institution_id}", response_model=InstitutionPublic)
def get_hospital(
    institution_id: int,
    _: User = Depends(require_permission("hospitals:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    institution = session.get(Institution, institution_id)
    if institution is None or not institution.is_active:
        raise HTTPException(
            status_code=404,
            detail={"code": "institution_not_found", "message": "Institution not found."},
        )
    return present_institution(institution)


@router.post("/hospitals", response_model=InstitutionPublic, status_code=201)
def create_hospital(
    body: InstitutionCreate,
    request: Request,
    actor: User = Depends(require_permission("hospitals:manage")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    institution = Institution(
        institution_code=body.institution_code,
        name=body.name.strip(),
        institution_type=body.institution_type.strip(),
        city=body.city.strip(),
        state=body.state.strip(),
        is_verified=False,
        is_active=True,
        is_demo=True,
    )
    session.add(institution)
    session.flush()
    record_audit(
        session,
        request,
        actor=actor,
        action="institution_created",
        entity_type="institution",
        entity_id=str(institution.id),
        metadata={"is_demo": True},
    )
    session.commit()
    session.refresh(institution)
    return present_institution(institution)


@router.post("/hospitals/{institution_id}/verification", response_model=InstitutionPublic)
def set_hospital_verification(
    institution_id: int,
    request: Request,
    verified: bool = Query(...),
    actor: User = Depends(require_permission("hospitals:manage")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    institution = session.get(Institution, institution_id)
    if institution is None:
        raise HTTPException(
            status_code=404,
            detail={"code": "institution_not_found", "message": "Institution not found."},
        )
    institution.is_verified = verified
    record_audit(
        session,
        request,
        actor=actor,
        action="institution_verification_changed",
        entity_type="institution",
        entity_id=str(institution.id),
        metadata={"is_verified": verified, "is_demo": institution.is_demo},
    )
    session.commit()
    session.refresh(institution)
    return present_institution(institution)


@router.get("/hospitals/{institution_id}/capabilities")
def list_capabilities(
    institution_id: int,
    _: User = Depends(require_permission("hospitals:read")),
    session: Session = Depends(get_db),
) -> list[dict[str, object]]:
    institution = session.get(Institution, institution_id)
    if institution is None or not institution.is_active:
        raise HTTPException(
            status_code=404,
            detail={"code": "institution_not_found", "message": "Institution not found."},
        )
    capabilities = session.scalars(
        select(FacilityCapability)
        .options(
            joinedload(FacilityCapability.resource_type), joinedload(FacilityCapability.status)
        )
        .where(
            FacilityCapability.institution_id == institution_id,
            FacilityCapability.is_active.is_(True),
        )
        .order_by(FacilityCapability.name)
    ).all()
    return [
        {
            "id": item.id,
            "name": item.name,
            "resource_type": item.resource_type.key,
            "category": item.resource_type.category,
            "status": item.status.status if item.status else "requires_confirmation",
            "last_updated": item.status.updated_at if item.status else None,
            "availability_is_guaranteed": False,
        }
        for item in capabilities
    ]


@router.post(
    "/hospitals/{institution_id}/capabilities",
    status_code=201,
)
def add_capability(
    institution_id: int,
    body: CapabilityCreate,
    request: Request,
    actor: User = Depends(require_permission("hospitals:manage")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    institution = session.get(Institution, institution_id)
    resource_type = session.scalar(
        select(ResourceType).where(ResourceType.key == body.resource_type_key)
    )
    if institution is None or resource_type is None:
        raise HTTPException(
            status_code=404,
            detail={
                "code": "institution_or_resource_not_found",
                "message": "Institution or resource type not found.",
            },
        )
    capability = FacilityCapability(
        institution_id=institution.id,
        resource_type_id=resource_type.id,
        name=body.name.strip(),
    )
    session.add(capability)
    session.flush()
    record_audit(
        session,
        request,
        actor=actor,
        action="facility_capability_added",
        entity_type="facility_capability",
        entity_id=str(capability.id),
        metadata={"institution_id": institution.id},
    )
    session.commit()
    return {
        "id": capability.id,
        "institution_id": institution.id,
        "name": capability.name,
        "resource_type": resource_type.key,
        "category": resource_type.category,
    }


@router.get("/hospitals/{institution_id}/users")
def list_institution_users(
    institution_id: int,
    pagination: Pagination = Depends(Pagination.dependency),
    actor: User = Depends(get_current_user),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    if actor.role.name != RoleName.NETWORK_ADMINISTRATOR.value:
        if (
            actor.role.name != RoleName.HOSPITAL_ADMINISTRATOR.value
            or actor.institution_id != institution_id
        ):
            raise HTTPException(
                status_code=403,
                detail={
                    "code": "permission_denied",
                    "message": "You may only view users in your own institution.",
                },
            )
    statement = (
        select(User)
        .options(joinedload(User.role), joinedload(User.institution))
        .where(User.institution_id == institution_id)
        .order_by(User.id)
    )
    rows, metadata = paginate(session, statement, pagination)
    return page_response([present_user(user) for user in rows], metadata)
