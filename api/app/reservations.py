import re
from base64 import b32encode
from datetime import UTC
from hashlib import sha256
from secrets import token_bytes
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Path, Request, Response
from pydantic import UUID4, TypeAdapter, ValidationError
from sqlalchemy.dialects.sqlite import insert
from sqlalchemy.engine import Engine
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool
from starlette.requests import ClientDisconnect

from .db import Reservation
from .schemas import (
    REFERENCE_PATTERN,
    ReservationErrorResponse,
    ReservationRequest,
    ReservationResponse,
)

router = APIRouter(prefix="/api/v1/reservations", tags=["reservations"])
_MAX_JSON_BYTES = 8 * 1024
_UUID4 = TypeAdapter(UUID4)
_FIELD_MESSAGES = {
    "flight_number": "Enter a flight number such as ZZ731.",
    "arrival_airport": "Enter a three-letter airport code such as AYT.",
    "arrival_date": "Enter a valid arrival date.",
    "arrival_local_time": "Enter the local arrival time without a time zone or offset.",
    "destination": "Enter a destination of up to 200 characters.",
    "reviewed": "Confirm that you reviewed the trip details.",
}


def _error(
    status: int, code: str, message: str, fields: dict[str, str] | None = None
) -> HTTPException:
    detail: dict[str, object] = {"code": code, "message": message}
    if fields:
        detail["fields"] = fields
    return HTTPException(
        status_code=status, detail=detail, headers={"Cache-Control": "no-store"}
    )


async def _reviewed_request(request: Request) -> ReservationRequest:
    content_type = (
        request.headers.get("content-type", "").split(";", 1)[0].strip().lower()
    )
    if content_type != "application/json":
        raise _error(415, "invalid_content_type", "Send reservation details as JSON.")

    body = bytearray()
    try:
        async for chunk in request.stream():
            if len(body) + len(chunk) > _MAX_JSON_BYTES:
                raise _error(
                    413, "request_too_large", "The reservation request is too large."
                )
            body.extend(chunk)
    except ClientDisconnect as exc:
        raise _error(
            422, "invalid_reservation", "The reservation request was incomplete."
        ) from exc
    try:
        return ReservationRequest.model_validate_json(body)
    except ValidationError as exc:
        fields = {
            error["loc"][0]: _FIELD_MESSAGES[error["loc"][0]]
            for error in exc.errors(include_input=False, include_context=False)
            if error["loc"] and error["loc"][0] in _FIELD_MESSAGES
        }
        raise _error(
            422,
            "invalid_reservation",
            "Check your trip details and confirm your review.",
            fields,
        ) from exc


def _idempotency_key(request: Request) -> UUID | None:
    value = request.headers.get("idempotency-key")
    if value is None:
        return None
    try:
        return _UUID4.validate_python(value)
    except ValidationError as exc:
        raise _error(
            422, "invalid_reservation", "The reservation retry key is invalid."
        ) from exc


def _new_reference(key: UUID | None) -> str:
    entropy = sha256(key.bytes).digest() if key else token_bytes(8)
    return "RR-" + b32encode(entropy).decode("ascii")[:12]


def _confirmation(record: Reservation) -> ReservationResponse:
    return ReservationResponse(
        reference=record.reference,
        flight_number=record.flight_number,
        arrival_airport=record.arrival_airport,
        arrival_date=record.arrival_date,
        arrival_local_time=record.arrival_local_time,
        destination=record.destination,
        status=record.status,
        created_at=record.created_at_utc.replace(tzinfo=UTC),
    )


def _save(
    engine: Engine, payload: ReservationRequest, key: UUID | None
) -> tuple[ReservationResponse, bool]:
    details = payload.model_dump(exclude={"reviewed"})
    with Session(engine) as session:
        for _ in range(1 if key else 5):
            reference = _new_reference(key)
            operation = (
                insert(Reservation)
                .values(reference=reference, **details)
                .on_conflict_do_nothing(index_elements=[Reservation.reference])
                .returning(Reservation)
            )
            record = session.scalars(operation).one_or_none()
            if record is not None:
                confirmation = _confirmation(record)
                session.commit()
                return confirmation, True
            if key:
                existing = session.get(Reservation, reference)
                if existing is not None and all(
                    getattr(existing, name) == value for name, value in details.items()
                ):
                    return _confirmation(existing), False
                raise _error(
                    409,
                    "reservation_conflict",
                    "This reservation retry key belongs to different trip details.",
                )
    raise _error(
        503,
        "reservation_unavailable",
        "A reservation reference could not be assigned. Please try again.",
    )


@router.post(
    "",
    status_code=201,
    response_model=ReservationResponse,
    responses={
        200: {
            "model": ReservationResponse,
            "description": "Saved reservation returned for an identical retry",
        },
        **{
            status: {"model": ReservationErrorResponse}
            for status in (409, 413, 415, 422, 503)
        },
    },
    openapi_extra={
        "requestBody": {
            "required": True,
            "content": {
                "application/json": {
                    "schema": {"$ref": "#/components/schemas/ReservationRequest"},
                }
            },
        },
        "parameters": [
            {
                "in": "header",
                "name": "Idempotency-Key",
                "required": False,
                "schema": {"type": "string", "format": "uuid"},
                "description": "Optional version 4 UUID. Reuse it for identical retries.",
            }
        ],
    },
)
async def create_reservation(
    request: Request, response: Response
) -> ReservationResponse:
    key = _idempotency_key(request)
    payload = await _reviewed_request(request)
    try:
        confirmation, created = await run_in_threadpool(
            _save, request.app.state.engine, payload, key
        )
    except SQLAlchemyError as exc:
        raise _error(
            503,
            "reservation_unavailable",
            "We couldn't save the reservation. Try again with the same trip details.",
        ) from exc
    response.status_code = 201 if created else 200
    response.headers["Location"] = f"/api/v1/reservations/{confirmation.reference}"
    response.headers["Cache-Control"] = "no-store"
    return confirmation


@router.get(
    "/{reference}",
    responses={
        status: {"model": ReservationErrorResponse} for status in (404, 422, 503)
    },
)
def get_reservation(
    request: Request,
    response: Response,
    reference: Annotated[str, Path(json_schema_extra={"pattern": REFERENCE_PATTERN})],
) -> ReservationResponse:
    if not re.fullmatch(REFERENCE_PATTERN, reference):
        raise _error(
            422, "invalid_reservation", "Enter a reference such as RR-ABC123DEF456."
        )
    try:
        with Session(request.app.state.engine) as session:
            record = session.get(Reservation, reference)
            if record is None:
                raise _error(
                    404,
                    "reservation_not_found",
                    "No reservation matches that reference.",
                )
            confirmation = _confirmation(record)
    except SQLAlchemyError as exc:
        raise _error(
            503,
            "reservation_unavailable",
            "We couldn't load the reservation. Please try again.",
        ) from exc
    response.headers["Cache-Control"] = "no-store"
    return confirmation
