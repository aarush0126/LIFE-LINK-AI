from enum import StrEnum


class RoleName(StrEnum):
    PENDING_REVIEW = "pending_review"
    HOSPITAL_ADMINISTRATOR = "hospital_administrator"
    TRANSPLANT_COORDINATOR = "transplant_coordinator"
    BLOOD_BANK_OFFICER = "blood_bank_officer"
    EMERGENCY_ICU_COORDINATOR = "emergency_icu_coordinator"
    EQUIPMENT_COORDINATOR = "equipment_coordinator"
    NETWORK_ADMINISTRATOR = "network_administrator"
    AUDITOR_COMPLIANCE_OFFICER = "auditor_compliance_officer"


class ResourceCategory(StrEnum):
    BLOOD = "blood"
    ICU = "icu"
    EQUIPMENT = "equipment"
    ORGAN_COORDINATION = "organ_coordination"


class ResourceStatusName(StrEnum):
    REPORTED = "reported"
    REQUIRES_CONFIRMATION = "requires_confirmation"
    INSTITUTION_CONFIRMED = "institution_confirmed"


class RequestStatus(StrEnum):
    ENQUIRY_LOGGED = "enquiry_logged"
    AWAITING_INSTITUTION_RESPONSE = "awaiting_institution_response"
    RESPONSE_RECORDED = "response_recorded"
    CLOSED = "closed"


class VerificationStatus(StrEnum):
    PENDING = "pending"
    INSTITUTION_REPORTED = "institution_reported"
    DEMO_VERIFIED = "demo_verified"


ROLE_PERMISSIONS: dict[RoleName, set[str]] = {
    RoleName.PENDING_REVIEW: set(),
    RoleName.HOSPITAL_ADMINISTRATOR: {
        "hospitals:read",
        "blood:read",
        "blood:enquire",
        "blood:report",
        "icu:read",
        "icu:enquire",
        "icu:report",
        "equipment:read",
        "equipment:enquire",
        "equipment:report",
        "notifications:read",
        "reports:read",
        "ai:use",
    },
    RoleName.TRANSPLANT_COORDINATOR: {
        "hospitals:read",
        "organ:read",
        "organ:coordinate",
        "notifications:read",
        "ai:use",
    },
    RoleName.BLOOD_BANK_OFFICER: {
        "hospitals:read",
        "blood:read",
        "blood:enquire",
        "blood:report",
        "notifications:read",
        "ai:use",
    },
    RoleName.EMERGENCY_ICU_COORDINATOR: {
        "hospitals:read",
        "blood:read",
        "icu:read",
        "icu:enquire",
        "icu:report",
        "equipment:read",
        "equipment:enquire",
        "equipment:report",
        "notifications:read",
        "ai:use",
    },
    RoleName.EQUIPMENT_COORDINATOR: {
        "hospitals:read",
        "equipment:read",
        "equipment:enquire",
        "equipment:report",
        "notifications:read",
        "ai:use",
    },
    RoleName.NETWORK_ADMINISTRATOR: {
        "hospitals:read",
        "hospitals:manage",
        "users:manage",
        "roles:read",
        "blood:read",
        "blood:enquire",
        "icu:read",
        "icu:enquire",
        "equipment:read",
        "equipment:enquire",
        "blood:report",
        "icu:report",
        "equipment:report",
        "organ:read",
        "organ:coordinate",
        "notifications:read",
        "audit:read",
        "reports:read",
        "ai:use",
    },
    RoleName.AUDITOR_COMPLIANCE_OFFICER: {
        "hospitals:read",
        "roles:read",
        "notifications:read",
        "audit:read",
        "reports:read",
    },
}

ASSIGNABLE_ROLE_NAMES = {
    RoleName.HOSPITAL_ADMINISTRATOR,
    RoleName.TRANSPLANT_COORDINATOR,
    RoleName.BLOOD_BANK_OFFICER,
    RoleName.EMERGENCY_ICU_COORDINATOR,
    RoleName.EQUIPMENT_COORDINATOR,
}
