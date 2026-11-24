from asyncio import Semaphore
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from pydantic.json_schema import models_json_schema
from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from starlette.concurrency import run_in_threadpool

from .db import Reservation, initialize_database
from .extraction import LocalTicketExtractor, TicketExtractor
from .schemas import (
    ErrorDetail,
    ErrorResponse,
    ExtractionResult,
    HealthResponse,
    ReservationRequest,
    ReservationResponse,
    TicketErrorResponse,
)
from .settings import Settings
from .ticket_upload import TicketError, read_ticket_upload

_TICKET_ERRORS = {
    400: ("invalid_upload", "Missing or malformed multipart file"),
    413: ("upload_too_large", "Upload or document exceeds a supported limit"),
    415: ("unsupported_ticket_type", "Unsupported or mismatched file type"),
    422: ("invalid_ticket", "Corrupt, empty, or unsupported document"),
}
_TICKET_BODY = {
    "required": True,
    "content": {
        "multipart/form-data": {
            "schema": {
                "type": "object",
                "additionalProperties": False,
                "required": ["ticket"],
                "properties": {"ticket": {"type": "string", "format": "binary"}},
            },
            "encoding": {
                "ticket": {"contentType": "application/pdf, image/png, image/jpeg"}
            },
        }
    },
}


def create_app(settings: Settings | None = None) -> FastAPI:
    configuration = settings if settings is not None else Settings()
    extractor: TicketExtractor = LocalTicketExtractor(
        executable=configuration.tesseract_executable,
        timeout_seconds=configuration.ocr_timeout_seconds,
    )
    ticket_slots = Semaphore(2)

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
        version="0.2.0",
        description=(
            "Local API health and editable flight-ticket suggestions. Reservation schemas describe planned contracts."
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

    @application.post(
        "/api/v1/tickets/extract",
        summary="Extract flight suggestions from a PDF, PNG, or JPEG ticket",
        responses={
            status: {"model": TicketErrorResponse, "description": description}
            for status, (_, description) in _TICKET_ERRORS.items()
        },
        openapi_extra={"requestBody": _TICKET_BODY},
    )
    async def extract_ticket(request: Request) -> ExtractionResult:
        """Returns editable suggestions. OCR failures and unreadable fields can be entered manually."""
        try:
            async with ticket_slots:
                ticket = await read_ticket_upload(request)
                return await run_in_threadpool(
                    extractor.extract, ticket.content, media_type=ticket.media_type
                )
        except TicketError as exc:
            code, _ = _TICKET_ERRORS[exc.status]
            raise HTTPException(
                status_code=exc.status, detail={"code": code, "message": str(exc)}
            ) from exc

    # Publish planned components alongside the live route without exposing placeholder endpoints.
    default_openapi = application.openapi

    def openapi():
        document = default_openapi()
        _, definitions = models_json_schema(
            [
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
