import json
import os
import sqlite3
import subprocess
import tempfile
from contextlib import closing
from io import BytesIO
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from PIL import Image
from reportlab.pdfgen.canvas import Canvas

from app.extraction import LocalTicketExtractor
from app.main import create_app
from app.settings import Settings
from app.ticket_upload import MAX_REQUEST_BYTES, MAX_TICKET_BYTES

SAMPLES = Path(__file__).resolve().parents[2] / "samples"
EXPECTED = json.loads((SAMPLES / "expected.json").read_text(encoding="utf-8"))
MEDIA_TYPES = {".pdf": "application/pdf", ".png": "image/png", ".jpeg": "image/jpeg"}
ENDPOINT = "/api/v1/tickets/extract"


@pytest.fixture
def client(tmp_path):
    def make(**settings):
        return TestClient(
            create_app(
                Settings(database_path=tmp_path / "ticket-tests.sqlite3", **settings)
            )
        )

    return make


@pytest.fixture(scope="session")
def ocr_executable():
    executable = Settings().tesseract_executable
    try:
        result = subprocess.run(
            [executable, "--list-langs"], capture_output=True, check=True, timeout=10
        )
        available = b"eng" in {line.strip() for line in result.stdout.splitlines()}
    except (OSError, subprocess.SubprocessError):
        available = False
    if not available:
        message = "Tesseract with English trained data is required for real OCR tests."
        if os.environ.get("RAYRIDE_REQUIRE_OCR_TESTS") == "1":
            pytest.fail(message)
        pytest.skip(message)
    return executable


def _post_sample(client, name):
    path = SAMPLES / name
    with path.open("rb") as ticket:
        return client.post(
            ENDPOINT, files={"ticket": (name, ticket, MEDIA_TYPES[path.suffix])}
        )


def _assert_fixture(response, name):
    assert response.status_code == 200, response.text
    actual = response.json()
    expected = EXPECTED[name]
    assert actual["method"] == expected["method"]
    for field, value in expected["values"].items():
        field_result = actual[field]
        if field in expected["missing"]:
            assert field_result == {"status": "missing", "value": None}, field
        elif field in expected["uncertain"]:
            assert field_result == {"status": "uncertain", "value": value}, field
        elif (
            name == "image-ticket.png"
            and field == "flight_number"
            and field_result["status"] == "uncertain"
        ):
            # Q/O can look alike to OCR. A low-confidence code must be withheld.
            assert field_result["value"] is None
        else:
            assert field_result == {"status": "extracted", "value": value}, field
    if any(actual[field]["status"] != "extracted" for field in expected["values"]):
        assert actual["warnings"]


@pytest.mark.parametrize("name", ["text-ticket.pdf", "ambiguous-ticket.pdf"])
def test_embedded_pdf_and_ambiguous_legs_work_without_ocr(client, name):
    with client(tesseract_executable="rayride-nonexistent-ocr") as app:
        _assert_fixture(_post_sample(app, name), name)


@pytest.mark.ocr
@pytest.mark.parametrize(
    "name",
    [
        "scanned-ticket.pdf",
        "image-ticket.png",
        "image-ticket.jpeg",
        "missing-fields.pdf",
        "mixed-ticket.pdf",
        "unreadable-ticket.png",
    ],
)
def test_real_ocr_ticket_fixtures(client, ocr_executable, name):
    with client(tesseract_executable=ocr_executable) as app:
        _assert_fixture(_post_sample(app, name), name)


@pytest.mark.ocr
def test_tesseract_subprocess_honors_a_real_timeout(ocr_executable):
    extractor = LocalTicketExtractor(executable=ocr_executable, timeout_seconds=8)
    with pytest.raises(subprocess.TimeoutExpired):
        extractor._tesseract((SAMPLES / "image-ticket.png").read_bytes(), timeout=0.001)


@pytest.mark.parametrize(
    ("name", "media_type", "content", "code"),
    [
        ("ticket.zip", "application/zip", b"abc", 415),
        ("ticket.png", "application/pdf", b"%PDF-1.7", 415),
        ("ticket.jpeg", "image/jpeg", b"plain text", 415),
        ("ticket.png", "image/png", b"\x89PNG\r\n\x1a\n", 422),
        ("ticket.jpeg", "image/jpeg", b"\xff\xd8\xff", 422),
        ("ticket.pdf", "application/pdf", b"%PDF-1.7\ncut off", 422),
        ("ticket.pdf", "application/pdf", b"%PDF-1.7\ninvalid PDF\n%%EOF", 422),
        ("ticket.pdf", "application/pdf", b"", 422),
    ],
)
def test_rejects_unsupported_spoofed_and_corrupt_files(
    client, name, media_type, content, code
):
    with client() as app:
        response = app.post(ENDPOINT, files={"ticket": (name, content, media_type)})
    assert response.status_code == code, response.text
    assert set(response.json()["detail"]) == {"code", "message"}


def test_rejects_missing_duplicate_and_incomplete_multipart(client):
    file = ("ticket.pdf", b"%PDF-1.7", "application/pdf")
    with client() as app:
        assert app.post(ENDPOINT, files={"other": file}).status_code == 400
        assert (
            app.post(ENDPOINT, files=[("ticket", file), ("ticket", file)]).status_code
            == 400
        )
        response = app.post(
            ENDPOINT,
            content=b'--cuts\r\nContent-Disposition: form-data; name="ticket"; filename="ticket.pdf"\r\n\r\n%PDF-1.7',
            headers={"Content-Type": "multipart/form-data; boundary=cuts"},
        )
        assert response.status_code == 400


def test_streamed_upload_is_bounded_without_content_length(client):
    def multipart():
        yield b'--bound\r\nContent-Disposition: form-data; name="ticket"; filename="big.pdf"\r\n\r\n'
        for _ in range(MAX_TICKET_BYTES // 65536):
            yield b" " * 65536
        yield b"x\r\n--bound--\r\n"

    with client() as app:
        response = app.post(
            ENDPOINT,
            content=multipart(),
            headers={"Content-Type": "multipart/form-data; boundary=bound"},
        )
    assert "content-length" not in response.request.headers
    assert response.status_code == 413
    assert response.json()["detail"]["code"] == "upload_too_large"


def test_request_page_and_pixel_limits(client):
    pages = BytesIO()
    canvas = Canvas(pages)
    for index in range(6):
        canvas.drawString(30, 740, f"Fictional page {index + 1}")
        canvas.showPage()
    canvas.save()
    oversized_image = BytesIO()
    Image.new("1", (4001, 3000), 1).save(oversized_image, format="PNG")
    with client() as app:
        above_limit = app.post(
            ENDPOINT,
            content=b"",
            headers={
                "Content-Type": "multipart/form-data; boundary=bound",
                "Content-Length": str(MAX_REQUEST_BYTES + 1),
            },
        )
        assert above_limit.status_code == 413
        for ticket in [
            ("pages.pdf", pages.getvalue(), "application/pdf"),
            ("large.png", oversized_image.getvalue(), "image/png"),
        ]:
            assert app.post(ENDPOINT, files={"ticket": ticket}).status_code == 413


def test_missing_ocr_and_timeout_are_recoverable(client, monkeypatch):
    with client(tesseract_executable="rayride-nonexistent-ocr") as app:
        unavailable = _post_sample(app, "scanned-ticket.pdf")
        assert unavailable.status_code == 200
        assert unavailable.json()["method"] == "unavailable"
        assert "Tesseract OCR is unavailable" in unavailable.json()["warnings"][0]

    def timeout(self, payload, remaining):
        raise subprocess.TimeoutExpired(self.executable, remaining)

    monkeypatch.setattr(LocalTicketExtractor, "_tesseract", timeout)
    with client() as app:
        partial = _post_sample(app, "missing-fields.pdf")
        assert partial.status_code == 200
        result = partial.json()
        assert result["method"] == "pdf_text"
        assert result["flight_number"]["value"] == "ZZ154"
        assert result["arrival_date"] == {"status": "missing", "value": None}
        assert "OCR timed out" in result["warnings"][0]
        assert _post_sample(app, "text-ticket.pdf").status_code == 200


def test_tesseract_failure_returns_safe_manual_entry_feedback(
    client, monkeypatch, caplog
):
    def fail(self, payload, remaining):
        raise subprocess.CalledProcessError(
            1, self.executable, stderr=b"private OCR output"
        )

    monkeypatch.setattr(LocalTicketExtractor, "_tesseract", fail)
    with client() as app:
        response = _post_sample(app, "image-ticket.jpeg")
    assert response.status_code == 200
    result = response.json()
    assert result["method"] == "unavailable"
    assert all(
        result[field]["status"] == "missing"
        for field in EXPECTED["image-ticket.jpeg"]["values"]
    )
    assert "English language data" in result["warnings"][0]
    assert "private OCR output" not in response.text + caplog.text


def test_pdf_text_limit_rejects_instead_of_scoring_a_partial_page(client, monkeypatch):
    monkeypatch.setattr("app.extraction.MAX_TEXT_PER_PAGE", 10)
    with client() as app:
        response = _post_sample(app, "text-ticket.pdf")
    assert response.status_code == 413
    assert response.json()["detail"]["code"] == "upload_too_large"


def test_invalid_embedded_field_triggers_fallback_even_with_four_labels(client):
    pdf = BytesIO()
    canvas = Canvas(pdf)
    lines = (
        "Flight: unreadable",
        "Arrival airport: AYT",
        "Arrival date: 2026-12-12",
        "Arrival time: 09:20",
    )
    for index, line in enumerate(lines):
        canvas.drawString(42, 700 - index * 24, line)
    canvas.save()
    with client(tesseract_executable="rayride-nonexistent-ocr") as app:
        response = app.post(
            ENDPOINT,
            files={"ticket": ("partial.pdf", pdf.getvalue(), "application/pdf")},
        )
    assert response.status_code == 200
    result = response.json()
    assert result["flight_number"] == {"status": "uncertain", "value": None}
    assert "Tesseract OCR is unavailable" in result["warnings"][0]


def test_request_does_not_spool_store_or_log_uploads(
    client, tmp_path, monkeypatch, caplog
):
    def unexpected_temp_file(*args, **kwargs):
        pytest.fail("The upload handler attempted to write a temporary file.")

    monkeypatch.setattr(tempfile, "TemporaryFile", unexpected_temp_file)
    monkeypatch.setattr(tempfile, "SpooledTemporaryFile", unexpected_temp_file)
    with client() as app:
        names_before = set(tmp_path.iterdir())
        ticket = (SAMPLES / "text-ticket.pdf").read_bytes()
        response = app.post(
            ENDPOINT,
            files={
                "ticket": ("private-filename.pdf", ticket, "application/octet-stream")
            },
        )
        assert response.status_code == 200
        assert "private-filename" not in response.text + caplog.text
        assert "Fictional flight ticket" not in response.text + caplog.text
        assert set(tmp_path.iterdir()) == names_before
        with closing(sqlite3.connect(tmp_path / "ticket-tests.sqlite3")) as database:
            assert database.execute("SELECT count(*) FROM reservations").fetchone() == (
                0,
            )
