import sqlite3
from contextlib import closing

from fastapi.testclient import TestClient

from app.main import create_app
from app.settings import Settings


def test_health_initializes_sqlite_and_publishes_contract(tmp_path):
    database = tmp_path / "data" / "test.sqlite3"
    application = create_app(Settings(database_path=database))
    assert not database.exists()

    with TestClient(application) as client:
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok", "database": "ready"}
        assert database.is_file()

        contract = client.get("/openapi.json").json()
        assert list(contract["paths"]) == ["/health"]
        assert "503" in contract["paths"]["/health"]["get"]["responses"]
        assert {"ExtractionResult", "ReservationRequest", "ReservationResponse"} <= set(
            contract["components"]["schemas"]
        )
        assert client.post("/api/v1/tickets/extract").status_code == 404
        assert client.post("/api/v1/reservations").status_code == 404
        assert client.get("/api/v1/reservations/RR-123456789ABC").status_code == 404


def test_health_reports_database_failure(tmp_path):
    database = tmp_path / "test.sqlite3"
    with TestClient(create_app(Settings(database_path=database))) as client:
        with closing(sqlite3.connect(database)) as connection:
            connection.execute("DROP TABLE reservations")
            connection.commit()

        response = client.get("/health")
        assert response.status_code == 503
        assert response.json() == {
            "detail": {
                "code": "database_unavailable",
                "message": "SQLite is unavailable.",
            }
        }
