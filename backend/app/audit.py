from fastapi import Request
from sqlalchemy.orm import Session

from app.models import AuditEvent, User


def record_audit(
    session: Session,
    request: Request,
    *,
    action: str,
    entity_type: str,
    entity_id: str,
    actor: User | None = None,
    metadata: dict[str, str | int | bool | None] | None = None,
) -> None:
    session.add(
        AuditEvent(
            actor_user_id=actor.id if actor else None,
            actor_role=actor.role.name if actor else "system",
            institution_id=actor.institution_id if actor else None,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            request_id=request.state.request_id,
            event_metadata=metadata or {},
        )
    )
