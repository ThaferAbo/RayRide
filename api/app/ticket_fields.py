import re
import unicodedata
from collections.abc import Iterable
from dataclasses import dataclass, field
from datetime import date, time
from typing import Generic, TypeVar

from .schemas import (
    FLIGHT_NUMBER_PATTERN,
    AirportCode,
    ArrivalDate,
    ArrivalLocalTime,
    Extracted,
    ExtractionMethod,
    ExtractionResult,
    FlightNumber,
    Missing,
    Uncertain,
)

_LABEL = re.compile(
    r"^(ARRIVAL(?:\s+(?:AIRPORT|DATE\s*/\s*TIME|DATE|TIME))?|ARRIV(?:E|ES|ING)|"
    r"DESTINATION|TO|DEPARTURE(?:\s+(?:AIRPORT|DATE\s*/\s*TIME|DATE|TIME))?|"
    r"DEPART(?:S|ING)?|ORIGIN|FROM|"
    r"FLIGHT(?!\s+(?:DATE|TIME|STATUS|DURATION)\b)(?:\s+(?:NUMBER|NO\.?))?|"
    r"AIRPORT|DATE|TIME)(?!\w)[ \t]*[:#]?[ \t]*(.*)$"
)
_INLINE_DIRECTION = re.compile(
    r"\s+(?=(?:ARRIVAL|DEPARTURE)\s+[A-Z]|(?:ARRIVAL|DEPARTURE):)"
)
_FLIGHT = re.compile(r"\b(?:[A-Z][A-Z0-9]|[0-9][A-Z])[ -]?[0-9]{1,4}[A-Z]?\b")
_ROUTE = re.compile(r"\b[A-Z]{3}\s*(?:->|→|/)\s*[A-Z]{3}\b")
_MONTHS = {
    name: month
    for month, name in enumerate(
        "JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC".split(), 1
    )
}
_MONTH = (
    r"JAN(?:UARY)?|FEB(?:RUARY)?|MAR(?:CH)?|APR(?:IL)?|MAY|JUN(?:E)?|"
    r"JUL(?:Y)?|AUG(?:UST)?|SEP(?:T(?:EMBER)?)?|OCT(?:OBER)?|NOV(?:EMBER)?|DEC(?:EMBER)?"
)
_YEAR_FIRST = re.compile(
    r"(?<![0-9])([0-9]{4})[-/.]([0-9]{1,2})[-/.]([0-9]{1,2})(?![0-9])"
)
_YEAR_LAST = re.compile(
    r"(?<![0-9./-])([0-9]{1,2})[-/.]([0-9]{1,2})[-/.]([0-9]{4})(?![0-9])"
)
_DAY_MONTH = re.compile(rf"\b([0-9]{{1,2}})\s+({_MONTH})\s+([0-9]{{4}})\b")
_MONTH_DAY = re.compile(rf"\b({_MONTH})\s+([0-9]{{1,2}}),?\s+([0-9]{{4}})\b")
_TIME = re.compile(
    r"(?<![0-9:.])([0-9]{1,2}):([0-9]{2})(?::([0-9]{2})(?:\.([0-9]{1,6}))?)?(?:\s*(AM|PM))?(?![0-9:.])"
)
_TIME_ZONE = (
    r"Z|UTC|GMT|BST|CET|CEST|EET|EEST|EST|EDT|CST|CDT|MST|MDT|PST|PDT|"
    r"IST|TRT|JST|KST|AEST|AEDT|NZST|NZDT|[A-Z_]+/[A-Z_]+"
)
_TIME_QUALIFIER = re.compile(rf"^\s*(?:\(?(?:{_TIME_ZONE})\b|\(?[+-]\s*[0-9])")
_TIME_PREFIX = re.compile(r"\b(?:UTC|GMT)(?:\s*[+-]\s*[0-9:]{0,5})?\s*$")


@dataclass(frozen=True)
class TicketLine:
    text: str
    reliable: bool = True


T = TypeVar("T", str, date, time)


@dataclass
class _Evidence(Generic[T]):
    candidates: dict[T, bool] = field(default_factory=dict)
    ambiguous: bool = False
    unqualified: bool = False

    def record(self, values: Iterable[T], reliable: bool) -> None:
        for value in values:
            self.candidates[value] = self.candidates.get(value, False) or reliable

    def suggestion(self, model_type, *, multiple_legs: bool = False):
        # A conflicting or unqualified value is withheld instead of choosing a candidate.
        if len(self.candidates) > 1 or self.ambiguous:
            return Uncertain[model_type](status="uncertain", value=None)
        if not self.candidates:
            if self.unqualified:
                return Uncertain[model_type](status="uncertain", value=None)
            return Missing(status="missing", value=None)
        value, reliable = next(iter(self.candidates.items()))
        if not reliable:
            return Uncertain[model_type](status="uncertain", value=None)
        if multiple_legs:
            return Uncertain[model_type](status="uncertain", value=value)
        return Extracted[model_type](status="extracted", value=value)


def _flights(text: str) -> set[str]:
    normalized = {
        match.replace(" ", "").replace("-", "") for match in _FLIGHT.findall(text)
    }
    return {item for item in normalized if re.fullmatch(FLIGHT_NUMBER_PATTERN, item)}


def _airports(text: str) -> set[str]:
    codes = set(re.findall(r"\(([A-Z]{3})\)", text))
    for piece in re.split(r"\s+[/-]\s+(?=[A-Z]{3}\b)", text):
        leading = re.match(
            r"^\s*([A-Z]{3})(?=$|\s*(?:[-–,]|[0-9])|\s+[A-Z]{3}\s+[0-9])", piece
        )
        if leading:
            codes.add(leading.group(1))
    return codes - {"UTC", "GMT"}


def _valid_dates(parts: Iterable[tuple[int, int, int]]) -> set[date]:
    dates = set()
    for year, month, day in parts:
        try:
            dates.add(date(year, month, day))
        except ValueError:
            continue
    return dates


def _dates(text: str) -> set[date]:
    parts = [
        (int(year), int(month), int(day))
        for year, month, day in _YEAR_FIRST.findall(text)
    ]
    for first, second, year in _YEAR_LAST.findall(text):
        parts.extend(
            [(int(year), int(first), int(second)), (int(year), int(second), int(first))]
        )
    parts.extend(
        (int(year), _MONTHS[month[:3]], int(day))
        for day, month, year in _DAY_MONTH.findall(text)
    )
    parts.extend(
        (int(year), _MONTHS[month[:3]], int(day))
        for month, day, year in _MONTH_DAY.findall(text)
    )
    return _valid_dates(parts)


def _times(text: str) -> tuple[set[time], bool]:
    values = set()
    qualified = False
    for match in _TIME.finditer(text):
        hour, minute, second, fraction, meridiem = match.groups()
        if _TIME_QUALIFIER.match(text[match.end() :]) or _TIME_PREFIX.search(
            text[: match.start()]
        ):
            qualified = True
            continue
        clock_hour = int(hour)
        if meridiem:
            if not 1 <= clock_hour <= 12:
                continue
            clock_hour = clock_hour % 12 + (12 if meridiem == "PM" else 0)
        try:
            microsecond = int(fraction.ljust(6, "0")) if fraction else 0
            values.add(time(clock_hour, int(minute), int(second or 0), microsecond))
        except ValueError:
            continue
    return values, qualified


@dataclass
class _TicketFields:
    flight: _Evidence[str] = field(default_factory=_Evidence)
    arrival_airport: _Evidence[str] = field(default_factory=_Evidence)
    arrival_date: _Evidence[date] = field(default_factory=_Evidence)
    arrival_time: _Evidence[time] = field(default_factory=_Evidence)

    def read(self, label: str, value: str, reliable: bool) -> None:
        if label.startswith("FLIGHT"):
            flights = _flights(value)
            self.flight.record(flights, reliable)
            self.flight.ambiguous |= bool(value and not flights)
            return

        field = (
            label.removeprefix("ARRIVAL").strip() if label.startswith("ARRIVAL") else ""
        )
        if label in ("TO", "DESTINATION"):
            field = "AIRPORT"
        if field in ("", "AIRPORT"):
            airports = _airports(value)
            self.arrival_airport.record(airports, reliable)
            self.arrival_airport.ambiguous |= field == "AIRPORT" and bool(
                value and not airports
            )
        if field == "" or "DATE" in field:
            dates = _dates(value)
            self.arrival_date.record(dates, reliable)
            self.arrival_date.ambiguous |= field == "DATE" and bool(value and not dates)
        if field == "" or "TIME" in field:
            times, qualified = _times(value)
            self.arrival_time.record(times, reliable)
            self.arrival_time.ambiguous |= qualified or (
                field == "TIME" and bool(value and not times)
            )
            if qualified and field != "TIME":
                self.arrival_date.ambiguous = True

    def parse_page(self, lines: Iterable[TicketLine]) -> None:
        direction = ""
        pending: tuple[str, bool] | None = None
        for line in lines:
            text = unicodedata.normalize("NFKC", line.text).upper()
            for part in re.split(r"[|\t;]", text):
                for segment in _INLINE_DIRECTION.split(part.strip()):
                    match = _LABEL.match(segment)
                    if not match:
                        if pending and segment:
                            label, label_reliable = pending
                            self.read(label, segment, label_reliable and line.reliable)
                        elif not direction and _ROUTE.search(segment):
                            self.arrival_airport.unqualified = True
                        else:
                            direction = ""
                        pending = None
                        continue

                    label, value = match.groups()
                    value = value.lstrip(" -–").strip()
                    pending = None
                    if label.startswith("DEPART") or label in ("FROM", "ORIGIN"):
                        direction = "departure"
                        continue
                    if label in ("AIRPORT", "DATE", "TIME"):
                        if direction == "departure":
                            continue
                        if direction != "arrival":
                            getattr(
                                self, f"arrival_{label.lower()}"
                            ).unqualified |= bool(value)
                            continue
                        label = f"ARRIVAL {label}"
                    if label == "ARRIVAL" and not value:
                        direction = "arrival"
                    elif label.startswith("FLIGHT") or direction == "departure":
                        direction = ""
                    if value:
                        self.read(label, value, line.reliable)
                    else:
                        pending = (label, line.reliable)


def _collect_fields(pages: Iterable[Iterable[TicketLine]]) -> _TicketFields:
    fields = _TicketFields()
    for lines in pages:
        fields.parse_page(lines)
    return fields


def parse_embedded_ticket(pages: list[list[TicketLine]]) -> ExtractionResult | None:
    if not all(pages):
        return None
    fields = _collect_fields(pages)
    evidence = (
        fields.flight,
        fields.arrival_airport,
        fields.arrival_date,
        fields.arrival_time,
    )
    # Multiple well-formed candidates are meaningful. Invalid or absent evidence needs OCR.
    if all(item.candidates and not item.ambiguous for item in evidence):
        return _suggestions(fields, "pdf_text", ())
    return None


def parse_ticket(
    pages: Iterable[Iterable[TicketLine]],
    method: ExtractionMethod,
    warnings: Iterable[str] = (),
) -> ExtractionResult:
    return _suggestions(_collect_fields(pages), method, warnings)


def _suggestions(
    fields: _TicketFields, method: ExtractionMethod, warnings: Iterable[str]
) -> ExtractionResult:
    multiple_legs = len(fields.flight.candidates) > 1
    result = ExtractionResult(
        method=method,
        flight_number=fields.flight.suggestion(FlightNumber),
        arrival_airport=fields.arrival_airport.suggestion(
            AirportCode, multiple_legs=multiple_legs
        ),
        arrival_date=fields.arrival_date.suggestion(
            ArrivalDate, multiple_legs=multiple_legs
        ),
        arrival_local_time=fields.arrival_time.suggestion(
            ArrivalLocalTime, multiple_legs=multiple_legs
        ),
        warnings=list(warnings),
    )
    for label, suggestion in (
        ("flight number", result.flight_number),
        ("arrival airport", result.arrival_airport),
        ("arrival date", result.arrival_date),
        ("arrival time", result.arrival_local_time),
    ):
        if suggestion.status == "uncertain":
            result.warnings.append(f"Review the uncertain {label}.")
        elif suggestion.status == "missing":
            result.warnings.append(f"Enter the missing {label} manually.")
    return result
