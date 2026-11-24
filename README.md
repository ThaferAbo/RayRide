# RayRide

RayRide is the CSE491 airport transfer reservation prototype from Group 4. Phase 1 provides a local status page, a live API health check, and SQLite initialization. Ticket intake, OCR, and simulated reservation workflows are planned for later phases.

| Path | Contents |
| --- | --- |
| [`frontend/`](frontend/) | Next.js App Router, React, TypeScript, and Tailwind CSS |
| [`api/`](api/) | FastAPI, Pydantic contracts, and a SQLAlchemy/SQLite foundation |
| [`docs/implementation-log.md`](docs/implementation-log.md) | Decisions, verification results, and known limitations |
| `lib/`, `test/`, `assets/`, and Flutter platform directories | Legacy Flutter transfer demo |
| `Backend/` | Ignored local .NET course solution, available only on machines that already have it |

## Run the CSE491 foundation

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

Open the [status page](http://127.0.0.1:3000). It should show **Operational**. The [health endpoint](http://127.0.0.1:8000/health) returns `{"status":"ok","database":"ready"}` after SQLite initialization. [API documentation](http://127.0.0.1:8000/docs) shows the live endpoint and the planned data schemas.

The default configuration works without a local environment file. To override it, copy `api/.env.example` to `api/.env` or `frontend/.env.example` to `frontend/.env.local`. The API database path defaults to `api/data/rayride.sqlite3`. Relative database paths resolve from `api/`. The web server reads `RAYRIDE_API_URL` at request time and accepts loopback HTTP origins. Both documented servers bind to `127.0.0.1`.

## Verification and development

Run the API checks from `api/` after `uv sync --locked`.

```sh
uv run --locked ruff check .
uv run --locked ruff format --check .
uv run --locked python -m app.export_openapi --check
uv run --locked pytest -q
```

Run the web checks from `frontend/` after `npm ci`.

```sh
npm run contracts:check
npm run lint
npm run typecheck
npm test
npm run build
npm start
```

`npm start` serves the production build on port 3000. Stop the development server first if it is already using that port. Phase 1 passed local contract checks, lint, typecheck, build, 14 API tests, 3 web tests, and a browser health check against the running API. The CI workflow passed local workflow lint. A hosted run is pending. [Implementation log](docs/implementation-log.md) · [CI workflow](.github/workflows/ci.yml)

Edit the Pydantic models in `api/app/schemas.py` when a contract changes. From `api/`, run `uv run --locked python -m app.export_openapi`. Then, from `frontend/`, run `npm run contracts:generate`. Keep both generated files, `api/openapi.json` and `frontend/lib/api.types.ts`, with the change.

| Route | Status and contract |
| --- | --- |
| `GET /health` | Live. Returns `HealthResponse` or HTTP 503 with `ErrorResponse` if the database check fails. |
| `POST /api/v1/tickets/extract` | Planned. Multipart `ticket` file (PDF, PNG, or JPEG) to `ExtractionResult`. The `TicketExtractor` protocol defines the adapter boundary. |
| `POST /api/v1/reservations` | Planned. `ReservationRequest` with explicitly reviewed data to `ReservationResponse`. |
| `GET /api/v1/reservations/{reference}` | Planned. Retrieves a stored `ReservationResponse` by its confirmation reference. |

Keep the CSE491 work in `frontend/` and `api/`. Leave the legacy applications in their current directories. Use the dependency lockfiles and record commands and observed results in the implementation log. Keep the local plan, personal `AGENTS.md`, credentials, and database files out of Git.

## Attribution and sample data

Use fictional or anonymized ticket fixtures. Record the source, author, license, and required notices for external code, libraries, datasets, images, and other assets. Keep applicable notices with redistributed material. The lockfiles record dependencies and versions. In the project report, disclose AI assistance and record actual team contributions.

Phase 1 uses system fonts and no legacy assets. Verify reuse rights before importing any legacy image or other asset. The planned PDF adapter uses pypdfium2. Review the notices for the selected wheel, including bundled PDFium and third-party licenses, when adding that dependency. [pypdfium2 licensing](https://pypdfium2.readthedocs.io/en/stable/readme.html#licensing)

## Legacy Flutter demo

The Flutter app demonstrates passenger transfers in Antalya, driver trip handling, and admin screens. Its clients expect legacy endpoints that the checked-in `swagger.json` does not fully describe. A fresh clone has no copy of the ignored .NET solution.

To explore the legacy app, use Flutter with Dart 3.11 or later in the 3.x series. From the repository root, run `flutter pub get` and `flutter run`. The pre-existing [`Counter increments smoke test`](test/widget_test.dart#L13) fails because the test expects the Flutter starter counter. The CSE491 checks cover the new frontend and API. See the [legacy baseline in the implementation log](docs/implementation-log.md#legacy-flutter-baseline).
