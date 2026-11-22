from __future__ import annotations

from datetime import UTC, datetime, timedelta
from hashlib import sha256

from fastapi import APIRouter, Depends
from sqlalchemy import case, func, or_, select
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.dependencies import require_permission
from app.domain import ResourceCategory
from app.models import (
    CoordinationRequest,
    FacilityCapability,
    Institution,
    ModelRecommendation,
    ResourceStatus,
    ResourceType,
    User,
)
from app.schemas import AIResourceSearchInput, AIResourceSearchResponse

router = APIRouter(prefix="/ai", tags=["AI services"])

_CATEGORY_PERMISSION = {
    ResourceCategory.BLOOD.value: "blood:read",
    ResourceCategory.ICU.value: "icu:read",
    ResourceCategory.EQUIPMENT.value: "equipment:read",
    ResourceCategory.ORGAN_COORDINATION.value: "organ:read",
}


@router.post("/resource-search", response_model=AIResourceSearchResponse)
def deterministic_resource_search(
    body: AIResourceSearchInput,
    actor: User = Depends(require_permission("ai:use")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    requested_category = body.category
    available_categories = {
        category
        for category, permission in _CATEGORY_PERMISSION.items()
        if permission in actor.role.permissions
    }
    if requested_category and requested_category not in available_categories:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=403,
            detail={
                "code": "resource_scope_denied",
                "message": "Your assigned role cannot search this resource category.",
            },
        )

    terms = [term for term in body.query.strip().split() if len(term) > 1][:8]
    statement = (
        select(ResourceStatus)
        .join(ResourceStatus.capability)
        .join(FacilityCapability.resource_type)
        .join(FacilityCapability.institution)
        .options(
            joinedload(ResourceStatus.capability).joinedload(FacilityCapability.institution),
            joinedload(ResourceStatus.capability).joinedload(FacilityCapability.resource_type),
        )
        .where(
            ResourceType.category.in_(
                [requested_category] if requested_category else sorted(available_categories)
            ),
            Institution.is_active.is_(True),
            FacilityCapability.is_active.is_(True),
        )
        .order_by(ResourceStatus.updated_at.desc())
    )
    if body.city:
        statement = statement.where(Institution.city.ilike(f"%{body.city.strip()}%"))
    if body.state:
        statement = statement.where(Institution.state.ilike(f"%{body.state.strip()}%"))
    for term in terms:
        statement = statement.where(
            or_(
                FacilityCapability.name.ilike(f"%{term}%"),
                ResourceType.label.ilike(f"%{term}%"),
                Institution.city.ilike(f"%{term}%"),
                Institution.state.ilike(f"%{term}%"),
            )
        )
    matches = session.scalars(statement.limit(100)).all()
    now = datetime.now(UTC)
    results = []
    for item in matches:
        stale = now - item.updated_at.replace(tzinfo=UTC) > timedelta(hours=24)
        needs_confirmation = (
            item.status != "institution_confirmed"
            or not item.capability.institution.is_verified
            or stale
        )
        results.append(
            {
                "institution_id": item.capability.institution.id,
                "institution_name": item.capability.institution.name,
                "city": item.capability.institution.city,
                "state": item.capability.institution.state,
                "resource_type": item.capability.resource_type.label,
                "capability": item.capability.name,
                "status": item.status,
                "quantity": item.quantity,
                "unit": item.unit,
                "last_updated": item.updated_at,
                "verification": (
                    "institution verified"
                    if item.capability.institution.is_verified
                    else "institution verification pending"
                ),
                "why_suggested": "Matched the requested resource or location terms.",
                "uncertainty": (
                    "Information may be incomplete or out of date; contact the institution."
                    if needs_confirmation
                    else "Institution-reported only; confirm directly before acting."
                ),
            }
        )
    summary = (
        "Advisory search results only. Resource status is an enquiry indicator, "
        "not a guarantee, clinical recommendation, admission, reservation, or allocation."
    )
    query_hash = sha256(body.query.strip().lower().encode("utf-8")).hexdigest()
    session.add(
        ModelRecommendation(
            user_id=actor.id,
            category="resource_discovery",
            query_sha256=query_hash,
            result_count=len(results),
            advisory_summary="Deterministic synthetic resource discovery; advisory only.",
            model_version="deterministic-demo-v1",
        )
    )
    session.commit()
    return {
        "mode": "deterministic_demo",
        "advisory_only": True,
        "results": results,
        "message": summary,
    }


@router.get("/data-quality")
def data_quality_summary(
    category: str | None = None,
    actor: User = Depends(require_permission("ai:use")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    allowed_categories = {
        category_name
        for category_name, permission in _CATEGORY_PERMISSION.items()
        if permission in actor.role.permissions
    }
    if category is not None and category not in allowed_categories:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=403,
            detail={
                "code": "resource_scope_denied",
                "message": "Your assigned role cannot inspect this resource category.",
            },
        )
    selected_categories = [category] if category else sorted(allowed_categories)
    cutoff = datetime.now(UTC) - timedelta(hours=24)
    rows = session.execute(
        select(
            ResourceType.category,
            func.count(ResourceStatus.id),
            func.sum(
                case(
                    (ResourceStatus.status == "requires_confirmation", 1),
                    else_=0,
                )
            ),
            func.sum(
                case(
                    (ResourceStatus.updated_at < cutoff, 1),
                    else_=0,
                )
            ),
        )
        .join(FacilityCapability, FacilityCapability.resource_type_id == ResourceType.id)
        .join(ResourceStatus, ResourceStatus.capability_id == FacilityCapability.id)
        .where(ResourceType.category.in_(selected_categories))
        .group_by(ResourceType.category)
    ).all()
    by_category = {
        row[0]: {
            "records": int(row[1] or 0),
            "awaiting_confirmation": int(row[2] or 0),
            "older_than_24h": int(row[3] or 0),
        }
        for row in rows
    }
    return {
        "mode": "deterministic_demo",
        "advisory_only": True,
        "categories": by_category,
        "message": (
            "Quality indicators identify missing confirmation and age only. "
            "They do not determine clinical suitability or resource availability."
        ),
    }


@router.get("/operational-summary")
def operational_summary(
    actor: User = Depends(require_permission("ai:use")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    allowed_categories = {
        category
        for category, permission in _CATEGORY_PERMISSION.items()
        if permission in actor.role.permissions
    }
    rows = session.execute(
        select(CoordinationRequest.category, func.count(CoordinationRequest.id))
        .where(
            CoordinationRequest.category.in_(allowed_categories),
            CoordinationRequest.status.in_(["enquiry_logged", "awaiting_institution_response"]),
        )
        .group_by(CoordinationRequest.category)
    ).all()
    return {
        "mode": "deterministic_demo",
        "advisory_only": True,
        "pending_enquiries": {category: int(count) for category, count in rows},
        "message": (
            "This is a current synthetic enquiry count, not a clinical forecast or "
            "guaranteed capacity estimate."
        ),
    }
