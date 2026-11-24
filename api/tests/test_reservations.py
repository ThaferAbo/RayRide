import re
import sqlite3
from concurrent.futures import ThreadPoolExecutor
from contextlib import closing
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from app.main import create_app
from app.schemas import REFERENCE_PATTERN
from app.settings import Settings

PATH = "/api/v1/reservations"
REVIEWED = {
    "flight_number": "ZZ731",
    "arrival_airport": "AYT",
    "arrival_date": "2026-12-03",
    "arrival_local_time": "14:10:00.123456",
    "destination": "Fictional Hotel",
    "reviewed": True,
}


@pytest.fixture
def settings(tmp_path):
    return Settings(database_path=tmp_path / "reservations.sqlite3")


def _count(settings):
    with closing(sqlite3.connect(settings.database_path)) as database:
        return database.execute("SELECT COUNT(*) FROM reservations").fetchone()[0]


def test_creation_returns_committed_values_and_survives_an_application_restart(
    settings,
):
    with TestClient(create_app(settings)) as client:
        response = client.post(
            PATH, json={**REVIEWED, "destination": " Fictional Hotel "}
        )
        second = client.post(PATH, json=REVIEWED)
        assert response.status_code == second.status_code == 201
        saved = response.json()
        assert re.fullmatch(REFERENCE_PATTERN, saved["reference"])
        assert saved["reference"] != second.json()["reference"]
        assert saved["status"] == "simulated"
        assert saved["created_at"].endswith("Z")
        assert {key: saved[key] for key in REVIEWED if key != "reviewed"} == {
            key: value for key, value in REVIEWED.items() if key != "reviewed"
        }
        assert response.headers["location"] == f"{PATH}/{saved['reference']}"
        assert _count(settings) == 2

    with TestClient(create_app(settings)) as restarted:
        read = restarted.get(response.headers["location"])
        assert read.status_code == 200
        assert read.json() == saved
        assert read.headers["cache-control"] == "no-store"


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("reviewed", False),
        ("reviewed", 1),
        ("flight_number", "INVALID"),
        ("arrival_airport", "AYT1"),
        ("arrival_date", "2026-02-30"),
        ("arrival_local_time", "14:10:00+03:00"),
        ("destination", "   "),
        ("destination", "x" * 201),
    ],
)
def test_invalid_fields_are_rejected_without_a_write(settings, field, value):
    with TestClient(create_app(settings)) as client:
        response = client.post(PATH, json={**REVIEWED, field: value})
        assert response.status_code == 422
        assert field in response.json()["detail"]["fields"]
        assert _count(settings) == 0


def test_malformed_missing_or_extraneous_data_and_large_requests_are_rejected(settings):
    with TestClient(create_app(settings)) as client:
        assert client.post(PATH, json={}).status_code == 422
        invalid = client.post(
            PATH, json={**REVIEWED, "raw_ticket": "private-ticket-bytes"}
        )
        assert invalid.status_code == 422
        assert "private-ticket-bytes" not in invalid.text
        headers = {"content-type": "application/json"}
        assert client.post(PATH, content="{invalid", headers=headers).status_code == 422
        assert client.post(PATH, content="x" * 8193, headers=headers).status_code == 413
        assert client.post(PATH, content="abc").status_code == 415
        assert client.get(f"{PATH}/RR-ABCDEFGHIJKL").status_code == 404
        assert client.get(f"{PATH}/bad-ref").status_code == 422
        assert _count(settings) == 0


def test_concurrent_identical_retries_only_commit_one_reservation(settings):
    key = {"Idempotency-Key": str(uuid4())}
    with TestClient(create_app(settings)) as client:

        def send():
            return client.post(PATH, json=REVIEWED, headers=key)

        with ThreadPoolExecutor(max_workers=2) as workers:
            first, second = [
                future.result()
                for future in (workers.submit(send), workers.submit(send))
            ]
        assert sorted([first.status_code, second.status_code]) == [200, 201]
        assert first.json() == second.json()
        assert _count(settings) == 1

    with TestClient(create_app(settings)) as restarted:
        replay = restarted.post(PATH, json=REVIEWED, headers=key)
        assert replay.status_code == 200
        assert replay.json() == first.json()
        conflict = restarted.post(
            PATH, json={**REVIEWED, "destination": "Another hotel"}, headers=key
        )
        assert conflict.status_code == 409
        assert _count(settings) == 1


def test_commit_failure_returns_no_confirmation_and_leaves_no_row(
    settings, monkeypatch
):
    def fail_commit(self):
        raise OperationalError("COMMIT", {}, RuntimeError("private SQLite error"))

    key = {"Idempotency-Key": str(uuid4())}
    with TestClient(create_app(settings)) as client:
        with monkeypatch.context() as patch:
            patch.setattr(Session, "commit", fail_commit)
            failure = client.post(PATH, json=REVIEWED, headers=key)
            assert failure.status_code == 503
            assert "private SQLite error" not in failure.text
            assert "reference" not in failure.json()
            assert _count(settings) == 0

        assert client.post(PATH, json=REVIEWED, headers=key).status_code == 201
        assert _count(settings) == 1
