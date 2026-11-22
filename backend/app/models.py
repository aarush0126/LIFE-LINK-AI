from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class Role(Base):
    __tablename__ = "roles"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    permissions: Mapped[list[str]] = mapped_column(JSON, default=list)
    is_system_role: Mapped[bool] = mapped_column(Boolean, default=True)

    users: Mapped[list[User]] = relationship(back_populates="role")


class Institution(Base):
    __tablename__ = "institutions"

    id: Mapped[int] = mapped_column(primary_key=True)
    institution_code: Mapped[str] = mapped_column(String(40), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(200))
    institution_type: Mapped[str] = mapped_column(String(50))
    city: Mapped[str] = mapped_column(String(100), index=True)
    state: Mapped[str] = mapped_column(String(100), index=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_demo: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    users: Mapped[list[User]] = relationship(back_populates="institution")
    capabilities: Mapped[list[FacilityCapability]] = relationship(
        back_populates="institution", cascade="all, delete-orphan"
    )


class User(Base):
    __tablename__ = "users"
    __table_args__ = (Index("ix_users_institution_role", "institution_id", "role_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    full_name: Mapped[str] = mapped_column(String(160))
    department: Mapped[str] = mapped_column(String(120), default="")
    password_hash: Mapped[str] = mapped_column(String(255))
    institution_id: Mapped[int] = mapped_column(ForeignKey("institutions.id"))
    role_id: Mapped[int] = mapped_column(ForeignKey("roles.id"))
    is_active: Mapped[bool] = mapped_column(Boolean, default=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    institution: Mapped[Institution] = relationship(back_populates="users")
    role: Mapped[Role] = relationship(back_populates="users")


class RefreshSession(Base):
    __tablename__ = "refresh_sessions"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    token_jti: Mapped[str] = mapped_column(String(36), unique=True, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class ResourceType(Base):
    __tablename__ = "resource_types"

    id: Mapped[int] = mapped_column(primary_key=True)
    key: Mapped[str] = mapped_column(String(60), unique=True, index=True)
    label: Mapped[str] = mapped_column(String(120))
    category: Mapped[str] = mapped_column(String(40), index=True)

    capabilities: Mapped[list[FacilityCapability]] = relationship(back_populates="resource_type")


class FacilityCapability(Base):
    __tablename__ = "facility_capabilities"
    __table_args__ = (UniqueConstraint("institution_id", "resource_type_id", "name"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    institution_id: Mapped[int] = mapped_column(
        ForeignKey("institutions.id", ondelete="CASCADE"), index=True
    )
    resource_type_id: Mapped[int] = mapped_column(ForeignKey("resource_types.id"), index=True)
    name: Mapped[str] = mapped_column(String(160))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    institution: Mapped[Institution] = relationship(back_populates="capabilities")
    resource_type: Mapped[ResourceType] = relationship(back_populates="capabilities")
    status: Mapped[ResourceStatus | None] = relationship(
        back_populates="capability", cascade="all, delete-orphan", uselist=False
    )


class ResourceStatus(Base):
    __tablename__ = "resource_statuses"
    __table_args__ = (
        UniqueConstraint("capability_id"),
        CheckConstraint("quantity IS NULL OR quantity >= 0", name="ck_resource_nonnegative"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    capability_id: Mapped[int] = mapped_column(
        ForeignKey("facility_capabilities.id", ondelete="CASCADE"), index=True
    )
    status: Mapped[str] = mapped_column(String(40), default="reported", index=True)
    quantity: Mapped[int | None] = mapped_column(Integer)
    unit: Mapped[str] = mapped_column(String(30), default="items")
    blood_group: Mapped[str | None] = mapped_column(String(3), index=True)
    component: Mapped[str | None] = mapped_column(String(60), index=True)
    urgency: Mapped[str | None] = mapped_column(String(20))
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    capability: Mapped[FacilityCapability] = relationship(back_populates="status")


class CoordinationRequest(Base):
    __tablename__ = "requests"
    __table_args__ = (
        CheckConstraint("quantity > 0", name="ck_request_positive_quantity"),
        Index("ix_requests_resource_status", "resource_type_id", "status"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    request_reference: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    category: Mapped[str] = mapped_column(String(40), index=True)
    resource_type_id: Mapped[int] = mapped_column(ForeignKey("resource_types.id"))
    requesting_institution_id: Mapped[int] = mapped_column(ForeignKey("institutions.id"))
    target_institution_id: Mapped[int] = mapped_column(ForeignKey("institutions.id"))
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    quantity: Mapped[int] = mapped_column(Integer)
    blood_group: Mapped[str | None] = mapped_column(String(3))
    component: Mapped[str | None] = mapped_column(String(60))
    urgency: Mapped[str] = mapped_column(String(20), default="routine")
    status: Mapped[str] = mapped_column(String(40), default="enquiry_logged", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class CoordinationCase(Base):
    __tablename__ = "coordination_cases"

    id: Mapped[int] = mapped_column(primary_key=True)
    case_reference: Mapped[str] = mapped_column(String(60), unique=True, index=True)
    institution_id: Mapped[int] = mapped_column(ForeignKey("institutions.id"), index=True)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    pathway: Mapped[str] = mapped_column(String(40))
    resource_category: Mapped[str] = mapped_column(String(40))
    capability: Mapped[str] = mapped_column(String(160))
    status: Mapped[str] = mapped_column(String(40), default="pending_review", index=True)
    verification_status: Mapped[str] = mapped_column(String(40), default="pending")
    human_approved_by_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class AuthorisationReference(Base):
    __tablename__ = "authorisation_references"

    id: Mapped[int] = mapped_column(primary_key=True)
    coordination_case_id: Mapped[int] = mapped_column(
        ForeignKey("coordination_cases.id", ondelete="CASCADE"), index=True
    )
    pathway_level: Mapped[str] = mapped_column(String(30))
    reference_code: Mapped[str] = mapped_column(String(50))
    verification_status: Mapped[str] = mapped_column(String(30), default="not_verified")
    recorded_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class LogisticsEvent(Base):
    __tablename__ = "logistics_events"

    id: Mapped[int] = mapped_column(primary_key=True)
    coordination_case_id: Mapped[int] = mapped_column(
        ForeignKey("coordination_cases.id", ondelete="CASCADE"), index=True
    )
    event_type: Mapped[str] = mapped_column(String(40))
    status: Mapped[str] = mapped_column(String(40))
    recorded_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )


class Notification(Base):
    __tablename__ = "notifications"
    __table_args__ = (Index("ix_notifications_user_read", "user_id", "read_at"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    category: Mapped[str] = mapped_column(String(40), index=True)
    title: Mapped[str] = mapped_column(String(120))
    summary: Mapped[str] = mapped_column(String(300))
    request_id: Mapped[int | None] = mapped_column(ForeignKey("requests.id"))
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )


class ModelRecommendation(Base):
    __tablename__ = "model_recommendations"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    category: Mapped[str] = mapped_column(String(40))
    query_sha256: Mapped[str] = mapped_column(String(64), index=True)
    result_count: Mapped[int] = mapped_column(Integer, default=0)
    advisory_summary: Mapped[str] = mapped_column(String(300))
    model_version: Mapped[str] = mapped_column(String(60), default="deterministic-demo-v1")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class AuditEvent(Base):
    __tablename__ = "audit_events"
    __table_args__ = (Index("ix_audit_events_entity", "entity_type", "entity_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    actor_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), index=True)
    actor_role: Mapped[str] = mapped_column(String(50), default="system")
    institution_id: Mapped[int | None] = mapped_column(ForeignKey("institutions.id"))
    action: Mapped[str] = mapped_column(String(80), index=True)
    entity_type: Mapped[str] = mapped_column(String(60))
    entity_id: Mapped[str] = mapped_column(String(60))
    request_id: Mapped[str] = mapped_column(String(36), index=True)
    event_metadata: Mapped[dict[str, str | int | bool | None]] = mapped_column(
        "metadata", JSON, default=dict
    )
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )


__all__ = [
    "AuditEvent",
    "AuthorisationReference",
    "Base",
    "CoordinationCase",
    "CoordinationRequest",
    "FacilityCapability",
    "Institution",
    "LogisticsEvent",
    "ModelRecommendation",
    "Notification",
    "RefreshSession",
    "ResourceStatus",
    "ResourceType",
    "Role",
    "User",
]
