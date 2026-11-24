import re
from datetime import date, datetime, time
from typing import Annotated, Generic, Literal, TypeVar

from pydantic import (
    AfterValidator,
    AwareDatetime,
    BaseModel,
    BeforeValidator,
    ConfigDict,
    Field,
    StringConstraints,
    WithJsonSchema,
    field_validator,
)

FLIGHT_NUMBER_PATTERN = r"^(?:[A-Z][A-Z0-9]|[0-9][A-Z])[0-9]{1,4}[A-Z]?$"
FlightNumber = Annotated[str, StringConstraints(pattern=FLIGHT_NUMBER_PATTERN)]
AirportCode = Annotated[str, StringConstraints(pattern=r"^[A-Z]{3}$")]
Destination = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=200)
]
REFERENCE_PATTERN = r"^RR-[A-Z0-9]{12}$"
Reference = Annotated[str, StringConstraints(pattern=REFERENCE_PATTERN)]
TicketMediaType = Literal["application/pdf", "image/png", "image/jpeg"]
ExtractionMethod = Literal["pdf_text", "ocr", "mixed", "unavailable"]

_LOCAL_TIME_PATTERN = (
    r"^(?:[01][0-9]|2[0-3]):[0-5][0-9](?::[0-5][0-9](?:\.[0-9]{1,6})?)?$"
)


def _iso_date(value: object) -> object:
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    if (
        not isinstance(value, str)
        or re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}", value) is None
    ):
        raise ValueError("Use an ISO 8601 date in YYYY-MM-DD form.")
    return value


def _iso_local_time(value: object) -> object:
    if isinstance(value, time):
        return value
    if not isinstance(value, str) or re.fullmatch(_LOCAL_TIME_PATTERN, value) is None:
        raise ValueError("Use an ISO 8601 clock time without a UTC offset.")
    return value


def _no_time_offset(value: time) -> time:
    if value.tzinfo is not None:
        raise ValueError(
            "Arrival time must be local to the airport and have no UTC offset."
        )
    return value


ArrivalDate = Annotated[date, BeforeValidator(_iso_date)]
ArrivalLocalTime = Annotated[
    time,
    BeforeValidator(_iso_local_time),
    AfterValidator(_no_time_offset),
    WithJsonSchema(
        {
            "type": "string",
            "pattern": _LOCAL_TIME_PATTERN,
            "description": "Clock time at the arrival airport, without a UTC offset.",
            "examples": ["14:30", "14:30:00"],
        }
    ),
]


class HealthResponse(BaseModel):
    status: Literal["ok"]
    database: Literal["ready"]


class ErrorDetail(BaseModel):
    code: Literal["database_unavailable"]
    message: str


class ErrorResponse(BaseModel):
    detail: ErrorDetail


class TicketErrorDetail(BaseModel):
    code: Literal[
        "invalid_upload",
        "upload_too_large",
        "unsupported_ticket_type",
        "invalid_ticket",
    ]
    message: str


class TicketErrorResponse(BaseModel):
    detail: TicketErrorDetail


Value = TypeVar("Value")


class Extracted(BaseModel, Generic[Value]):
    status: Literal["extracted"]
    value: Value


class Uncertain(BaseModel, Generic[Value]):
    status: Literal["uncertain"]
    value: Value | None


class Missing(BaseModel):
    status: Literal["missing"]
    value: None


class ExtractionResult(BaseModel):
    """Editable ticket suggestions. All times are local to the arrival airport."""

    method: ExtractionMethod
    flight_number: Extracted[FlightNumber] | Uncertain[FlightNumber] | Missing = Field(
        discriminator="status"
    )
    arrival_airport: Extracted[AirportCode] | Uncertain[AirportCode] | Missing = Field(
        discriminator="status"
    )
    arrival_date: Extracted[ArrivalDate] | Uncertain[ArrivalDate] | Missing = Field(
        discriminator="status"
    )
    arrival_local_time: (
        Extracted[ArrivalLocalTime] | Uncertain[ArrivalLocalTime] | Missing
    ) = Field(discriminator="status")
    warnings: list[str]


class ReservationDetails(BaseModel):
    flight_number: FlightNumber
    arrival_airport: AirportCode
    arrival_date: ArrivalDate
    arrival_local_time: ArrivalLocalTime
    destination: Destination


class ReservationRequest(ReservationDetails):
    """Reservation request using data explicitly reviewed by the traveler."""

    model_config = ConfigDict(extra="forbid")

    reviewed: Literal[True]

    @field_validator("reviewed", mode="before")
    @classmethod
    def require_explicit_review(cls, value: object) -> object:
        if value is not True:
            raise ValueError("Traveler review is required.")
        return value


class ReservationResponse(ReservationDetails):
    """Confirmation for a saved simulated reservation."""

    reference: Reference
    status: Literal["simulated"]
    created_at: AwareDatetime


class ReservationErrorDetail(BaseModel):
    code: Literal[
        "invalid_reservation",
        "reservation_not_found",
        "reservation_conflict",
        "reservation_unavailable",
        "invalid_content_type",
        "request_too_large",
    ]
    message: str
    fields: dict[str, str] | None = None


class ReservationErrorResponse(BaseModel):
    detail: ReservationErrorDetail
