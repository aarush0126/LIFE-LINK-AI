from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import sessionmaker

from app.config import Settings, get_settings
from app.db import create_database_engine, create_session_factory
from app.errors import install_error_handlers
from app.routers import admin, ai, auth, coordination, notifications, registry, resources

API_PREFIX = "/api/v1"


def create_app(
    settings: Settings | None = None,
    session_factory: sessionmaker | None = None,
) -> FastAPI:
    resolved_settings = settings or get_settings()
    engine_holder = {"engine": None}

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        resolved_settings.validate_runtime()
        if app.state.session_factory is None:
            engine = create_database_engine(resolved_settings)
            engine_holder["engine"] = engine
            app.state.session_factory = create_session_factory(engine)
        yield
        engine = engine_holder["engine"]
        if engine is not None:
            engine.dispose()

    app = FastAPI(
        title=resolved_settings.app_name,
        version="0.1.0",
        description=(
            "Synthetic-first healthcare resource coordination API. "
            "This prototype is not a clinical decision system and has no government integrations."
        ),
        docs_url=f"{API_PREFIX}/docs",
        redoc_url=f"{API_PREFIX}/redoc",
        openapi_url=f"{API_PREFIX}/openapi.json",
        lifespan=lifespan,
    )
    app.state.settings = resolved_settings
    app.state.session_factory = session_factory
    app.add_middleware(
        CORSMiddleware,
        allow_origins=resolved_settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=[
            "Authorization",
            "Content-Type",
            "X-Client-Version",
            "X-Platform",
            "X-Request-ID",
        ],
        expose_headers=["X-Request-ID"],
    )
    install_error_handlers(app)
    for route_module in (
        auth,
        registry,
        resources,
        coordination,
        notifications,
        ai,
        admin,
    ):
        app.include_router(route_module.router, prefix=API_PREFIX)

    @app.get("/health/live", tags=["System"])
    def liveness() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/health/ready", tags=["System"])
    def readiness(request: Request):
        factory: sessionmaker = request.app.state.session_factory
        try:
            with factory() as session:
                session.execute(select(1))
        except SQLAlchemyError:
            return JSONResponse(
                status_code=503,
                content={"status": "not_ready", "database": "unavailable"},
            )
        return {
            "status": "ok",
            "environment": resolved_settings.app_env,
            "database": "connected",
            "data_mode": (
                "synthetic_demo"
                if resolved_settings.app_env in {"development", "test"}
                else "configured"
            ),
            "government_integrations": "not_configured",
        }

    return app


app = create_app()
