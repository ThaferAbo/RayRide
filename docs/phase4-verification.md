# Phase 4 acceptance evidence

**Local run on 24 November 2026.** The checkout was based on `be528b8` with the Phase 4 working-tree changes. The test machine ran Windows 11 Pro, Python 3.11.15, uv 0.11.24, Node 24.14.0, npm 11.9.0, and Tesseract 5.4.0.20240606 with English data. The browser tests used Playwright 1.65.1 and Chromium. All reservations and tickets used in the evidence are fictional.

This page preserves the Phase 4 measurements. The published Phase 6 revision `9749be2` and its latest hosted results are recorded separately. [Phase 6 final report](final-report.md#acceptance-evidence)

## Requirements traceability

| ID | Requirement | Result | Evidence and limits |
| --- | --- | --- | --- |
| FR-1 | Accept supported tickets and reject unsupported types | Pass | Text and scanned PDFs, PNG, and JPEG exercised. API tests reject unsupported or mismatched media and oversize requests. Browser tests check unsupported files, multiple dropped files, and the 10 MiB limit. [API tests](../api/tests/test_ticket_extraction.py) · [Browser acceptance](../frontend/tests/e2e/acceptance.spec.ts) |
| FR-2 | Extract flight number and arrival values, flag missing or uncertain fields | Pass | Both labeled corpora ran through the real API before review. Regression tests cover missing arrival columns, terminal suffixes, codeshares, and ambiguous dates or clock qualifiers. [OCR results](#extraction-before-correction) · [Parser tests](../api/tests/test_ticket_fields.py) |
| FR-3 | Make suggestions editable and require review | Pass | The browser blocks save until review and clears review when a field changes. The API independently rejects missing or non-boolean review. A changed local time with fractional seconds was saved after re-review. [Browser flows](../frontend/tests/e2e/booking.spec.ts) · [Reservation tests](../api/tests/test_reservations.py) |
| FR-4 | Allow manual entry and correction after extraction failure | Pass | The unreadable PNG led to missing-field feedback. The traveler entered all flight fields manually and saved from a 390 px viewport. [Browser flows](../frontend/tests/e2e/booking.spec.ts) · [Fallback screenshot](evidence/phase4/report-04-manual-fallback.png) |
| FR-5 | Collect and validate flight details and destination | Pass | The browser validates calendar dates and requires destination. The API rejects invalid airport, date, time and destination values, leaving no rows for rejected requests. [Browser validation](../frontend/tests/booking-contract.test.ts) · [Reservation tests](../api/tests/test_reservations.py) |
| FR-6 | Create a simulated reservation from reviewed data | Pass | The five named workflows committed a simulated reservation. Browser network checks found only same-origin requests. Commit failure produced 503 with no confirmation or row. [Browser flows](../frontend/tests/e2e/booking.spec.ts) · [Reservation tests](../api/tests/test_reservations.py) |
| FR-7 | Display and retrieve saved details, unique reference and simulated status | Pass | The confirmation displayed the saved values, reference and simulation label. API tests verified uniqueness and retrieval after restarting Uvicorn. Browser tests verified reload and lookup in a fresh context. [Confirmation screenshot](evidence/phase4/report-03-confirmation.png) · [Reservation tests](../api/tests/test_reservations.py) |
| FR-8 | Handle invalid and unreadable files, allow retry or manual continuation | Pass | Unsupported, corrupt and oversized inputs were rejected. Browser retry recovered from an API error and an incompatible reply. The suite covered actual Tesseract timeout and the API's recoverable timeout response. [API tests](../api/tests/test_ticket_extraction.py) · [Browser flows](../frontend/tests/e2e/booking.spec.ts) |
| NFR-1 | Reject missing critical fields | Pass | The browser focuses the first invalid field. The API rejects missing, malformed or invalid values and leaves the reservation table unchanged. [Browser acceptance](../frontend/tests/e2e/acceptance.spec.ts) · [Reservation tests](../api/tests/test_reservations.py) |
| NFR-2 | Observe 2–3 pilot users unaided and record issues | Open | Human sessions were not run. The protocol and blank recording fields are ready. [Pilot protocol](phase4-manual-protocols.md#pilot-usability) |
| NFR-3 | Use synthetic or anonymized tickets and protect local data | Pass for local prototype | Samples are synthetic. Real OCR left the scratch directory and reservation table unchanged, and returned no filename or fictional passenger marker. Confirmation responses are uncached and send `Referrer-Policy: no-referrer`. Git ignores local settings, databases, and browser output. [Privacy tests](../api/tests/test_ticket_extraction.py) · [Browser acceptance](../frontend/tests/e2e/acceptance.spec.ts) · [Fixture provenance](../samples/README.md) |
| NFR-4 | Extraction failure preserves manual entry and creates no false booking | Pass | The unreadable scan allowed manual entry, while the real OCR-only request left SQLite unchanged. An unreviewed request and a rejected database write created no reservation. [Browser flows](../frontend/tests/e2e/booking.spec.ts) · [Reservation tests](../api/tests/test_reservations.py) |
| NFR-5 | Reproduce setup on a second development machine | Open | The documented clean setup has not been run on another development machine. Hosted Ubuntu CI passed for the published Phase 4 revision and supplies separate automated evidence. [Second-machine protocol](phase4-manual-protocols.md#second-machine-setup) · [Phase 4 hosted CI](https://github.com/ThaferAbo/RayRide/actions/runs/45394288030) |

## Observed workflow results

| ID | Fixture and requirements | Expected | Observed |
| --- | --- | --- | --- |
| E2E-01 | `text-ticket.pdf` · FR-1–FR-3, FR-5–FR-7 | Text suggestions, review, saved confirmation | **Pass.** Saved `ZZ731`, `AYT`, `2026-12-03`, `14:10:00`, and Antalya city center. Reload and fresh-context lookup returned the same reference. |
| E2E-02 | `scanned-ticket.pdf` · FR-1–FR-3, FR-5–FR-7 | Real OCR suggestions, review, saved confirmation | **Pass.** Tesseract supplied all four matches, and the same reviewed details persisted across reload and lookup. |
| E2E-03 | `image-ticket.jpeg` · FR-1–FR-3, FR-5–FR-7 | Image suggestions, review and saved confirmation | **Pass.** The real image flow saved `6E318` after the arrival airport check and destination entry. |
| E2E-04 | `ambiguous-ticket.pdf` · FR-2–FR-7, NFR-1 | Uncertainty visible, correction, new review and save | **Pass.** All four fields were flagged. Changing the local time cleared the review. Re-review saved the corrected `14:51:05.123456` without converting it. |
| E2E-05 | `unreadable-ticket.png` · FR-4–FR-8, NFR-4 | OCR failure, manual entry and saved confirmation | **Pass.** Four missing fields appeared. After manual entry and review, the confirmation showed Fictional Riverside Lodge. |

All five named workflows passed in Chromium with the production Next.js build and a live local API. The suite also passed checks for invalid and oversized uploads, absent review, wrong calendar dates, cross-origin rejection, malformed upstream replies, missing OCR, OCR timeout, database rollback, lost responses after commit, and duplicate-safe retries. A separate backend test stopped a live Uvicorn process, started a different process with the same SQLite file, and retrieved and replayed the original reservation with only one row. [Browser flows](../frontend/tests/e2e/booking.spec.ts) · [API restart test](../api/tests/test_reservations.py)

Automated axe checks reported no violations in the tested upload, review, fallback and confirmation states. Playwright verified keyboard focus on review, back navigation and validation errors. No horizontal overflow was observed at 320, 390, 768 or 1280 px on the tested flow. These are automated and keyboard checks on Chromium. Screen-reader use and human usability are open. [Accessibility tests](../frontend/tests/e2e/acceptance.spec.ts)

## Extraction before correction

### Windows acceptance run

| Corpus | Correct labeled fields | Confidently wrong | Missing among labeled | Uncertain among labeled | Values supplied confidently on fields with no gold value | All four correct on fully labeled tickets |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Original, 8 tickets | 21/27 (77.8%) | 0 | 4 | 2 | 0/5 | 4/6 |
| Phase 4 expansion, 7 tickets | 14/20 (70.0%) | 0 | 0 | 6 | 0/8 | 2/3 |

Field accuracy counts an exact normalized match only when the API marks the value `extracted`. Missing and uncertain labeled fields count as misses. Fields with no single labeled value are excluded from accuracy and checked separately for confident output. The two corpora have different layouts and difficulty. Each score measures extraction before review. The five browser workflows measure completion after review. [Original results JSON](evidence/phase4/ocr-original.json) · [Expansion results JSON](evidence/phase4/ocr-expansion.json)

The original files and labels matched Git object hashes. The seven expansion fixtures regenerated byte for byte in the tested environment. Before the fix, the expanded set produced a confident `BER` from a departure-only column. The regression run withheld that value. It also extracted `MUC` from the explicit arrival label `MUC Terminal 2`. The expansion still exposes uncertainty with tilted images, flattened columns, qualified clocks and multiple flight identifiers. Results apply to this small English-language synthetic corpus. [Expansion labels](../samples/phase4/expected.json)

### Hosted Ubuntu 24.04 run

| Corpus | Correct labeled fields | Confidently wrong | Missing among labeled | Uncertain among labeled | Values supplied confidently on fields with no gold value | All four correct on fully labeled tickets |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Original, 8 tickets | 22/27 (81.5%) | 0 | 4 | 1 | 0/5 | 5/6 |
| Phase 4 expansion, 7 tickets | 15/20 (75.0%) | 0 | 0 | 5 | 0/8 | 2/3 |

These results are from the hosted check for published revision `005aef6`. The saved JSON files above retain the Windows measurement. [Hosted evaluation logs](https://github.com/ThaferAbo/RayRide/actions/runs/45394288030/job/138445797141)

## Reproduce and capture

From `api/` after OCR setup, use `export RAYRIDE_REQUIRE_OCR_TESTS=1` on POSIX or `$env:RAYRIDE_REQUIRE_OCR_TESTS = '1'` in PowerShell.

```sh
uv sync --locked
uv run --locked ruff check .
uv run --locked ruff format --check .
uv run --locked python -m app.export_openapi --check
uv run --locked pytest -q
uv run --locked python -m scripts.build_phase4_samples
uv run --locked python -m scripts.evaluate_tickets --corpus original
uv run --locked python -m scripts.evaluate_tickets --corpus phase4
```

Add `--output PATH` to either evaluation command to reproduce the JSON. Backend results were **70 passed** with OCR tests required.

From `frontend/`, run the following. Set `RAYRIDE_CAPTURE_EVIDENCE=1` before `npm run test:e2e` to capture the four report PNGs in `test-results/browser/` under their test directories. Use `export` on POSIX or `$env:RAYRIDE_CAPTURE_EVIDENCE = '1'` in PowerShell.

```sh
npm ci
npm run contracts:check
npm run lint
npm run typecheck
npm test
npm run build
npx playwright install chromium
npm run test:e2e
```

Contract checks, lint, typecheck and build passed. **8 frontend unit tests and 12 Chromium tests passed.** Playwright used an isolated SQLite database under the ignored test-results directory. `actionlint` and Git diff checks passed. Hosted CI for `005aef6` passed 70 API, 8 frontend unit and 12 browser tests, both separate corpus evaluations, and the service smoke checks. [Workflow](../.github/workflows/ci.yml) · [Hosted run](https://github.com/ThaferAbo/RayRide/actions/runs/45394288030)

## Screenshots for the report

1. [Desktop ticket upload](evidence/phase4/report-01-upload.png) shows the simulated flow, allowed formats and manual entry.
2. [Mobile flight review](evidence/phase4/report-02-review.png) shows the uncertain fields from the two-leg ticket.
3. [Desktop saved confirmation](evidence/phase4/report-03-confirmation.png) shows the saved reference and the reviewed simulated trip after reload.
4. [Mobile manual fallback](evidence/phase4/report-04-manual-fallback.png) shows the missing fields after the unreadable PNG.

**Local Phase 4 gate and hosted CI passed.** NFR-2 and NFR-5 are still open. [Manual protocols](phase4-manual-protocols.md)
