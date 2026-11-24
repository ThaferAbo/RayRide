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

## Phase 2 ticket intake and extraction

### Implementation and decisions

- `POST /api/v1/tickets/extract` accepts one PDF, PNG, or JPEG as a multipart `ticket` file. The API bounds the file, request, PDF pages, and decoded images. It checks the declared format, signature, and decoder result. Uploads stay in memory, Tesseract reads from stdin, and the endpoint writes no files, raw OCR logs, or database rows.
- pypdfium2 reads embedded text first and renders pages for OCR when text is incomplete or unusable. Pillow validates images, OpenCV prepares grayscale contrast, and Tesseract reports English word confidence. Tesseract has an 8-second default budget across OCR pages. The PDFium work is serialized within the process because PDFium is not thread-safe. [PDFium threading documentation](https://pypdfium2.readthedocs.io/en/stable/python_api.html#incompatibility-with-threading)
- The parser distinguishes arrival labels from departure labels, requires an unambiguous date with a year, and preserves the printed local clock time. Conflicting legs, ambiguous numeric dates, low OCR confidence, and qualified times that cannot be interpreted safely are sent for review. The endpoint returns typed partial or unavailable results for OCR failure. The web app continues to show health, and booking paths remain absent.
- Python dependencies are locked in `api/uv.lock`. The Windows run used the checksum-verified UB Mannheim Tesseract 5.4.0.20240606 and its English trained data, configured through the ignored `api/.env`. The workflow installs the Ubuntu 24.04 Tesseract and English packages and fails if real OCR tests cannot run. Keep the relevant PDFium, Tesseract and trained-data, OpenCV, and Pillow notices if redistributing their binaries. [Windows and Ubuntu setup](../README.md#set-up-tesseract-ocr)

### Observed field accuracy

On 24 November 2026, `uv run --locked python -m scripts.evaluate_tickets` posted eight synthetic tickets to the real extraction endpoint. The gold values were recorded independently in `samples/expected.json`. A hit requires an `extracted` status and an exact normalized gold match. Missing and uncertain responses count as misses for known fields. The five fields without one annotated answer are excluded from that denominator and checked for unsupported confident output. No answers were manually corrected before scoring. [Corpus and reproduction](../samples/README.md)

| Fixture | Observed method | Correct / labeled | Observed issue |
| --- | --- | ---: | --- |
| Text PDF | `pdf_text` | 4 / 4 | All four fields matched. |
| Same ticket as a scanned PDF | `ocr` | 4 / 4 | All four fields matched. |
| PNG | `ocr` | 3 / 4 | Tesseract read `QX` as `OX` with low confidence. The API withheld the flight number and flagged it. |
| JPEG | `ocr` | 4 / 4 | All four fields matched. |
| Ambiguous two-leg PDF | `pdf_text` | 0 / 1 | All fields were flagged. The shared date was available only as uncertain. The other three fields have no single gold value. |
| PDF with missing arrival fields | `mixed` | 2 / 2 | Arrival date and time were flagged as missing. The parser ignored the departure date and time. |
| Mixed text and raster PDF | `mixed` | 4 / 4 | Both sources contributed the needed fields. |
| Degraded PNG | `unavailable` | 0 / 4 | All four known source fields were flagged as missing. |
| **Total** | | **21 / 27 (77.8%)** | **0 confidently wrong, 2 uncertain and 4 missing among labeled fields. No confident values for the five unlabeled fields.** |

Results describe this small English-language synthetic corpus and Windows OCR build. Unlabeled tables, different languages, and complex schedules may need manual entry. The parser does not verify airports or flights against a live database or infer time zones.

### Verification and gate

| Check | Observed result |
| --- | --- |
| `uv sync --locked` | Installed and verified the API environment. |
| API Ruff lint and format, OpenAPI export check, and `uv run --locked pytest -q` with `RAYRIDE_REQUIRE_OCR_TESTS=1` | Passed. 49 tests passed, including seven real Tesseract cases. Coverage includes format and size rejection, departure/arrival ambiguity, OCR timeout, recoverable process failure, and upload privacy. |
| Sample generation and rendering | Recreated all eight binary samples byte for byte on Windows. Rendered and visually inspected all six PDF pages with Poppler. |
| Frontend contract generation and check, `npm run lint`, `npm run typecheck`, `npm test`, and `npm run build` | Passed. Three frontend tests passed. |
| Live Uvicorn and Next.js smoke checks | Health and frontend readiness passed. Real chunked uploads of PDFs, PNG, and JPEG returned the expected methods and field statuses. An unsupported upload returned 415. Live OpenAPI matched the generated contract. |
| Workflow and Git checks | `actionlint` and Git whitespace checks passed. Hosted CI execution is pending. Legacy Flutter and local .NET paths were preserved. |

**Phase 2 local gate passed.** The API accepts and validates supported files, preserves usable suggestions when OCR fails, and returns explicit missing or uncertain fields. Traveler review, reservation creation and retrieval, and end-to-end workflow acceptance remain later-phase work.

## Phase 3 review and simulated reservations

### Shipped behavior

- The responsive Next.js flow starts with ticket upload or manual entry. It shows the source status for each flight field, resets review after edits, allows destination selection or custom entry, and displays a confirmation from the saved record. A traveler can reload or look up the confirmation by its reference. The original readiness check is available at `/status`.
- The browser uses same-origin routes. The Next.js server forwards only the defined operations to the configured loopback API, with request and response byte and time limits and no caching. The FastAPI ticket limits and parser are unchanged. Neither the web app nor the API saves uploads or OCR transcripts.
- The reservation API persists only reviewed trip details, a reference, the simulated status, and the UTC creation timestamp. Arrival date and time remain local strings throughout browser review. SQLite stores their date and time values without a timezone. The API returns the confirmation after commit. An identical retry with the same key reads the committed confirmation. The SQLite primary key prevents competing writes from creating duplicate references.
- The hero image is original AI-generated artwork for this project. The web asset is `frontend/public/rayride-coast.webp` and was generated with the built-in ImageGen tool. Manrope is distributed under the SIL Open Font License and Phosphor Icons under MIT. No legacy imagery was reused.

### Local verification on 24 November 2026

The Phase 3 working tree was tested on Windows with Tesseract 5.4 and Chromium through Playwright 1.65.1. The checkout started at `22fe779`. Tests wrote only to isolated databases.

| Check | Observed result |
| --- | --- |
| `uv sync --locked`, Ruff lint and format, OpenAPI export check, and `uv run --locked pytest -q` with `RAYRIDE_REQUIRE_OCR_TESTS=1` | Passed. **61 tests**, including direct validation, failed commit rollback, concurrent retry, and retrieval after the API reopens SQLite. |
| `uv run --locked python -m scripts.evaluate_tickets` | Phase 2 measurement reproduced at **21/27** labeled fields before manual correction. |
| `npm ci`, contract generation and check, lint, typecheck, `npm test`, and production build | Passed. **7 unit tests**, including bounded forwarding, rejecting other origins, and upstream timeout handling. |
| `npm run test:e2e` | Passed. **8 Chromium tests** used the production Next.js build and a live local FastAPI instance. Confirmed no cross-origin browser requests during the text and scanned ticket flows. |
| Workflow and Git checks | Local `actionlint` and Git whitespace checks passed. The legacy Flutter and local .NET paths were preserved. Hosted CI execution is pending. |

| Browser scenario | Observed result |
| --- | --- |
| `text-ticket.pdf` and `scanned-ticket.pdf` | Saved the reviewed flight values with the chosen destination. Reload and lookup in a fresh browser context returned the same reference and details. |
| `image-ticket.jpeg` | Extracted the flight and arrival airport and saved the reviewed reservation. |
| `ambiguous-ticket.pdf` | Displayed four uncertain fields. Editing cleared the previous review, and a new review saved the corrected values including fractional local seconds. |
| `unreadable-ticket.png` | Displayed missing fields and recovered through manual entry. Saved the reviewed values in a 390-pixel-wide browser viewport. |
| Invalid file, invalid review, and API failures | Rejected an unsupported format, a corrupted PDF, an invalid airport, an unreviewed submission, and a cross-origin write. Recovered from an extraction error and an incompatible reply. |
| Lost reply after commit | The interface disabled the pending save action. Retrying with the same trip details returned the already-saved reservation with the same reference. |
| System status | The retained readiness page reported the API and SQLite as operational. |

**Phase 3 local gate passed.** The main and fallback flows are ready to demonstrate on this machine. OCR accuracy is measured on a small synthetic corpus. Retry recovery retains the same key while the current form is open. Confirmation lookup depends on possession of the reference and access to the local app. Hosted CI, pilot usability, and second-machine reproduction are unverified. [Meeting 5 rehearsal checklist](meeting-5-demo.md)

### Hero artwork prompt

> Create an original photorealistic editorial travel photograph for a very wide airport transfer booking website hero. View from above the deep navy Aegean waters toward a sunlit Mediterranean coastline, warm pale limestone cliffs and a small coastal city with distant mountains. A single unbranded white commercial airplane banks gently toward the city on the right side, seen from above and slightly behind. Put the aircraft and almost all land in the right half, with generous dark open water across the left half for readable overlaid website text. Wide panoramic framing with the key visual in the middle vertical band so a 3:1 center crop works. Natural late-afternoon haze, warm ivory highlights, restrained teal water, premium and plausible travel photography. No words, typography, graphics, logos, airline marks, watermarks or borders.

## Phase 4 acceptance testing, reliability and usability

- Fixed a confirmed false arrival airport in flattened departure/arrival columns. Added extraction for terminal suffixes on explicitly labeled arrival airports. Both fixes have parser and HTTP regression coverage.
- Fixed lost keyboard focus when returning to upload and silent acceptance of the first of multiple dropped files. Booking now validates calendar dates before submission and confirmation pages prevent referrer disclosure.
- Verified SQLite rollback after a real database rejection, retry after failure, and retrieval and idempotent replay across two Uvicorn processes. Verified that real OCR leaves no scratch files or reservation rows and omits the upload filename and passenger marker from the response and captured logs.
- Ran the local gate on 24 November 2026. **70 API tests, 8 frontend unit tests and 12 Chromium tests passed.** The five required workflows saved simulated reservations. Keyboard, reflow, and automated accessibility checks passed in the tested pages. Hosted CI passed on `be528b8`, the published Phase 3 baseline. Hosted execution of the Phase 4 worktree is pending. [Acceptance evidence and screenshots](phase4-verification.md) · [Phase 3 hosted CI](https://github.com/ThaferAbo/RayRide/actions/runs/45390325875)
- The original corpus and labels are unchanged and reproduced at **21/27**. The seven independently labeled expansion fixtures scored **14/20**. Neither run returned a confidently wrong labeled value. Both scores are before manual correction. [Original benchmark](evidence/phase4/ocr-original.json) · [Expansion benchmark](evidence/phase4/ocr-expansion.json)

**The local Phase 4 gate passed.** The traceability matrix marks pilot usability and second-machine reproduction open. No human results or Phase 4 hosted results were recorded. [Manual protocols](phase4-manual-protocols.md)

## Legacy Flutter baseline

Phase 0 ran `flutter test --no-pub --reporter expanded` in a temporary copy against the installed Flutter cache. The only Flutter widget test failed at `test/widget_test.dart:19` because it expected a starter counter with text `0`. Dart analysis exited 0 with 24 deprecation notices, and the cached Flutter web build succeeded. The cached package graph differed from `pubspec.lock`. Phase 1 preserves the Flutter and local .NET applications and uses separate Node and Python checks.
