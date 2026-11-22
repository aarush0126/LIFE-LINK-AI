from app.models import Institution, ResourceStatus, User


def present_user(user: User) -> dict[str, object]:
    return {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "department": user.department,
        "institution_id": user.institution_id,
        "institution_name": user.institution.name,
        "role": user.role.name,
        "is_active": user.is_active,
        "is_verified": user.is_verified,
    }


def present_institution(institution: Institution) -> dict[str, object]:
    return {
        "id": institution.id,
        "institution_code": institution.institution_code,
        "name": institution.name,
        "institution_type": institution.institution_type,
        "city": institution.city,
        "state": institution.state,
        "is_verified": institution.is_verified,
        "is_active": institution.is_active,
        "is_demo": institution.is_demo,
    }


def present_resource(status: ResourceStatus) -> dict[str, object]:
    capability = status.capability
    institution = capability.institution
    return {
        "id": status.id,
        "institution_id": institution.id,
        "institution_name": institution.name,
        "institution_city": institution.city,
        "institution_state": institution.state,
        "institution_verified": institution.is_verified,
        "capability_id": capability.id,
        "capability": capability.name,
        "resource_type": capability.resource_type.label,
        "category": capability.resource_type.category,
        "status": status.status,
        "quantity": status.quantity,
        "unit": status.unit,
        "blood_group": status.blood_group,
        "component": status.component,
        "urgency": status.urgency,
        "expires_at": status.expires_at,
        "updated_at": status.updated_at,
    }
