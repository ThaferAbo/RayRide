# RayRide

RayRide is the CSE491 Senior Design Project I prototype from Group 4 (Efkan, Thafer and Alperen), Fall 2026–2027. Upload a fictional flight ticket or enter details manually, review the arrival and destination, then save and retrieve a simulated airport transfer.

![RayRide booking page in the verified desktop prototype](docs/evidence/phase4/report-01-upload.png)

The published Phase 6 revision `9749be2` is ready for a local simulated demo in Chromium. Pilot usability (NFR-2), setup on a second physical machine (NFR-5), individual contribution confirmation, and two failures in the pinned Firefox runner remain open. [Release revision](https://github.com/ThaferAbo/RayRide/commit/9749be2685a56df789f393071d7ec1ead93f6091) · [Final report and evidence](docs/final-report.md) · [Presentation and live demo](docs/final-demo.md)

## Prerequisites

- Node.js 24 with npm 11, Python 3.11, and [uv](https://docs.astral.sh/uv/getting-started/installation/). The lockfile installs are local to `frontend/node_modules` and `api/.venv`.
- Tesseract 5 with English (`eng`) trained data for scanned PDFs and images. Run `tesseract --version` and `tesseract --list-langs`. The Windows rehearsal used UB Mannheim 5.4.0.20240606. [Tesseract installation guide](https://tesseract-ocr.github.io/tessdoc/Installation.html) · [Windows installer](https://github.com/UB-Mannheim/tesseract/releases/tag/v5.4.0.20240606)
- Chromium for the browser tests. Install it separately with the project-local Playwright command in [Verification](#verification).

Phase 6 locks Next.js 16.4.6, React 19.3.1, FastAPI 0.165.0, Pillow 13.0.0, and Playwright 1.65.1. [Dependency versions and credits](docs/attribution.md#runtime-dependencies)

### Set up Tesseract OCR

The Phase 6 hosted run used Tesseract 5.3.4. On Ubuntu 24.04, CI installs it and the English data with the following packages.

```sh
sudo apt-get update
sudo apt-get install --yes --no-install-recommends tesseract-ocr tesseract-ocr-eng
```

On Windows, use the linked installer with English data. If the executable is outside PATH, copy `api/.env.example` to `api/.env` and set `RAYRIDE_TESSERACT_EXECUTABLE` to its absolute path. Forward slashes work in that setting, for example `C:/Program Files/Tesseract-OCR/tesseract.exe`. Use the actual installed path if it differs. Set `RAYRIDE_OCR_TIMEOUT_SECONDS` in the same file to override the eight-second default.

## Run the CSE491 prototype

From the repository root, start the API in one terminal.

```sh
cd api
uv sync --locked
uv run --locked uvicorn app.main:app --host 127.0.0.1 --port 8000
```

From the repository root, start the web app in another terminal.

```sh
cd frontend
npm ci
npm run dev
```

Open [RayRide](http://127.0.0.1:3000) and check [System status](http://127.0.0.1:3000/status) for **Operational**. The [API health endpoint](http://127.0.0.1:8000/health) checks SQLite readiness. If you change the API port, set the server-only `RAYRIDE_API_URL` in `frontend/.env.local` using [the example](frontend/.env.example). The app accepts loopback HTTP origins. The default SQLite file is `api/data/rayride.sqlite3`. To use a separate file, set `RAYRIDE_DATABASE_PATH` in the API environment. Paths relative to `api/` and absolute paths are supported.

### Try both demo paths

1. Choose `samples/scanned-ticket.pdf` and select **Extract flight details**. Verify `ZZ731`, `AYT`, `2026-12-03`, and `14:10` local time. Enter **Antalya city center**, check the review box and save.
2. Copy the reference from **Reservation saved** and use **Find a reservation** to retrieve it.
3. Start again with `samples/unreadable-ticket.png`. Enter `ZZ969`, `FCO`, `2026-12-19`, `21:20`, and **Fictional Riverside Lodge**. Review and save. [Production rehearsal and fallback slides](docs/final-demo.md) · [Mobile review screenshot](docs/evidence/phase4/report-02-review.png) · [Confirmation screenshot](docs/evidence/phase4/report-03-confirmation.png) · [Manual fallback screenshot](docs/evidence/phase4/report-04-manual-fallback.png)

## Verification

After `uv sync --locked`, run these checks from `api/`. Set `RAYRIDE_REQUIRE_OCR_TESTS=1` before pytest to require real Tesseract and English data, as CI does. In PowerShell use `$env:RAYRIDE_REQUIRE_OCR_TESTS = '1'`. In a POSIX shell use `export RAYRIDE_REQUIRE_OCR_TESTS=1`.

```sh
uv run --locked ruff check .
uv run --locked ruff format --check .
uv run --locked python -m app.export_openapi --check
uv run --locked pytest -q
uv run --locked python -m scripts.evaluate_tickets --corpus original
uv run --locked python -m scripts.evaluate_tickets --corpus phase4
```

After `npm ci`, run these checks from `frontend/`.

```sh
npm run contracts:check
npm run lint
npm run typecheck
npm test
npm run build
npx playwright install chromium
npm run test:e2e
```

The browser suite starts the production web app on port 3131 and the real API on 8131, with an isolated SQLite file. Set `RAYRIDE_CAPTURE_EVIDENCE=1` before `npm run test:e2e` to capture the report screens. The 24 November 2026 hosted Ubuntu run for `9749be2` passed **72 API tests with real OCR, 8 frontend unit tests, and 13 Chromium tests**, as well as contract, lint, type, build, and service smoke checks. [Phase 6 CI run](https://github.com/ThaferAbo/RayRide/actions/runs/45430637548) · [CI workflow](.github/workflows/ci.yml)

The Phase 6 QA fixes clear the previous draft when a replacement is selected and read `ARRIVAL ETA` as time evidence. The independent QA run also verified concurrent saves and retrieval after an API restart. For a local three-engine run, install `chromium firefox webkit` with Playwright and use `npm run test:e2e -- --browser=all --workers=2`. Ubuntu may need Playwright system dependencies. Hosted Chromium results, local browser findings, and OCR scores by corpus and environment are recorded in the audit. [Final QA setup and results](docs/final-qa.md) · [Historical Phase 4 requirements matrix and results](docs/phase4-verification.md)

## Scope and handoff

- CSE491 lives in [`frontend/`](frontend/) and [`api/`](api/). The original, Phase 4 expansion, and final QA [synthetic ticket sets](samples/README.md) each have separate field labels and reproducible generators.
- Use fictional or anonymized tickets. Suggestions can be uncertain or incomplete, especially with small or angled text and ambiguous layouts. Local SQLite holds only reviewed flight and simulated reservation details. The app is a loopback-only prototype with reference-based lookup and no real booking, payment or dispatch.
- See the [architecture and database diagrams](docs/architecture.md), [REST API guide](docs/api.md), [attribution and team evidence](docs/attribution.md), and [proposed CSE492 roadmap](docs/cse492-roadmap.md). Keep local settings, credentials, databases, and personal files out of Git.

## Legacy Flutter demo

The root Flutter app demonstrates passenger transfers in Antalya, driver trip handling, and administration. Its clients expect endpoints that the checked-in `swagger.json` describes only in part. `Backend/` is an ignored local .NET course solution, so a fresh clone does not include it. Neither is required for the CSE491 prototype.

To explore the legacy app, use Flutter with Dart 3.11 or later in the 3.x series. From the repository root, run `flutter pub get` and `flutter run`. The existing [counter test](test/widget_test.dart#L13) failed at baseline because it expects the Flutter starter counter. [Legacy baseline](docs/implementation-log.md#legacy-flutter-baseline)
