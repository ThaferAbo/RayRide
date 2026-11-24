# RayRide implementation log

## Phase 1 foundation and API contract

### Decisions

- Used `api/` to avoid a case-insensitive collision with the ignored `Backend/` course solution. Kept the local roadmap and personal agent instructions ignored. Shared development instructions are in the [README](../README.md).
- Used the locked npm and uv environments for the Next.js and FastAPI projects. The Next server requests `GET /health` at render time, limits it to a loopback origin, and reports an unavailable API or database in the page.
- FastAPI initializes SQLite on startup through SQLAlchemy and checks the `reservations` table for readiness. The prototype uses an idempotent `create_all` for the first schema. A later schema change will need an explicit migration. The model stores arrival clock time without an offset and uses a separate UTC creation timestamp.
- OpenAPI publishes the live health route and the planned extraction and reservation schemas. The generated TypeScript types come from that document. Only the health route is live. `TicketExtractor` is a protocol with no implementation. There is no stub OCR or booking endpoint.
- Selected pypdfium2 for a future PDF adapter and deferred its installation to ticket intake. Review the chosen wheel's PDFium and third-party notices before redistribution. Phase 1 uses no legacy assets. Record upstream credits, license terms, fixture provenance, and AI assistance in the project evidence. [pypdfium2 licensing](https://pypdfium2.readthedocs.io/en/stable/readme.html#licensing)

### Verification

The Phase 1 local gate passed on 24 November 2026 on Windows with Node 24.14.0, npm 11.9.0, CPython 3.11.15, and uv 0.11.24.

| Check | Observed result |
| --- | --- |
| API setup with `uv sync --locked` | Installed dependencies into `api/.venv` and verified the lockfile. |
| API checks with `uv run --locked ruff check .`, `uv run --locked ruff format --check .`, and `uv run --locked python -m app.export_openapi --check` | Passed. |
| `uv run --locked pytest -q` | 14 passed. Covers configuration, contract validation, database readiness and failure, duplicate references, and persistence across database reopen. |
| Web setup with `npm ci` | Installed the locked dependencies into `frontend/node_modules`. |
| `npm run contracts:check`, `npm run lint`, `npm run typecheck`, and `npm run build` | Passed. The generated TypeScript contract is kept at LF on Windows and Linux so the generator can compare it byte for byte. |
| `npm test` | 3 passed. Covers valid health responses, failure and malformed responses, and blocked remote URLs. |
| `uv run --locked uvicorn app.main:app --host 127.0.0.1 --port 8000` | Started with an absent default database and created it. Live `/health` returned HTTP 200 and the expected `ok` and `ready` values. Live `/openapi.json` matched the export. SQLite passed `PRAGMA integrity_check` and the reservations table was empty. |
| `npm run dev -- --port 3001` and `npm start` | Both started on loopback. Playwright in Chrome showed **Unavailable** with the API stopped, then **Operational** after API startup and a click on **Refresh status**. The final production page also passed a mobile-width visual check with no browser console errors. |
| `actionlint .github/workflows/ci.yml` | Passed with actionlint 1.7.12. Hosted GitHub Actions execution is pending. |
| `git diff --check` and `git diff --no-index --check` for new paths | Passed. The local roadmap, agent instructions, and database are ignored. Legacy sources were preserved. |

Ticket extraction, reservation behavior, and second-machine verification are later-phase work. No integrated ticket demo or OCR accuracy results were produced in Phase 1.

## Legacy Flutter baseline

Phase 0 ran `flutter test --no-pub --reporter expanded` in a temporary copy against the installed Flutter cache. The only Flutter widget test failed at `test/widget_test.dart:19` because it expected a starter counter with text `0`. Dart analysis exited 0 with 24 deprecation notices, and the cached Flutter web build succeeded. The cached package graph differed from `pubspec.lock`. Phase 1 preserves the Flutter and local .NET applications and uses separate Node and Python checks.
