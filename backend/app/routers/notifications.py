from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.audit import record_audit
from app.db import get_db
from app.dependencies import require_permission
from app.models import Notification, User
from app.pagination import Pagination, page_response, paginate

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("")
def list_notifications(
    pagination: Pagination = Depends(Pagination.dependency),
    category: str | None = Query(None, max_length=40),
    unread_only: bool = False,
    actor: User = Depends(require_permission("notifications:read")),
    session: Session = Depends(get_db),
) -> dict[str, object]:
    statement = (
        select(Notification)
        .where(Notification.user_id == actor.id)
        .order_by(Notification.created_at.desc())
    )
    if category:
        statement = statement.where(Notification.category == category)
    if unread_only:
        statement = statement.where(Notification.read_at.is_(None))
    rows, metadata = paginate(session, statement, pagination)
    return page_response(
        [
            {
                "id": item.id,
                "category": item.category,
                "title": item.title,
                "summary": item.summary,
                "request_id": item.request_id,
                "is_read": item.read_at is not None,
                "created_at": item.created_at,
            }
            for item in rows
        ],
        metadata,
    )


@router.post("/{notification_id}/read", status_code=204)
def mark_notification_read(
    notification_id: int,
    request: Request,
    actor: User = Depends(require_permission("notifications:read")),
    session: Session = Depends(get_db),
) -> None:
    notification = session.scalar(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == actor.id,
        )
    )
    if notification is None:
        raise HTTPException(
            status_code=404,
            detail={
                "code": "notification_not_found",
                "message": "Notification not found.",
            },
        )
    if notification.read_at is None:
        notification.read_at = datetime.now(UTC)
        record_audit(
            session,
            request,
            actor=actor,
            action="notification_marked_read",
            entity_type="notification",
            entity_id=str(notification.id),
            metadata={"category": notification.category},
        )
        session.commit()
