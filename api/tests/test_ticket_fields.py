import pytest

from app.ticket_fields import TicketLine, parse_ticket


def test_departure_values_and_an_unqualified_date_are_never_used_as_arrival():
    result = parse_ticket(
        [
            [
                TicketLine("Flight: ZZ 171"),
                TicketLine("Departure: IST 2026-12-13 09:02 | Arrival airport: AYT"),
                TicketLine("Date: 2026-12-12"),
            ]
        ],
        "pdf_text",
    )
    assert result.flight_number.value == "ZZ171"
    assert result.arrival_airport.value == "AYT"
    assert result.arrival_date.status == "uncertain"
    assert result.arrival_date.value is None
    assert result.arrival_local_time.status == "missing"


def test_split_labels_and_arrival_heading_provide_local_date_and_time():
    lines = [
        "Flight no.",
        "A1-28A",
        "Departure",
        "Time: 07:25",
        "Arrival",
        "Airport: FCO",
        "Date: 31/05/2027",
        "Time: 12:05 AM",
    ]
    result = parse_ticket([[TicketLine(line) for line in lines]], "pdf_text")
    assert result.flight_number.value == "A128A"
    assert result.arrival_airport.value == "FCO"
    assert result.arrival_date.value.isoformat() == "2027-05-31"
    assert result.arrival_local_time.value.isoformat() == "00:05:00"


@pytest.mark.parametrize(
    "time_label",
    [
        "14:30+03:00",
        "UTC 14:30",
        "14:30 (+1)",
        "14:30 CET",
        "UTC+03:00 14:30",
        "14:30 Europe/Istanbul",
    ],
)
def test_ambiguous_numeric_dates_and_qualified_times_are_withheld(time_label):
    result = parse_ticket(
        [
            [
                TicketLine("Arrival date: 03/04/2027"),
                TicketLine(f"Arrival time: {time_label}"),
            ]
        ],
        "pdf_text",
    )
    assert result.arrival_date.model_dump() == {"status": "uncertain", "value": None}
    assert result.arrival_local_time.model_dump() == {
        "status": "uncertain",
        "value": None,
    }


def test_generic_route_and_low_confidence_ocr_values_are_withheld():
    result = parse_ticket(
        [
            [
                TicketLine("IST -> AYT"),
                TicketLine("Flight: OX482", reliable=False),
            ]
        ],
        "ocr",
    )
    assert result.arrival_airport.model_dump() == {"status": "uncertain", "value": None}
    assert result.flight_number.model_dump() == {"status": "uncertain", "value": None}


def test_clock_time_keeps_printed_fractional_seconds():
    result = parse_ticket([[TicketLine("Arrival time: 14:31:12.345")]], "pdf_text")
    assert result.arrival_local_time.value.isoformat() == "14:31:12.345000"


def test_parallel_headings_do_not_assign_departure_values_to_arrival():
    lines = [
        TicketLine("Flight: ZZ 631"),
        TicketLine("DEPARTURE | ARRIVAL"),
        TicketLine("Airport: BER | --"),
        TicketLine("Date: 2027-06-15 | --"),
        TicketLine("Time: 07:05 | --"),
    ]
    result = parse_ticket([lines], "pdf_text")
    assert result.flight_number.value == "ZZ631"
    for field in (
        result.arrival_airport,
        result.arrival_date,
        result.arrival_local_time,
    ):
        assert field.model_dump() == {"status": "uncertain", "value": None}


def test_explicit_arrival_airport_can_include_a_terminal():
    result = parse_ticket(
        [[TicketLine("Departure airport: VIE | Arrival airport: MUC Terminal 2")]],
        "pdf_text",
    )
    assert result.arrival_airport.model_dump() == {
        "status": "extracted",
        "value": "MUC",
    }


def test_arrival_eta_is_a_clock_label_and_not_airport_evidence():
    lines = [TicketLine("Arrival ETA 18:20")]
    result = parse_ticket([lines], "ocr")
    assert result.arrival_airport.model_dump() == {"status": "missing", "value": None}
    assert result.arrival_local_time.value.isoformat() == "18:20:00"
