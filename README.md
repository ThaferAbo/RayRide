# RayRide

RayRide is the CSE491 airport transfer reservation prototype from Group 4. Upload a fictional flight ticket or enter the flight details yourself, review the arrival and destination, then save and retrieve a simulated reservation.

| Path | Contents |
| --- | --- |
| [`frontend/`](frontend/) | Next.js App Router, React, TypeScript, and Tailwind CSS |
| [`api/`](api/) | FastAPI, ticket extraction, and simulated reservations in SQLite |
| [`samples/`](samples/) | Fictional tickets, independent field labels, and fixture generation instructions |
| [`docs/implementation-log.md`](docs/implementation-log.md) | Decisions, verification results, and known limitations |
| [`docs/phase4-verification.md`](docs/phase4-verification.md) | Traceability, acceptance results, and screenshots |
| [`docs/meeting-5-demo.md`](docs/meeting-5-demo.md) | Demo setup and rehearsal checklist |
| `lib/`, `test/`, `assets/`, and Flutter platform directories | Legacy Flutter transfer demo |
| `Backend/` | Ignored local .NET course solution, available only on machines that already have it |

## Run the CSE491 prototype

Use Node.js 24 with npm 11, Python 3.11, and `uv`. The baseline used Node 24.14.0, npm 11.9.0, Python 3.11.15, and uv 0.11.24 on Windows. `uv` uses `api/.venv`, and npm uses `frontend/node_modules`.

From the repository root, run the API in one terminal.

```sh
cd api
uv sync --locked
uv run --locked uvicorn app.main:app --host 127.0.0.1 --port 8000
```

From the repository root, run the web app in another terminal.

```sh
cd frontend
npm ci
npm run dev
```

Open the [booking page](http://127.0.0.1:3000) and upload `samples/scanned-ticket.pdf`. Verify the four suggested fields, add a destination, and check the review box. After saving, reload the confirmation or use **Find a reservation** with the displayed reference. To try recovery, upload `samples/unreadable-ticket.png` and enter the details manually. [Meeting 5 checklist](docs/meeting-5-demo.md)

The [system status page](http://127.0.0.1:3000/status) shows API and SQLite readiness. The [health endpoint](http://127.0.0.1:8000/health) returns `{"status":"ok","database":"ready"}` after SQLite initialization. The [API documentation](http://127.0.0.1:8000/docs) lists the live endpoints.

Both services start without a local environment file. To override defaults, copy `api/.env.example` to `api/.env` or `frontend/.env.example` to `frontend/.env.local`. The API database path defaults to `api/data/rayride.sqlite3`. Relative database paths resolve from `api/`. The web server reads `RAYRIDE_API_URL` at request time and accepts loopback HTTP origins. Both documented servers bind to `127.0.0.1`.

### Set up Tesseract OCR

`uv sync --locked` installs the Python libraries from `api/uv.lock`. OCR also needs Tesseract 5 and English (`eng`) trained data. On Windows, the version used for local verification is available through WinGet. The installer may prompt for administrator approval.

```powershell
winget install --id UB-Mannheim.TesseractOCR --exact --version 5.4.0.20240606 --source winget
$env:RAYRIDE_TESSERACT_EXECUTABLE = Join-Path $env:ProgramFiles 'Tesseract-OCR\tesseract.exe'
& $env:RAYRIDE_TESSERACT_EXECUTABLE --version
& $env:RAYRIDE_TESSERACT_EXECUTABLE --list-langs
```

Confirm that `eng` appears. Start the API from that terminal, or put the executable's absolute path in `api/.env` using forward slashes. If Tesseract is on PATH, `RAYRIDE_TESSERACT_EXECUTABLE=tesseract` works. The validation run used a per-user copy of the checksum-verified UB Mannheim release and English data. [Tesseract Windows installation](https://tesseract-ocr.github.io/tessdoc/Installation.html#windows) · [UB Mannheim release](https://github.com/UB-Mannheim/tesseract/releases/tag/v5.4.0.20240606)

On Ubuntu 24.04, use the same packages as CI.

```sh
sudo apt-get update
sudo apt-get install --yes --no-install-recommends tesseract-ocr tesseract-ocr-eng
tesseract --version
tesseract --list-langs
```

`RAYRIDE_OCR_TIMEOUT_SECONDS` defaults to 8 seconds across all OCR pages in a ticket. Embedded-text extraction works without Tesseract when the document contains sufficient evidence. If OCR is unavailable, the API preserves usable embedded suggestions and returns warnings for manual entry.

### Try the extraction API

With the API running, run this from the repository root. On POSIX shells use `curl` in place of `curl.exe`.

```powershell
curl.exe --fail-with-body --form 'ticket=@samples/scanned-ticket.pdf;type=application/pdf' 'http://127.0.0.1:8000/api/v1/tickets/extract'
```

Send one `ticket` part ending in `.pdf`, `.png`, `.jpg`, or `.jpeg`. The API checks the file extension, declared media type, signature, and ability to decode the supported format. It accepts files up to 10 MiB, PDFs up to five pages with at most 20,000 embedded characters per page, and images up to 12 million pixels. Uploads and OCR images are processed in memory. The API stores no ticket files, OCR transcripts, or reservation data from this endpoint.

An HTTP 200 response includes the method (`pdf_text`, `ocr`, `mixed`, or `unavailable`), field statuses, and warnings. A low-confidence or conflicting value may be withheld as `null`. Arrival time stays local to the arrival airport. Incomplete or failed OCR leaves the review form available for manual entry. Invalid requests use `400` for malformed multipart, `413` for limits, `415` for unsupported or mismatched formats, and `422` for unreadable, invalid, or empty files.

### Simulated reservations and privacy

The browser sends requests to the Next.js server on the same origin. The server forwards only the ticket, booking, and lookup requests to a configured loopback API. Requests and responses have byte and time limits. Use fictional or anonymized tickets. The app discards ticket files and saves only the reviewed flight, local arrival date and time, destination, reference, simulated status, and creation timestamp to SQLite.

The API issues a reference after committing the reservation. The confirmation page loads the saved record by that reference. Edits clear the review checkbox. If a reply is lost, retry with the same trip details in the same form to recover the original reservation. API clients can use a version 4 UUID in `Idempotency-Key`. The initial write returns `201`, an identical retry returns `200`, and reuse of the same key for different details returns `409`. A confirmation reference can be used by anyone who has access to the local prototype, so keep it private if necessary.

## Verification and development

Run the API checks from `api/` after `uv sync --locked`.

```sh
uv run --locked ruff check .
uv run --locked ruff format --check .
uv run --locked python -m app.export_openapi --check
uv run --locked pytest -q
uv run --locked python -m scripts.evaluate_tickets --corpus original
uv run --locked python -m scripts.evaluate_tickets --corpus phase4
```

Set `RAYRIDE_REQUIRE_OCR_TESTS=1` to fail the real OCR tests if Tesseract or English data are unavailable, as CI does. In PowerShell use `$env:RAYRIDE_REQUIRE_OCR_TESTS = '1'`. Evaluation scores the two independently labeled synthetic corpora before any manual correction. [Fixture details](samples/README.md) · [Phase 4 results](docs/phase4-verification.md)

Run the web checks from `frontend/` after `npm ci`.

```sh
npm run contracts:check
npm run lint
npm run typecheck
npm test
npm run build
npx playwright install chromium
npm run test:e2e
```

The browser suite starts the production frontend on port 3131 and the real API on 8131 with a separate ignored SQLite file. It requires working Tesseract with English data for the scanned fixtures. Set `RAYRIDE_CAPTURE_EVIDENCE=1` before `npm run test:e2e` to capture the four report screenshots. The standard `npm start` serves the production build on port 3000. [Capture instructions and evidence](docs/phase4-verification.md#reproduce-and-capture) · [CI workflow](.github/workflows/ci.yml)

Edit the Pydantic models in `api/app/schemas.py` when a contract changes. From `api/`, run `uv run --locked python -m app.export_openapi`. Then, from `frontend/`, run `npm run contracts:generate`. Keep both generated files, `api/openapi.json` and `frontend/lib/api.types.ts`, with the change.

| Route | Status and contract |
| --- | --- |
| `GET /health` | Live. Returns `HealthResponse` or HTTP 503 with `ErrorResponse` if the database check fails. |
| `POST /api/v1/tickets/extract` | Live. Multipart `ticket` file (PDF, PNG, or JPEG) to `ExtractionResult` or a typed upload error. |
| `POST /api/v1/reservations` | Live. Validates an explicitly reviewed `ReservationRequest` and returns the committed `ReservationResponse`. |
| `GET /api/v1/reservations/{reference}` | Live. Retrieves a stored simulated reservation by its confirmation reference. |

Keep the CSE491 work in `frontend/` and `api/`. Leave the legacy applications in their current directories. Use the dependency lockfiles and record commands and observed results in the implementation log. Keep the local plan, personal `AGENTS.md`, credentials, and database files out of Git.

## Attribution and sample data

Use fictional or anonymized ticket fixtures. Record the source, author, license, and required notices for external code, libraries, datasets, images, and other assets. Keep applicable notices with redistributed material. The lockfiles record dependencies and versions. In the project report, disclose AI assistance and record actual team contributions.

The CSE491 app and sample corpus use no legacy assets. Verify reuse rights before importing any legacy image or other asset. The extraction pipeline uses pypdfium2/PDFium, Tesseract and its English data, Pillow, and OpenCV. Keep the applicable upstream notices if redistributing any of those components or binaries. [pypdfium2 licensing](https://pypdfium2.readthedocs.io/en/stable/readme.html#licensing) · [Tesseract license](https://github.com/tesseract-ocr/tesseract/blob/main/LICENSE) · [OpenCV license](https://github.com/opencv/opencv/blob/4.x/LICENSE)

The booking page uses an original AI-generated coastline image, the Manrope typeface under the SIL Open Font License, and Phosphor Icons under MIT. The font and icons are served with local project dependencies. [Asset provenance](docs/implementation-log.md#phase-3-review-and-simulated-reservations) · [Manrope](https://github.com/sharanda/manrope) · [Phosphor Icons](https://github.com/phosphor-icons/react)

## Legacy Flutter demo

The Flutter app demonstrates passenger transfers in Antalya, driver trip handling, and admin screens. Its clients expect legacy endpoints that the checked-in `swagger.json` does not fully describe. A fresh clone has no copy of the ignored .NET solution.

To explore the legacy app, use Flutter with Dart 3.11 or later in the 3.x series. From the repository root, run `flutter pub get` and `flutter run`. The pre-existing [`Counter increments smoke test`](test/widget_test.dart#L13) fails because the test expects the Flutter starter counter. The CSE491 checks cover the new frontend and API. See the [legacy baseline in the implementation log](docs/implementation-log.md#legacy-flutter-baseline).
