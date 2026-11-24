from datetime import date, time

import pytest
from sqlalchemy import inspect, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db import Reservation, initialize_database


def test_reservation_storage_schema_and_restart(tmp_path):
    path = tmp_path / "data" / "test.sqlite3"
    reference = "RR-123456789ABC"
    values = {
        "reference": reference,
        "flight_number": "ZZ123",
        "arrival_airport": "AYT",
        "arrival_date": date(2026, 12, 3),
        "arrival_local_time": time(14, 30),
        "destination": "Fictional Hotel",
    }

    engine = initialize_database(path)
    try:
        assert inspect(engine).get_table_names() == ["reservations"]
        with Session(engine) as session:
            session.add(Reservation(**values))
            session.commit()
    finally:
        engine.dispose()

    restarted_engine = initialize_database(path)
    try:
        with Session(restarted_engine) as session:
            saved = session.scalar(select(Reservation))
            assert saved is not None
            assert saved.reference == reference
            assert saved.arrival_local_time == time(14, 30)
            assert saved.status == "simulated"
            assert saved.created_at_utc is not None

        with Session(restarted_engine) as session:
            session.add(Reservation(**values))
            with pytest.raises(IntegrityError):
                session.commit()
    finally:
        restarted_engine.dispose()
