from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from pydantic.json_schema import models_json_schema
from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError

from .db import Reservation, initialize_database
from .schemas import (
    ErrorDetail,
    ErrorResponse,
    ExtractionResult,
    HealthResponse,
    ReservationRequest,
    ReservationResponse,
)
from .settings import Settings


def create_app(settings: Settings | None = None) -> FastAPI:
    configuration = settings if settings is not None else Settings()

    @asynccontextmanager
    async def lifespan(application: FastAPI) -> AsyncIterator[None]:
        engine = initialize_database(configuration.resolved_database_path)
        application.state.engine = engine
        try:
            yield
        finally:
            engine.dispose()

    application = FastAPI(
        title="RayRide CSE491 API",
        version="0.1.0",
        description=(
            "Phase 1 exposes health only. Ticket and reservation schemas describe planned contracts."
        ),
        lifespan=lifespan,
    )

    @application.get("/health", responses={503: {"model": ErrorResponse}})
    def health(request: Request) -> HealthResponse:
        try:
            with request.app.state.engine.connect() as connection:
                connection.execute(select(Reservation.reference).limit(1))
        except SQLAlchemyError as exc:
            detail = ErrorDetail(
                code="database_unavailable", message="SQLite is unavailable."
            )
            raise HTTPException(status_code=503, detail=detail.model_dump()) from exc
        return HealthResponse(status="ok", database="ready")

    # Publish planned components alongside the live route without exposing placeholder endpoints.
    default_openapi = application.openapi

    def openapi():
        document = default_openapi()
        _, definitions = models_json_schema(
            [
                (ExtractionResult, "serialization"),
                (ReservationRequest, "validation"),
                (ReservationResponse, "serialization"),
            ],
            ref_template="#/components/schemas/{model}",
        )
        document["components"]["schemas"].update(definitions["$defs"])
        return document

    application.openapi = openapi
    return application


app = create_app()
