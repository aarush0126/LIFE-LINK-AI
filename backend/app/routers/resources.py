from __future__ import annotations

from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import or_, select
from sqlalchemy.orm import Session, joinedload

from app.audit import record_audit
from app.db import get_db
from app.dependencies import get_current_user, require_permission
from app.domain import ResourceCategory, RoleName
from app.models import (
    CoordinationRequest,
    FacilityCapability,
    Institution,
    Notification,
    ResourceStatus,
    ResourceType,
    User,
)
from app.pagination import Pagination, page_response, paginate
from app.presenters import present_resource
from app.schemas import (
    BedEnquiryCreate,
    EnquiryCreate,
    EnquiryResponse,
    ResourcePublic,
    ResourceReportInput,
)

router = APIRouter(tags=["Blood bank", "ICU beds", "Equipment"])


_RESOURCE_READ_PERMISSION = {
    ResourceCategory.BLOOD.value: "blood:read",
    ResourceCategory.ICU.value: "icu:read",
    ResourceCategory.EQUIPMENT.value: "equipment:read",
}
_RESOURCE_REPORT_PERMISSION = {
    ResourceCategory.BLOOD.value: "blood:report",
    ResourceCategory.ICU.value: "icu:report",
    ResourceCategory.EQUIPMENT.value: "equipment:report",
}
_RESOURCE_ENQUIRE_PERMISSION = {
    ResourceCategory.BLOOD.value: "blood:enquire",
    ResourceCategory.ICU.value: "icu:enquire",
    ResourceCategory.EQUIPMENT.value: "equipment:enquire",
}
_NOTIFICATION_ROLES = {
    ResourceCategory.BLOOD.value: {
        RoleName.BLOOD_BANK_OFFICER.value,
        RoleName.HOSPITAL_ADMINISTRATOR.value,
        RoleName.NETWORK_ADMINISTRATOR.value,
    },
    ResourceCategory.ICU.value: {
        RoleName.EMERGENCY_ICU_COORDINATOR.value,
        RoleName.HOSPITAL_ADMINISTRATOR.value,
        RoleName.NETWORK_ADMINISTRATOR.value,
    },
    ResourceCategory.EQUIPMENT.value: {
        RoleName.EQUIPMENT_COORDINATOR.value,
        RoleName.HOSPITAL_ADMINISTRATOR.value,
        RoleName.NETWORK_ADMINISTRATOR.value,
    },
}


def _resource_statement():
    return (
        select(ResourceStatus)
        .join(ResourceStatus.capability)
        .join(FacilityCapability.resource_type)
        .join(FacilityCapability.institution)
        .options(
            joinedload(ResourceStatus.capability).joinedload(FacilityCapability.institution),
            joinedload(ResourceStatus.capability).joinedload(FacilityCapability.resource_type),
        )
        .where(
            FacilityCapability.is_active.is_(True),
            Institution.is_active.is_(True),
        )
        .order_by(ResourceStatus.updated_at.desc())
    )


def _list_resources(
    *,
    category: str,
    pagination: Pagination,
    session: Session,
    city: str | None,
    state: str | None,
    search: str | None,
    resource_status: str | None,
    blood_group: str | None = None,
    component: str | None = None,
    resource_type_key: str | None = None,
) -> dict[str, object]:
    statement = _resource_statement().where(ResourceType.category == category)
    if city:
        statement = statement.where(Institution.city.ilike(f"%{city.strip()}%"))
    if state:
        statement = statement.where(Institution.state.ilike(f"%{state.strip()}%"))
    if search:
        term = f"%{search.strip()}%"
        statement = statement.where(
            or_(
                Institution.name.ilike(term),
                FacilityCapability.name.ilike(term),
                ResourceType.label.ilike(term),
            )
        )
    if resource_status:
        statement = statement.where(ResourceStatus.status == resource_status)
    if blood_group:
        statement = statement.where(ResourceStatus.blood_group == blood_group)
    if component:
        statement = statement.where(ResourceStatus.component.ilike(f"%{component.strip()}%"))
    if resource_type_key:
        statement = statement.where(ResourceType.key == resource_type_key)
    rows, metadata = paginate(session, statement, pagination)
    return page_response([present_resource(row) for row in rows], metadata)


@router.get("/blood-bank/inventory")
def blood_inventory(
    pagination: Pagination = Depends(Pagination.dependency),
    city: str | None = Query(None, max_length=100),
    state: str | None = Query(None, max_length=100),
    search: str | None = Query(None, max_length=120),
    resource_status: str | None = Query(
        None, pattern="^(reported|requires_confirmation|institution_confirmed)$"
    ),
    blood_group: str | None = Query(None, pattern=r"^(A|B|AB|O)[+-]$"),
    component: str | None = Query(None, max_length=60),
    _: User = Depends(require_permission("blood:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    return _list_resources(
        category=ResourceCategory.BLOOD.value,
        pagination=pagination,
        session=session,
        city=city,
        state=state,
        search=search,
        resource_status=resource_status,
        blood_group=blood_group,
        component=component,
    )


@router.get("/icu-beds")
def icu_bed_indicators(
    pagination: Pagination = Depends(Pagination.dependency),
    city: str | None = Query(None, max_length=100),
    state: str | None = Query(None, max_length=100),
    search: str | None = Query(None, max_length=120),
    care_category: str | None = Query(None, max_length=60),
    resource_status: str | None = Query(
        None, pattern="^(reported|requires_confirmation|institution_confirmed)$"
    ),
    _: User = Depends(require_permission("icu:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    return _list_resources(
        category=ResourceCategory.ICU.value,
        pagination=pagination,
        session=session,
        city=city,
        state=state,
        search=search,
        resource_status=resource_status,
        resource_type_key=care_category,
    )


@router.get("/equipment")
def equipment_inventory(
    pagination: Pagination = Depends(Pagination.dependency),
    city: str | None = Query(None, max_length=100),
    state: str | None = Query(None, max_length=100),
    search: str | None = Query(None, max_length=120),
    resource_status: str | None = Query(
        None, pattern="^(reported|requires_confirmation|institution_confirmed)$"
    ),
    category: str | None = Query(None, max_length=60),
    _: User = Depends(require_permission("equipment:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    statement = _resource_statement().where(ResourceType.category == "equipment")
    if city:
        statement = statement.where(Institution.city.ilike(f"%{city.strip()}%"))
    if state:
        statement = statement.where(Institution.state.ilike(f"%{state.strip()}%"))
    if search:
        term = f"%{search.strip()}%"
        statement = statement.where(
            or_(
                Institution.name.ilike(term),
                FacilityCapability.name.ilike(term),
                ResourceType.label.ilike(term),
            )
        )
    if resource_status:
        statement = statement.where(ResourceStatus.status == resource_status)
    if category:
        statement = statement.where(ResourceType.key == category)
    rows, metadata = paginate(session, statement, pagination)
    return page_response([present_resource(row) for row in rows], metadata)


@router.post("/resources/status", response_model=ResourcePublic)
def report_resource_status(
    body: ResourceReportInput,
    request: Request,
    actor: User = Depends(get_current_user),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    capability = session.scalar(
        select(FacilityCapability)
        .options(
            joinedload(FacilityCapability.institution),
            joinedload(FacilityCapability.resource_type),
            joinedload(FacilityCapability.status),
        )
        .where(FacilityCapability.id == body.capability_id)
    )
    if capability is None or not capability.is_active:
        raise HTTPException(
            status_code=404,
            detail={
                "code": "capability_not_found",
                "message": "The requested institution capability was not found.",
            },
        )
    category = capability.resource_type.category
    permission = _RESOURCE_REPORT_PERMISSION.get(category)
    if permission is None or permission not in actor.role.permissions:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "permission_denied",
                "message": "Your assigned role cannot report this resource category.",
            },
        )
    if (
        actor.role.name != RoleName.NETWORK_ADMINISTRATOR.value
        and capability.institution_id != actor.institution_id
    ):
        raise HTTPException(
            status_code=403,
            detail={
                "code": "institution_scope_denied",
                "message": "Resource status can only be updated for your own institution.",
            },
        )
    if category != ResourceCategory.BLOOD.value and (
        body.blood_group is not None or body.component is not None
    ):
        raise HTTPException(
            status_code=422,
            detail={
                "code": "resource_fields_mismatch",
                "message": "Blood group and component fields are only valid for blood inventory.",
            },
        )
    item = capability.status
    if item is None:
        item = ResourceStatus(capability_id=capability.id)
        session.add(item)
    item.status = body.status
    item.quantity = body.quantity
    item.unit = body.unit.strip()
    item.blood_group = body.blood_group
    item.component = body.component
    item.urgency = body.urgency
    item.expires_at = body.expires_at
    session.flush()
    record_audit(
        session,
        request,
        actor=actor,
        action="resource_status_reported",
        entity_type="resource_status",
        entity_id=str(item.id),
        metadata={"category": category, "status": body.status},
    )
    session.commit()
    session.refresh(item)
    return present_resource(item)


def _notify_resource_enquiry(
    *,
    session: Session,
    target: Institution,
    category: str,
    request_id: int,
    request_reference: str,
) -> None:
    allowed_roles = _NOTIFICATION_ROLES[category]
    target_users = session.scalars(
        select(User)
        .join(User.role)
        .where(
            User.institution_id == target.id,
            User.is_active.is_(True),
            User.is_verified.is_(True),
        )
    ).all()
    for user in target_users:
        if user.role.name in allowed_roles:
            session.add(
                Notification(
                    user_id=user.id,
                    category="new_coordination_enquiry",
                    title="New synthetic resource enquiry",
                    summary=(
                        f"A {category} enquiry ({request_reference}) is awaiting "
                        "institutional review. It is not a reservation or confirmation."
                    ),
                    request_id=request_id,
                )
            )


def _create_enquiry(
    *,
    category: str,
    resource_type_key: str,
    target_institution_id: int,
    quantity: int,
    urgency: str,
    blood_group: str | None,
    component: str | None,
    actor: User,
    request: Request,
    session: Session,
) -> dict[str, object]:
    if category != ResourceCategory.BLOOD.value and (
        blood_group is not None or component is not None
    ):
        raise HTTPException(
            status_code=422,
            detail={
                "code": "resource_fields_mismatch",
                "message": "Blood group and component fields are only valid for blood enquiries.",
            },
        )
    target = session.get(Institution, target_institution_id)
    resource_type = session.scalar(
        select(ResourceType).where(
            ResourceType.key == resource_type_key,
            ResourceType.category == category,
        )
    )
    if target is None or not target.is_active or resource_type is None:
        raise HTTPException(
            status_code=404,
            detail={
                "code": "target_or_resource_not_found",
                "message": "Select an active institution and a resource type in this category.",
            },
        )
    reference = f"LL-ENQ-{uuid4().hex[:12].upper()}"
    enquiry = CoordinationRequest(
        request_reference=reference,
        category=category,
        resource_type_id=resource_type.id,
        requesting_institution_id=actor.institution_id,
        target_institution_id=target.id,
        created_by_user_id=actor.id,
        quantity=quantity,
        blood_group=blood_group,
        component=component,
        urgency=urgency,
        status="awaiting_institution_response",
    )
    session.add(enquiry)
    session.flush()
    _notify_resource_enquiry(
        session=session,
        target=target,
        category=category,
        request_id=enquiry.id,
        request_reference=reference,
    )
    record_audit(
        session,
        request,
        actor=actor,
        action="resource_enquiry_created",
        entity_type="request",
        entity_id=str(enquiry.id),
        metadata={"category": category, "status": enquiry.status},
    )
    session.commit()
    session.refresh(enquiry)
    return {
        "request_reference": enquiry.request_reference,
        "status": enquiry.status,
        "message": (
            "Enquiry logged. Availability and transfers require institutional "
            "confirmation; this is not a reservation."
        ),
        "created_at": enquiry.created_at,
    }


@router.post("/blood-bank/enquiries", response_model=EnquiryResponse, status_code=201)
def create_blood_enquiry(
    body: EnquiryCreate,
    request: Request,
    actor: User = Depends(require_permission("blood:enquire")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    return _create_enquiry(
        category=ResourceCategory.BLOOD.value,
        resource_type_key=body.resource_type_key,
        target_institution_id=body.target_institution_id,
        quantity=body.quantity,
        urgency=body.urgency,
        blood_group=body.blood_group,
        component=body.component,
        actor=actor,
        request=request,
        session=session,
    )


@router.post("/icu-beds/enquiries", response_model=EnquiryResponse, status_code=201)
def create_bed_enquiry(
    body: BedEnquiryCreate,
    request: Request,
    actor: User = Depends(require_permission("icu:enquire")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    return _create_enquiry(
        category=ResourceCategory.ICU.value,
        resource_type_key=body.care_category,
        target_institution_id=body.target_institution_id,
        quantity=1,
        urgency=body.urgency,
        blood_group=None,
        component=None,
        actor=actor,
        request=request,
        session=session,
    )


@router.post("/equipment/enquiries", response_model=EnquiryResponse, status_code=201)
def create_equipment_enquiry(
    body: EnquiryCreate,
    request: Request,
    actor: User = Depends(require_permission("equipment:enquire")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    return _create_enquiry(
        category=ResourceCategory.EQUIPMENT.value,
        resource_type_key=body.resource_type_key,
        target_institution_id=body.target_institution_id,
        quantity=body.quantity,
        urgency=body.urgency,
        blood_group=body.blood_group,
        component=body.component,
        actor=actor,
        request=request,
        session=session,
    )


def _list_requests(
    *,
    category: str,
    pagination: Pagination,
    actor: User,
    session: Session,
    status_filter: str | None,
) -> dict[str, object]:
    statement = (
        select(CoordinationRequest)
        .where(CoordinationRequest.category == category)
        .order_by(CoordinationRequest.created_at.desc())
    )
    if actor.role.name != RoleName.NETWORK_ADMINISTRATOR.value:
        statement = statement.where(
            or_(
                CoordinationRequest.requesting_institution_id == actor.institution_id,
                CoordinationRequest.target_institution_id == actor.institution_id,
            )
        )
    if status_filter:
        statement = statement.where(CoordinationRequest.status == status_filter)
    rows, metadata = paginate(session, statement, pagination)
    return page_response(
        [
            {
                "id": item.id,
                "request_reference": item.request_reference,
                "category": item.category,
                "resource_type_id": item.resource_type_id,
                "requesting_institution_id": item.requesting_institution_id,
                "target_institution_id": item.target_institution_id,
                "quantity": item.quantity,
                "blood_group": item.blood_group,
                "component": item.component,
                "urgency": item.urgency,
                "status": item.status,
                "created_at": item.created_at,
                "updated_at": item.updated_at,
            }
            for item in rows
        ],
        metadata,
    )


@router.get("/blood-bank/enquiries")
def list_blood_enquiries(
    pagination: Pagination = Depends(Pagination.dependency),
    request_status: str | None = Query(None, max_length=40),
    actor: User = Depends(require_permission("blood:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    return _list_requests(
        category=ResourceCategory.BLOOD.value,
        pagination=pagination,
        actor=actor,
        session=session,
        status_filter=request_status,
    )


@router.get("/icu-beds/enquiries")
def list_bed_enquiries(
    pagination: Pagination = Depends(Pagination.dependency),
    request_status: str | None = Query(None, max_length=40),
    actor: User = Depends(require_permission("icu:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    return _list_requests(
        category=ResourceCategory.ICU.value,
        pagination=pagination,
        actor=actor,
        session=session,
        status_filter=request_status,
    )


@router.get("/equipment/enquiries")
def list_equipment_enquiries(
    pagination: Pagination = Depends(Pagination.dependency),
    request_status: str | None = Query(None, max_length=40),
    actor: User = Depends(require_permission("equipment:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    return _list_requests(
        category=ResourceCategory.EQUIPMENT.value,
        pagination=pagination,
        actor=actor,
        session=session,
        status_filter=request_status,
    )
