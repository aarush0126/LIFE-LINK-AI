# LIFE-LINK AI FastAPI backend

Synthetic-first REST API for the LIFE-LINK AI competition prototype. The backend uses FastAPI, Pydantic, synchronous SQLAlchemy 2, PostgreSQL, JWT access tokens, persisted one-time refresh tokens, and Alembic migrations.

This service is not a clinical decision system, live allocation service, or government integration. Demo institutions/resources are fictional. Resource statuses are indications for enquiry, not availability guarantees. Organ coordination is simulated, advisory, and human-gated.

## Setup

Requirements: Python 3.12+ and PostgreSQL for non-test use.

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e ".[dev]"
Copy-Item .env.example .env
```

Set `DATABASE_URL` to a PostgreSQL database and generate a private JWT key (do not commit it):

```powershell
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Put the generated value in the ignored `backend/.env` as `JWT_SECRET_KEY`. Configure database access in the same file. Self-registration is disabled by default; accounts created through registration remain inactive and unverified pending institutional review.

## Migrations, demo data, and administrator bootstrap

```powershell
alembic upgrade head
python -m app.cli seed
python -m app.cli create-admin --email admin@example.com
```

`create-admin` prompts interactively for a name and a policy-compliant password; it does not accept or log passwords on the command line. The first bootstrap administrator is assigned to the synthetic network institution. Later privileged accounts must be provisioned through a separately approved process.

For production, do **not** run the demo `seed` command. Run `python -m app.cli seed-roles`, bootstrap the initial institution with `create-institution --code ... --name ... --institution-type ... --city ... --state ...`, then pass its code to `create-admin --institution-code <approved-code>`. The institution starts unverified and must complete institutional verification before operational use. Synthetic seed data is refused when `APP_ENV=production`.

## Run and inspect

```powershell
uvicorn app.main:app --reload
```

- Liveness: `GET /health/live`
- Readiness: `GET /health/ready`
- OpenAPI UI: `http://127.0.0.1:8000/api/v1/docs`

The client uses `API_BASE_URL=http://127.0.0.1:8000/api/v1` by default; set that variable in the Flutter environment file for another deployment.

## API areas

All module endpoints are under `/api/v1`. Authentication uses OAuth2 form-encoded credentials at `POST /auth/token`, then bearer tokens. Refresh tokens rotate at `POST /auth/refresh`; `POST /auth/logout` revokes the presented refresh token. Protected endpoints enforce role permissions on the server.

| Area | Routes |
|---|---|
| Auth | `/auth/register`, `/auth/token`, `/auth/refresh`, `/auth/logout`, `/auth/me` |
| Users and registry | `/roles`, `/users`, `/hospitals`, `/hospitals/{id}/capabilities` |
| Resource discovery | `/blood-bank/inventory`, `/icu-beds`, `/equipment`, `/resources/status`, and module enquiry routes |
| Organ coordination | `/coordination-cases`, case detail, approval, simulated routing, and logistics routes |
| Notifications | `/notifications` and notification read state |
| Advisory AI | `/ai/resource-search`, `/ai/data-quality`, `/ai/operational-summary` |
| Administration | `/admin/audit-events`, `/admin/system-health` |

Endpoints use bounded pagination and filtering where applicable. Structured errors include a request ID. The API does not expose raw AI prompts in the audit/recommendation record; only a one-way query hash is stored.

## Tests and lint

Tests use isolated SQLite databases; production configuration requires PostgreSQL.

```powershell
pytest
ruff check .
```

No government, NOTTO/ROTTO/SOTTO, hospital directory, or external identity integration is configured.
