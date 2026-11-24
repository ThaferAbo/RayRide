from datetime import date, time

import pytest
from pydantic import ValidationError

from app.schemas import ExtractionResult, ReservationRequest


@pytest.fixture
def reviewed_reservation():
    return {
        "flight_number": "ZZ123",
        "arrival_airport": "AYT",
        "arrival_date": "2026-12-03",
        "arrival_local_time": "14:30",
        "destination": " Fictional Hotel ",
        "reviewed": True,
    }


def test_reviewed_reservation_preserves_airport_local_values(reviewed_reservation):
    request = ReservationRequest.model_validate(reviewed_reservation)
    assert request.arrival_date == date(2026, 12, 3)
    assert request.arrival_local_time == time(14, 30)
    assert request.destination == "Fictional Hotel"


@pytest.mark.parametrize(
    ("field", "invalid"),
    [
        ("flight_number", "12345"),
        ("arrival_airport", "invalid"),
        ("arrival_date", 1796256000),
        ("arrival_local_time", "14:30:00+03:00"),
        ("arrival_local_time", 52200),
        ("destination", " "),
        ("reviewed", False),
        ("reviewed", 1),
    ],
)
def test_reservation_rejects_invalid_or_unreviewed_fields(
    reviewed_reservation, field, invalid
):
    with pytest.raises(ValidationError, match=field):
        ReservationRequest.model_validate({**reviewed_reservation, field: invalid})


def test_extraction_contract_distinguishes_uncertain_and_missing_fields():
    candidate = {
        "method": "pdf_text",
        "flight_number": {"status": "extracted", "value": "ZZ123"},
        "arrival_airport": {"status": "uncertain", "value": "AYT"},
        "arrival_date": {"status": "missing", "value": None},
        "arrival_local_time": {"status": "uncertain", "value": None},
        "warnings": ["Review arrival airport and enter the missing date and time."],
    }
    assert (
        ExtractionResult.model_validate(candidate).model_dump(mode="json") == candidate
    )
    with pytest.raises(ValidationError, match="arrival_date"):
        ExtractionResult.model_validate(
            {
                **candidate,
                "arrival_date": {"status": "missing", "value": "2026-12-03"},
            }
        )
