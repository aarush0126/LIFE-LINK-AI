from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import Settings
from app.db import get_db
from app.dependencies import get_current_user, get_settings, require_permission
from app.domain import RoleName
from app.models import AuditEvent, User
from app.pagination import Pagination, page_response, paginate

router = APIRouter(prefix="/admin", tags=["Administration and audit"])


@router.get("/audit-events")
def list_audit_events(
    pagination: Pagination = Depends(Pagination.dependency),
    action: str | None = Query(None, max_length=80),
    entity_type: str | None = Query(None, max_length=60),
    actor_role: str | None = Query(None, max_length=50),
    institution_id: int | None = Query(None, gt=0),
    actor: User = Depends(require_permission("audit:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    statement = select(AuditEvent).order_by(AuditEvent.occurred_at.desc())
    if actor.role.name == RoleName.AUDITOR_COMPLIANCE_OFFICER.value:
        statement = statement.where(AuditEvent.institution_id == actor.institution_id)
    if action:
        statement = statement.where(AuditEvent.action == action)
    if entity_type:
        statement = statement.where(AuditEvent.entity_type == entity_type)
    if actor_role:
        statement = statement.where(AuditEvent.actor_role == actor_role)
    if institution_id is not None:
        statement = statement.where(AuditEvent.institution_id == institution_id)
    rows, metadata = paginate(session, statement, pagination)
    return page_response(
        [
            {
                "id": item.id,
                "actor_role": item.actor_role,
                "institution_id": item.institution_id,
                "action": item.action,
                "entity_type": item.entity_type,
                "entity_id": item.entity_id,
                "request_id": item.request_id,
                "event_metadata": item.event_metadata,
                "occurred_at": item.occurred_at,
            }
            for item in rows
        ],
        metadata,
    )


@router.get("/system-health")
def system_health(
    actor: User = Depends(get_current_user),
    settings: Settings = Depends(get_settings),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    if actor.role.name != RoleName.NETWORK_ADMINISTRATOR.value:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "permission_denied",
                "message": "Network administrator access is required.",
            },
        )
    session.execute(select(1))
    return {
        "service": "lifelink-api",
        "environment": settings.app_env,
        "database": "connected",
        "authentication": "configured",
        "government_integrations": "not_configured",
        "data_mode": (
            "synthetic_demo_only" if settings.app_env in {"development", "test"} else "configured"
        ),
        "audit_storage": "database",
    }
