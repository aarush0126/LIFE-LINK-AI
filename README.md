# LIFE-LINK AI

LIFE-LINK AI is a healthcare coordination **prototype** with a Flutter web client and a separate FastAPI backend. Screens and seeded records are synthetic demonstrations, not live national healthcare data. The prototype does not make clinical decisions, allocate organs, guarantee resource availability, or connect to government systems.

## Flutter client

1. Copy `.env.example` to `.env` and set `API_BASE_URL` to the backend URL for the environment. The default is the local FastAPI service.
2. Install and run:

   ```powershell
   flutter pub get
   flutter run -d chrome
   ```

Demo sign-in remains a fictional, local-only flow. The Production option uses the configured backend and OAuth password-token endpoint; it sends credentials only to that configured API.

## FastAPI backend

See [backend/README.md](backend/README.md) for PostgreSQL configuration, migrations, synthetic seed data, administrator bootstrap, API documentation, and tests.

## Safety and integration status

- All included institutions and resource records are fictional demo data.
- Reported resources are enquiry indicators, never guarantees or reservations.
- Organ coordination routes are simulated and require human review; actual allocation remains with authorized authorities and medical professionals.
- No NOTTO/ROTTO/SOTTO, government, hospital registry, or other external integration is implemented.
- Configure real deployments with an approved identity provider, protected secrets, TLS, backups, monitoring, and institution-specific security review before using operational data.
