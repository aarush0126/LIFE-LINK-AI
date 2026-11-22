from conftest import APIContext, auth_headers, sign_in
from sqlalchemy import select
from sqlalchemy.orm import Session, sessionmaker

from app.cli import _create_institution
from app.domain import RoleName
from app.models import AuditEvent, Institution, User


def test_login_refresh_rotation_and_role_permissions(api_context: APIContext) -> None:
    client = api_context.client
    access_token, old_refresh_token = sign_in(client, api_context.user_emails["transplant"])

    profile = client.get("/api/v1/auth/me", headers=auth_headers(access_token))
    assert profile.status_code == 200
    assert profile.json()["role"] == RoleName.TRANSPLANT_COORDINATOR.value

    denied = client.get(
        "/api/v1/blood-bank/inventory",
        headers=auth_headers(access_token),
    )
    assert denied.status_code == 403

    rotated = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": old_refresh_token},
    )
    assert rotated.status_code == 200
    assert rotated.json()["refresh_token"] != old_refresh_token

    replayed = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": old_refresh_token},
    )
    assert replayed.status_code == 401


def test_synthetic_resource_search_and_data_quality(api_context: APIContext) -> None:
    client = api_context.client
    access_token, _ = sign_in(client, api_context.user_emails["blood"])
    headers = auth_headers(access_token)

    inventory = client.get("/api/v1/blood-bank/inventory", headers=headers)
    assert inventory.status_code == 200
    rows = inventory.json()["items"]
    assert rows
    assert all(
        row["status"] in {"reported", "requires_confirmation", "institution_confirmed"}
        for row in rows
    )
    assert all("updated_at" in row and "institution_verified" in row for row in rows)

    summary = client.get("/api/v1/ai/data-quality?category=blood", headers=headers)
    assert summary.status_code == 200
    assert summary.json()["mode"] == "deterministic_demo"
    assert summary.json()["advisory_only"] is True


def test_transplant_search_is_capability_only_and_advisory(
    api_context: APIContext,
) -> None:
    client = api_context.client
    access_token, _ = sign_in(client, api_context.user_emails["transplant"])
    response = client.post(
        "/api/v1/ai/resource-search",
        headers=auth_headers(access_token),
        json={
            "query": "transplant coordination",
            "category": "organ_coordination",
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["advisory_only"] is True
    assert body["mode"] == "deterministic_demo"
    assert body["results"]
    assert all(
        "pending" in result["verification"] and "contact the institution" in result["uncertainty"]
        for result in body["results"]
    )


def test_enquiry_is_scoped_and_notifies_only_target_institution(
    api_context: APIContext,
) -> None:
    client = api_context.client
    hospital_token, _ = sign_in(client, api_context.user_emails["hospital"])
    target_token, _ = sign_in(client, api_context.user_emails["blood"])
    response = client.post(
        "/api/v1/blood-bank/enquiries",
        headers=auth_headers(hospital_token),
        json={
            "target_institution_id": api_context.institution_ids["DEMO-HN-1003"],
            "resource_type_key": "platelets",
            "quantity": 2,
            "urgency": "urgent",
            "blood_group": "O+",
            "component": "Platelets",
        },
    )
    assert response.status_code == 201
    assert response.json()["status"] == "awaiting_institution_response"
    assert "not a reservation" in response.json()["message"]
    requests = client.get(
        "/api/v1/blood-bank/enquiries",
        headers=auth_headers(hospital_token),
    )
    assert requests.status_code == 200
    assert requests.json()["items"][0]["blood_group"] == "O+"
    assert requests.json()["items"][0]["component"] == "Platelets"

    target_notifications = client.get(
        "/api/v1/notifications",
        headers=auth_headers(target_token),
    )
    assert target_notifications.status_code == 200
    notification = target_notifications.json()["items"][0]
    assert notification["category"] == "new_coordination_enquiry"

    hospital_notifications = client.get(
        "/api/v1/notifications",
        headers=auth_headers(hospital_token),
    )
    assert hospital_notifications.status_code == 200
    assert hospital_notifications.json()["items"] == []

    mismatched_equipment_enquiry = client.post(
        "/api/v1/equipment/enquiries",
        headers=auth_headers(hospital_token),
        json={
            "target_institution_id": api_context.institution_ids["DEMO-HN-1003"],
            "resource_type_key": "ventilator",
            "quantity": 1,
            "blood_group": "O+",
            "component": "Platelets",
        },
    )
    assert mismatched_equipment_enquiry.status_code == 422
    assert mismatched_equipment_enquiry.json()["error"]["code"] == "resource_fields_mismatch"


def test_organ_workflow_requires_synthetic_reference_and_human_approval(
    api_context: APIContext,
) -> None:
    client = api_context.client
    access_token, _ = sign_in(client, api_context.user_emails["transplant"])
    headers = auth_headers(access_token)

    invalid_case = client.post(
        "/api/v1/coordination-cases",
        headers=headers,
        json={
            "case_reference": "LIVE-CASE-101",
            "pathway": "regional_review",
            "resource_category": "organ",
            "capability": "retrieval coordination",
        },
    )
    assert invalid_case.status_code == 422

    created = client.post(
        "/api/v1/coordination-cases",
        headers=headers,
        json={
            "case_reference": "DEMO-CASE-10001",
            "pathway": "regional_review",
            "resource_category": "organ",
            "capability": "retrieval coordination",
        },
    )
    assert created.status_code == 201
    case_id = created.json()["id"]

    route_before_review = client.post(
        f"/api/v1/coordination-cases/{case_id}/simulated-route",
        headers=headers,
    )
    assert route_before_review.status_code == 409
    assert route_before_review.json()["error"]["code"] == "human_approval_required"

    approved = client.post(
        f"/api/v1/coordination-cases/{case_id}/human-approval",
        headers=headers,
        json={"approved": True},
    )
    assert approved.status_code == 200
    assert approved.json()["status"] == "awaiting_institution_response"

    reference = client.post(
        f"/api/v1/coordination-cases/{case_id}/authorisation-references",
        headers=headers,
        json={"pathway_level": "regional_review", "reference_code": "DEMO-REF-01"},
    )
    assert reference.status_code == 201
    assert reference.json()["verification_status"] == "not_verified"

    routed = client.post(
        f"/api/v1/coordination-cases/{case_id}/simulated-route",
        headers=headers,
    )
    assert routed.status_code == 200
    assert routed.json()["status"] == "simulated_routing_requested"


def test_registration_starts_without_permissions(api_context: APIContext) -> None:
    context = api_context
    settings = context.client.app.state.settings
    disabled = context.client.post(
        "/api/v1/auth/register",
        json={
            "email": "new.user@example.com",
            "full_name": "New Demo User",
            "institution_id": context.institution_ids["DEMO-HN-1001"],
            "password": "StrongDemoPassword123!",
        },
    )
    assert disabled.status_code == 403

    settings.allow_self_registration = True
    response = context.client.post(
        "/api/v1/auth/register",
        json={
            "email": "new.user@example.com",
            "full_name": "New Demo User",
            "department": "Operations",
            "institution_id": context.institution_ids["DEMO-HN-1001"],
            "password": "StrongDemoPassword123!",
        },
    )
    assert response.status_code == 202
    with context.client.app.state.session_factory() as session:
        user = session.scalar(select(User).where(User.email == "new.user@example.com"))
        assert user is not None
        assert user.is_active is False
        assert user.is_verified is False
        assert user.role.name == RoleName.PENDING_REVIEW.value
        assert user.role.permissions == []


def test_health_and_openapi_are_available(api_context: APIContext) -> None:
    client = api_context.client
    assert client.get("/health/live").json() == {"status": "ok"}
    ready = client.get("/health/ready")
    assert ready.status_code == 200
    assert ready.json()["database"] == "connected"
    assert ready.json()["government_integrations"] == "not_configured"
    assert client.get("/api/v1/openapi.json").status_code == 200


def test_cors_allows_flutter_client_headers(api_context: APIContext) -> None:
    response = api_context.client.options(
        "/api/v1/auth/token",
        headers={
            "Origin": "http://localhost:5000",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": (
                "authorization,content-type,x-client-version,x-platform"
            ),
        },
    )
    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:5000"
    assert "x-platform" in response.headers["access-control-allow-headers"].lower()


def test_bootstrap_institution_is_unverified_and_audited(
    api_context: APIContext,
) -> None:
    factory: sessionmaker[Session] = api_context.client.app.state.session_factory
    with factory() as session:
        _create_institution(
            session,
            code="BOOTSTRAP-HOSPITAL-01",
            name="Bootstrap Hospital",
            institution_type="regional_hospital",
            city="Chandigarh",
            state="Chandigarh",
        )
    with factory() as session:
        institution = session.scalar(
            select(Institution).where(Institution.institution_code == "BOOTSTRAP-HOSPITAL-01")
        )
        assert institution is not None
        assert institution.is_demo is False
        assert institution.is_verified is False
        audit = session.scalar(
            select(AuditEvent).where(AuditEvent.action == "institution_bootstrapped")
        )
        assert audit is not None


def test_resource_reporting_cannot_cross_institution_boundary(
    api_context: APIContext,
) -> None:
    client = api_context.client
    hospital_token, _ = sign_in(client, api_context.user_emails["hospital"])
    # This capability belongs to a different institution (the demo blood centre).
    inventory = client.get(
        "/api/v1/blood-bank/inventory",
        headers=auth_headers(hospital_token),
    )
    assert inventory.status_code == 200
    target = next(
        row
        for row in inventory.json()["items"]
        if row["institution_id"] == api_context.institution_ids["DEMO-HN-1003"]
    )
    response = client.post(
        "/api/v1/resources/status",
        headers=auth_headers(hospital_token),
        json={
            "capability_id": target["capability_id"],
            "status": "reported",
            "quantity": 4,
            "unit": "units",
            "blood_group": "O+",
            "component": "Platelets",
        },
    )
    assert response.status_code == 403
    assert response.json()["error"]["code"] == "institution_scope_denied"
