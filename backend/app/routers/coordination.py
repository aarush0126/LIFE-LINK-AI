from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.audit import record_audit
from app.db import get_db
from app.dependencies import require_permission
from app.domain import RoleName
from app.models import (
    AuditEvent,
    AuthorisationReference,
    CoordinationCase,
    LogisticsEvent,
    User,
)
from app.pagination import Pagination, page_response, paginate
from app.schemas import (
    AuthorisationReferenceCreate,
    AuthorisationReferencePublic,
    CoordinationCaseCreate,
    CoordinationCasePublic,
    HumanApprovalInput,
    LogisticsEventCreate,
    LogisticsEventPublic,
)

router = APIRouter(prefix="/coordination-cases", tags=["Organ and tissue coordination"])


def _case_for_actor(session: Session, case_id: int, actor: User) -> CoordinationCase:
    statement = select(CoordinationCase).where(CoordinationCase.id == case_id)
    if actor.role.name != RoleName.NETWORK_ADMINISTRATOR.value:
        statement = statement.where(CoordinationCase.institution_id == actor.institution_id)
    case = session.scalar(statement)
    if case is None:
        raise HTTPException(
            status_code=404,
            detail={"code": "case_not_found", "message": "Coordination case not found."},
        )
    return case


def _present_case(case: CoordinationCase) -> dict[str, object]:
    return {
        "id": case.id,
        "case_reference": case.case_reference,
        "institution_id": case.institution_id,
        "pathway": case.pathway,
        "resource_category": case.resource_category,
        "capability": case.capability,
        "status": case.status,
        "verification_status": case.verification_status,
        "created_at": case.created_at,
        "updated_at": case.updated_at,
    }


@router.get("")
def list_cases(
    pagination: Pagination = Depends(Pagination.dependency),
    case_status: str | None = None,
    actor: User = Depends(require_permission("organ:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    statement = select(CoordinationCase).order_by(CoordinationCase.updated_at.desc())
    if actor.role.name != RoleName.NETWORK_ADMINISTRATOR.value:
        statement = statement.where(CoordinationCase.institution_id == actor.institution_id)
    if case_status:
        statement = statement.where(CoordinationCase.status == case_status)
    rows, metadata = paginate(session, statement, pagination)
    return page_response([_present_case(case) for case in rows], metadata)


@router.post("", response_model=CoordinationCasePublic, status_code=201)
def create_case(
    body: CoordinationCaseCreate,
    request: Request,
    actor: User = Depends(require_permission("organ:coordinate")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    case = CoordinationCase(
        case_reference=body.case_reference,
        institution_id=actor.institution_id,
        created_by_user_id=actor.id,
        pathway=body.pathway,
        resource_category=body.resource_category,
        capability=body.capability.strip(),
        status="pending_human_review",
        verification_status="pending",
    )
    session.add(case)
    session.flush()
    record_audit(
        session,
        request,
        actor=actor,
        action="coordination_case_created",
        entity_type="coordination_case",
        entity_id=str(case.id),
        metadata={"pathway": case.pathway, "resource_category": case.resource_category},
    )
    session.commit()
    session.refresh(case)
    return _present_case(case)


@router.get("/{case_id}", response_model=CoordinationCasePublic)
def get_case(
    case_id: int,
    actor: User = Depends(require_permission("organ:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    return _present_case(_case_for_actor(session, case_id, actor))


@router.post("/{case_id}/human-approval", response_model=CoordinationCasePublic)
def record_human_approval(
    case_id: int,
    body: HumanApprovalInput,
    request: Request,
    actor: User = Depends(require_permission("organ:coordinate")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    case = _case_for_actor(session, case_id, actor)
    if case.status != "pending_human_review":
        raise HTTPException(
            status_code=409,
            detail={
                "code": "invalid_case_transition",
                "message": "Human review has already been completed for this demo case.",
            },
        )
    case.status = "awaiting_institution_response" if body.approved else "review_not_approved"
    case.human_approved_by_user_id = actor.id if body.approved else None
    case.verification_status = "institution_reviewed" if body.approved else "pending"
    record_audit(
        session,
        request,
        actor=actor,
        action="human_review_recorded",
        entity_type="coordination_case",
        entity_id=str(case.id),
        metadata={"approved": body.approved},
    )
    session.commit()
    session.refresh(case)
    return _present_case(case)


@router.post(
    "/{case_id}/authorisation-references",
    response_model=AuthorisationReferencePublic,
    status_code=201,
)
def add_authorisation_reference(
    case_id: int,
    body: AuthorisationReferenceCreate,
    request: Request,
    actor: User = Depends(require_permission("organ:coordinate")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    case = _case_for_actor(session, case_id, actor)
    if case.human_approved_by_user_id is None:
        raise HTTPException(
            status_code=409,
            detail={
                "code": "human_approval_required",
                "message": (
                    "An authorized human must review the case before adding a pathway reference."
                ),
            },
        )
    reference = AuthorisationReference(
        coordination_case_id=case.id,
        pathway_level=body.pathway_level,
        reference_code=body.reference_code,
        verification_status="not_verified",
        recorded_by_user_id=actor.id,
    )
    session.add(reference)
    session.flush()
    record_audit(
        session,
        request,
        actor=actor,
        action="pathway_reference_recorded",
        entity_type="coordination_case",
        entity_id=str(case.id),
        metadata={"verification_status": "not_verified"},
    )
    session.commit()
    session.refresh(reference)
    return {
        "id": reference.id,
        "coordination_case_id": reference.coordination_case_id,
        "pathway_level": reference.pathway_level,
        "reference_code": reference.reference_code,
        "verification_status": reference.verification_status,
        "created_at": reference.created_at,
    }


@router.get("/{case_id}/authorisation-references")
def list_authorisation_references(
    case_id: int,
    pagination: Pagination = Depends(Pagination.dependency),
    actor: User = Depends(require_permission("organ:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    _case_for_actor(session, case_id, actor)
    statement = (
        select(AuthorisationReference)
        .where(AuthorisationReference.coordination_case_id == case_id)
        .order_by(AuthorisationReference.created_at.desc())
    )
    rows, metadata = paginate(session, statement, pagination)
    return page_response(
        [
            {
                "id": row.id,
                "coordination_case_id": row.coordination_case_id,
                "pathway_level": row.pathway_level,
                "reference_code": row.reference_code,
                "verification_status": row.verification_status,
                "created_at": row.created_at,
            }
            for row in rows
        ],
        metadata,
    )


@router.post("/{case_id}/simulated-route", response_model=CoordinationCasePublic)
def request_simulated_route(
    case_id: int,
    request: Request,
    actor: User = Depends(require_permission("organ:coordinate")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    case = _case_for_actor(session, case_id, actor)
    if case.human_approved_by_user_id is None:
        raise HTTPException(
            status_code=409,
            detail={
                "code": "human_approval_required",
                "message": "An authorized human must review the case before routing.",
            },
        )
    has_reference = session.scalar(
        select(AuthorisationReference.id).where(
            AuthorisationReference.coordination_case_id == case.id
        )
    )
    if has_reference is None:
        raise HTTPException(
            status_code=409,
            detail={
                "code": "pathway_reference_required",
                "message": "Record an external pathway reference before simulated routing.",
            },
        )
    case.status = "simulated_routing_requested"
    record_audit(
        session,
        request,
        actor=actor,
        action="simulated_route_requested",
        entity_type="coordination_case",
        entity_id=str(case.id),
        metadata={"external_integration": False},
    )
    session.commit()
    session.refresh(case)
    return _present_case(case)


@router.post(
    "/{case_id}/logistics-events",
    response_model=LogisticsEventPublic,
    status_code=201,
)
def add_logistics_event(
    case_id: int,
    body: LogisticsEventCreate,
    request: Request,
    actor: User = Depends(require_permission("organ:coordinate")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    case = _case_for_actor(session, case_id, actor)
    if case.human_approved_by_user_id is None or case.status != "simulated_routing_requested":
        raise HTTPException(
            status_code=409,
            detail={
                "code": "workflow_not_ready",
                "message": (
                    "Human approval and simulated routing are required before logistics updates."
                ),
            },
        )
    event = LogisticsEvent(
        coordination_case_id=case.id,
        event_type=body.event_type,
        status=body.status,
        recorded_by_user_id=actor.id,
    )
    session.add(event)
    session.flush()
    record_audit(
        session,
        request,
        actor=actor,
        action="logistics_demo_status_recorded",
        entity_type="coordination_case",
        entity_id=str(case.id),
        metadata={"event_type": event.event_type, "status": event.status},
    )
    session.commit()
    session.refresh(event)
    return {
        "id": event.id,
        "coordination_case_id": event.coordination_case_id,
        "event_type": event.event_type,
        "status": event.status,
        "occurred_at": event.occurred_at,
    }


@router.get("/{case_id}/logistics-events")
def list_logistics_events(
    case_id: int,
    pagination: Pagination = Depends(Pagination.dependency),
    actor: User = Depends(require_permission("organ:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    _case_for_actor(session, case_id, actor)
    statement = (
        select(LogisticsEvent)
        .where(LogisticsEvent.coordination_case_id == case_id)
        .order_by(LogisticsEvent.occurred_at.desc())
    )
    rows, metadata = paginate(session, statement, pagination)
    return page_response(
        [
            {
                "id": row.id,
                "coordination_case_id": row.coordination_case_id,
                "event_type": row.event_type,
                "status": row.status,
                "occurred_at": row.occurred_at,
            }
            for row in rows
        ],
        metadata,
    )


@router.get("/{case_id}/audit-events")
def list_case_audit_events(
    case_id: int,
    pagination: Pagination = Depends(Pagination.dependency),
    actor: User = Depends(require_permission("organ:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    case = _case_for_actor(session, case_id, actor)
    statement = (
        select(AuditEvent)
        .where(
            AuditEvent.entity_type == "coordination_case",
            AuditEvent.entity_id == str(case.id),
        )
        .order_by(AuditEvent.occurred_at.desc())
    )
    rows, metadata = paginate(session, statement, pagination)
    return page_response(
        [
            {
                "id": row.id,
                "actor_role": row.actor_role,
                "action": row.action,
                "entity_type": row.entity_type,
                "entity_id": row.entity_id,
                "event_metadata": row.event_metadata,
                "occurred_at": row.occurred_at,
            }
            for row in rows
        ],
        metadata,
    )
