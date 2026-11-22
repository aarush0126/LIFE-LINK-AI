from sqlalchemy import select
from sqlalchemy.orm import Session, sessionmaker

from app.domain import ROLE_PERMISSIONS
from app.models import (
    FacilityCapability,
    Institution,
    ResourceStatus,
    ResourceType,
    Role,
)

SYNTHETIC_INSTITUTIONS = (
    {
        "institution_code": "DEMO-HN-1001",
        "name": "Northstar Teaching Hospital (Demo)",
        "institution_type": "teaching_hospital",
        "city": "New Delhi",
        "state": "Delhi",
    },
    {
        "institution_code": "DEMO-HN-1002",
        "name": "Cedar Valley Medical Centre (Demo)",
        "institution_type": "regional_hospital",
        "city": "Chandigarh",
        "state": "Chandigarh",
    },
    {
        "institution_code": "DEMO-HN-1003",
        "name": "Riverside Emergency & Blood Services (Demo)",
        "institution_type": "trauma_blood_centre",
        "city": "Ludhiana",
        "state": "Punjab",
    },
    {
        "institution_code": "DEMO-HN-1004",
        "name": "Meadowbrook Clinical Coordination Centre (Demo)",
        "institution_type": "specialty_centre",
        "city": "Mumbai",
        "state": "Maharashtra",
    },
    {
        "institution_code": "DEMO-HN-1005",
        "name": "Summit South Regional Hospital (Demo)",
        "institution_type": "regional_hospital",
        "city": "Chennai",
        "state": "Tamil Nadu",
    },
    {
        "institution_code": "DEMO-NETWORK",
        "name": "LIFE-LINK Demo Network",
        "institution_type": "network_administration",
        "city": "New Delhi",
        "state": "Delhi",
    },
)

SYNTHETIC_RESOURCE_TYPES = (
    ("whole_blood", "Whole blood", "blood"),
    ("packed_red_cells", "Packed red blood cells", "blood"),
    ("platelets", "Platelets", "blood"),
    ("fresh_frozen_plasma", "Fresh frozen plasma", "blood"),
    ("general", "General bed indicator", "icu"),
    ("emergency", "Emergency bed indicator", "icu"),
    ("icu", "ICU bed indicator", "icu"),
    ("pediatric_icu", "Pediatric ICU bed indicator", "icu"),
    ("ventilator", "Ventilator", "equipment"),
    ("dialysis_machine", "Dialysis machine", "equipment"),
    ("oxygen_delivery", "Oxygen delivery equipment", "equipment"),
    ("patient_monitor", "Patient monitor", "equipment"),
    ("critical_equipment", "Other critical equipment", "equipment"),
    ("transplant_coordination", "Transplant coordination capability", "organ_coordination"),
)

_CAPABILITY_SAMPLES = (
    (
        "DEMO-HN-1001",
        "packed_red_cells",
        "Synthetic packed cell listing",
        18,
        "units",
        "reported",
        "O+",
    ),
    (
        "DEMO-HN-1003",
        "platelets",
        "Synthetic platelet listing",
        7,
        "units",
        "requires_confirmation",
        "A+",
    ),
    (
        "DEMO-HN-1002",
        "icu",
        "Synthetic adult ICU indicator",
        3,
        "beds",
        "requires_confirmation",
        None,
    ),
    ("DEMO-HN-1004", "emergency", "Synthetic emergency bed indicator", 2, "beds", "reported", None),
    ("DEMO-HN-1001", "ventilator", "Synthetic ventilator listing", 4, "devices", "reported", None),
    (
        "DEMO-HN-1005",
        "dialysis_machine",
        "Synthetic dialysis listing",
        2,
        "devices",
        "requires_confirmation",
        None,
    ),
    (
        "DEMO-HN-1004",
        "oxygen_delivery",
        "Synthetic oxygen equipment listing",
        5,
        "devices",
        "reported",
        None,
    ),
    (
        "DEMO-HN-1002",
        "patient_monitor",
        "Synthetic patient monitor listing",
        6,
        "devices",
        "reported",
        None,
    ),
    (
        "DEMO-HN-1004",
        "transplant_coordination",
        "Fictional transplant coordination capability",
        None,
        "capability",
        "requires_confirmation",
        None,
    ),
)


def seed_synthetic_data(factory: sessionmaker[Session]) -> None:
    with factory.begin() as session:
        _ensure_roles(session)
        resource_types = _ensure_resource_types(session)
        institutions = _ensure_institutions(session)
        _ensure_capabilities(session, resource_types, institutions)


def seed_roles(factory: sessionmaker[Session]) -> None:
    with factory.begin() as session:
        _ensure_roles(session)


def _ensure_roles(session: Session) -> None:
    for role_name, permissions in ROLE_PERMISSIONS.items():
        role = session.scalar(select(Role).where(Role.name == role_name.value))
        if role is None:
            session.add(
                Role(
                    name=role_name.value,
                    permissions=sorted(permissions),
                    is_system_role=True,
                )
            )
        elif set(role.permissions) != permissions:
            role.permissions = sorted(permissions)


def _ensure_resource_types(session: Session) -> dict[str, ResourceType]:
    result: dict[str, ResourceType] = {}
    for key, label, category in SYNTHETIC_RESOURCE_TYPES:
        resource_type = session.scalar(select(ResourceType).where(ResourceType.key == key))
        if resource_type is None:
            resource_type = ResourceType(key=key, label=label, category=category)
            session.add(resource_type)
            session.flush()
        result[key] = resource_type
    return result


def _ensure_institutions(session: Session) -> dict[str, Institution]:
    result: dict[str, Institution] = {}
    for values in SYNTHETIC_INSTITUTIONS:
        institution = session.scalar(
            select(Institution).where(Institution.institution_code == values["institution_code"])
        )
        if institution is None:
            institution = Institution(
                **values,
                is_verified=False,
                is_active=True,
                is_demo=True,
            )
            session.add(institution)
            session.flush()
        result[institution.institution_code] = institution
    return result


def _ensure_capabilities(
    session: Session,
    resource_types: dict[str, ResourceType],
    institutions: dict[str, Institution],
) -> None:
    for (
        institution_code,
        resource_key,
        name,
        quantity,
        unit,
        state,
        blood_group,
    ) in _CAPABILITY_SAMPLES:
        institution = institutions[institution_code]
        resource_type = resource_types[resource_key]
        capability = session.scalar(
            select(FacilityCapability).where(
                FacilityCapability.institution_id == institution.id,
                FacilityCapability.resource_type_id == resource_type.id,
                FacilityCapability.name == name,
            )
        )
        if capability is None:
            capability = FacilityCapability(
                institution_id=institution.id,
                resource_type_id=resource_type.id,
                name=name,
                is_active=True,
            )
            session.add(capability)
            session.flush()
        if capability.status is None:
            capability.status = ResourceStatus(
                status=state,
                quantity=quantity,
                unit=unit,
                blood_group=blood_group,
                component=resource_type.label if resource_type.category == "blood" else None,
            )


__all__ = ["seed_roles", "seed_synthetic_data"]
