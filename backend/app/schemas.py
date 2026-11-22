from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class APIModel(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")


class UserPublic(APIModel):
    id: int
    email: EmailStr
    full_name: str
    department: str
    institution_id: int
    institution_name: str
    role: str
    is_active: bool
    is_verified: bool


class RegistrationInput(APIModel):
    email: EmailStr
    full_name: str = Field(min_length=2, max_length=160)
    department: str = Field(default="", max_length=120)
    institution_id: int = Field(gt=0)
    password: str = Field(min_length=12, max_length=128)

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, password: str) -> str:
        if not any(character.islower() for character in password):
            raise ValueError("Password must contain a lowercase letter.")
        if not any(character.isupper() for character in password):
            raise ValueError("Password must contain an uppercase letter.")
        if not any(character.isdigit() for character in password):
            raise ValueError("Password must contain a number.")
        if not any(not character.isalnum() for character in password):
            raise ValueError("Password must contain a symbol.")
        return password


class RegistrationResponse(APIModel):
    message: str
    user_id: int
    status: Literal["pending_review"]


class TokenRequest(APIModel):
    refresh_token: str = Field(min_length=20, max_length=4096)


class TokenResponse(APIModel):
    access_token: str
    refresh_token: str
    token_type: Literal["bearer"] = "bearer"
    expires_in: int
    user: UserPublic


class UserRoleUpdate(APIModel):
    role: str = Field(min_length=3, max_length=50)


class UserStatusUpdate(APIModel):
    is_active: bool
    is_verified: bool = False


class InstitutionCreate(APIModel):
    institution_code: str = Field(pattern=r"^[A-Z0-9-]{4,40}$")
    name: str = Field(min_length=3, max_length=200)
    institution_type: str = Field(min_length=2, max_length=50)
    city: str = Field(min_length=2, max_length=100)
    state: str = Field(min_length=2, max_length=100)


class InstitutionPublic(APIModel):
    id: int
    institution_code: str
    name: str
    institution_type: str
    city: str
    state: str
    is_verified: bool
    is_active: bool
    is_demo: bool


class CapabilityCreate(APIModel):
    resource_type_key: str = Field(min_length=2, max_length=60)
    name: str = Field(min_length=2, max_length=160)


class ResourceReportInput(APIModel):
    capability_id: int = Field(gt=0)
    status: Literal["reported", "requires_confirmation", "institution_confirmed"]
    quantity: int | None = Field(default=None, ge=0, le=100_000)
    unit: str = Field(default="items", min_length=1, max_length=30)
    blood_group: str | None = Field(default=None, pattern=r"^(A|B|AB|O)[+-]$")
    component: str | None = Field(default=None, max_length=60)
    urgency: Literal["routine", "urgent", "emergency"] | None = None
    expires_at: datetime | None = None


class ResourcePublic(APIModel):
    id: int
    institution_id: int
    institution_name: str
    institution_city: str
    institution_state: str
    institution_verified: bool
    capability_id: int
    capability: str
    resource_type: str
    category: str
    status: str
    quantity: int | None
    unit: str
    blood_group: str | None
    component: str | None
    urgency: str | None
    expires_at: datetime | None
    updated_at: datetime


class EnquiryCreate(APIModel):
    target_institution_id: int = Field(gt=0)
    resource_type_key: str = Field(min_length=2, max_length=60)
    quantity: int = Field(gt=0, le=100_000)
    urgency: Literal["routine", "urgent", "emergency"] = "routine"
    blood_group: str | None = Field(default=None, pattern=r"^(A|B|AB|O)[+-]$")
    component: str | None = Field(default=None, max_length=60)


class BedEnquiryCreate(APIModel):
    target_institution_id: int = Field(gt=0)
    care_category: Literal["general", "emergency", "icu", "pediatric_icu"]
    patient_transfer_reference: str = Field(pattern=r"^DEMO-[A-Z0-9-]{4,48}$")
    urgency: Literal["routine", "urgent", "emergency"] = "routine"


class EnquiryResponse(APIModel):
    request_reference: str
    status: str
    message: str
    created_at: datetime


class CoordinationCaseCreate(APIModel):
    case_reference: str = Field(pattern=r"^DEMO-[A-Z0-9-]{4,48}$")
    pathway: Literal["national_review", "regional_review", "state_review"]
    resource_category: Literal["organ", "tissue"]
    capability: str = Field(min_length=2, max_length=160)


class CoordinationCasePublic(APIModel):
    id: int
    case_reference: str
    institution_id: int
    pathway: str
    resource_category: str
    capability: str
    status: str
    verification_status: str
    created_at: datetime
    updated_at: datetime


class HumanApprovalInput(APIModel):
    approved: bool


class AuthorisationReferenceCreate(APIModel):
    pathway_level: Literal["national_review", "regional_review", "state_review"]
    reference_code: str = Field(pattern=r"^DEMO-[A-Z0-9/-]{1,45}$")


class AuthorisationReferencePublic(APIModel):
    id: int
    coordination_case_id: int
    pathway_level: str
    reference_code: str
    verification_status: str
    created_at: datetime


class LogisticsEventCreate(APIModel):
    event_type: Literal[
        "retrieval_readiness",
        "preservation_readiness",
        "transport_readiness",
        "receiving_centre_readiness",
    ]
    status: Literal["pending", "ready_for_human_review", "human_confirmed", "delayed"]


class LogisticsEventPublic(APIModel):
    id: int
    coordination_case_id: int
    event_type: str
    status: str
    occurred_at: datetime


class NotificationPublic(APIModel):
    id: int
    category: str
    title: str
    summary: str
    request_id: int | None
    is_read: bool
    created_at: datetime


class AIResourceSearchInput(APIModel):
    query: str = Field(min_length=3, max_length=300)
    category: Literal["blood", "icu", "equipment", "organ_coordination"] | None = None
    city: str | None = Field(default=None, max_length=100)
    state: str | None = Field(default=None, max_length=100)


class AIResult(APIModel):
    institution_id: int
    institution_name: str
    city: str
    state: str
    resource_type: str
    capability: str
    status: str
    quantity: int | None
    unit: str
    last_updated: datetime
    verification: str
    why_suggested: str
    uncertainty: str


class AIResourceSearchResponse(APIModel):
    mode: Literal["deterministic_demo"] = "deterministic_demo"
    advisory_only: Literal[True] = True
    results: list[AIResult]
    message: str


class AuditEventPublic(APIModel):
    id: int
    actor_role: str
    institution_id: int | None
    action: str
    entity_type: str
    entity_id: str
    request_id: str
    event_metadata: dict[str, str | int | bool | None]
    occurred_at: datetime


class PageMetadata(APIModel):
    page: int
    page_size: int
    total: int
    pages: int


class Page(APIModel):
    items: list[dict[str, object]]
    pagination: PageMetadata


class HealthResponse(APIModel):
    status: Literal["ok", "not_ready"]
    environment: str
    data_mode: Literal["synthetic_demo", "configured"]
    database: Literal["connected", "unavailable"]
