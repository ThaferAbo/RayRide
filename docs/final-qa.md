# RayRide final QA audit

**24 November 2026 · CSE491 Group 4**

The audit started from a clean checkout of the Phase 5 baseline `23c4fb1a8502cef5fb40b27c250b16047ba2834d`. The fixes and audit evidence were published in Phase 6 at `9749be2685a56df789f393071d7ec1ead93f6091`. The local measurements below were collected before publication. All tickets and bookings were fictional. [Published revision](https://github.com/ThaferAbo/RayRide/commit/9749be2685a56df789f393071d7ec1ead93f6091)

## Clean environment

| Item | Observed setup |
| --- | --- |
| Host and isolation | Windows 11 Pro host, Ubuntu 26.04.1 LTS in WSL 2, x86-64, kernel `6.6.87.2-microsoft-standard-WSL2`. The Linux checkout used its own filesystem. WSL saw 12 logical CPUs on an AMD Ryzen 5 7535HS. |
| Source and local state | A fresh `git clone --no-local` began without `api/.venv`, `frontend/node_modules`, either local environment file, or an API database directory. npm and uv caches were scoped to the audit. |
| Language tools | Fresh Node 24.14.0/npm 11.9.0 and managed Python 3.11.18. uv 0.13.9 ran the local audit. uv 0.11.24, the CI version, resolved and installed the corrected lockfile. |
| OCR and browsers | Freshly extracted Ubuntu packages supplied Tesseract 5.5.0, `eng`, and browser system libraries inside the audit directory. The system package database was left intact. Playwright 1.65.1 installed its own browsers. |
| Application | Production Next.js on `127.0.0.1:3185` and FastAPI on `127.0.0.1:8185` for exploratory checks, with a fresh SQLite file. The Playwright suite used separate services on 3131/8131 and separate databases. |

The clean locked installs, contract checks, API lint/format checks, web lint/typecheck and production build succeeded. The initial Phase 5 baseline ran **70 API tests with real OCR required** and **8 frontend unit tests**. WSL is on the original physical machine. [Base setup instructions](../README.md#run-the-cse491-prototype) · [Manual verification protocols](phase4-manual-protocols.md)

## Findings and fixes

| Finding | Reproduction and fix |
| --- | --- |
| Prior trip silently reused after a replacement ticket failed | In a clean Chromium session, review `scanned-ticket.pdf`, go back, choose a damaged PDF, attempt extraction, and select **Enter details manually**. The old flight, airport, date, and time appeared without extraction badges. A new file selection now clears the previous draft. Going back and returning without selecting a file retains the draft. [Browser regression](../frontend/tests/e2e/booking.spec.ts) |
| OCR interpreted ETA as the arrival airport | `eta-without-airport.png` returned `ETA` as an extracted airport even though the card had only an estimated arrival time. The parser now treats `ARRIVAL ETA` as a time label. A parser regression and a real-Tesseract API regression both exposed the original error. [Parser test](../api/tests/test_ticket_fields.py) · [OCR API test](../api/tests/test_ticket_extraction.py) |
| The locked Pillow version had known security advisories | `uv audit --locked --no-dev` reported 43 advisory findings for Pillow 12.3.0 across 23 scanned runtime packages. The range excluded the available patched major release. The lockfile update moved only Pillow, to 13.0.0. The same audit then found no known vulnerabilities in its scanned set. The npm runtime audit also returned zero. [Pillow release notes](https://pillow.readthedocs.io/en/stable/releasenotes/13.0.0.html) · [uv lockfile](../api/uv.lock) |

## Exploratory browser sessions

An AI-assisted walkthrough used a fresh Chromium context, the on-page labels, and the tasks from the pilot protocol. It exercised the chooser, a scanned ticket, returning from review, a damaged replacement, manual recovery, and keyboard submission of both a malformed reference and a well-formed unknown reference. The first lookup produced a format hint. The second normalized whitespace and case and displayed **Reservation not found**. After the draft fix, the replacement's manual fallback displayed blank fields and an unchecked review box.

The automated suite also exercises text PDF, scanned PDF, JPEG, ambiguous-ticket correction, and unreadable-ticket recovery, with persistent confirmations. Other cases cover unsupported or oversized intake, keyboard focus through review and back, field-level validation, reflow at 320, 390, 768 and 1280 px, retry after a failed extraction, and retry after a committed save whose reply was lost. [Booking tests](../frontend/tests/e2e/booking.spec.ts) · [Acceptance checks](../frontend/tests/e2e/acceptance.spec.ts)

## Browser and automated results

| Environment | Observed result |
| --- | --- |
| Hosted Ubuntu 24.04 CI at `9749be2` | **72 API tests with real OCR, 8 frontend unit tests, and 13 Chromium tests passed.** Both preserved OCR evaluations and the API/web smoke checks passed. The runner used Node 24.22.3, npm 11.19.1, Python 3.11.15, uv 0.11.24, Tesseract 5.3.4 with English data, Pillow 13.0.0, and Chromium 159.0.8154.6. [Phase 6 CI logs](https://github.com/ThaferAbo/RayRide/actions/runs/45430637548/job/138574659791) |
| Chromium 159.0.8154.6 in WSL | **13/13 passed**, including all five booking paths, keyboard focus, reflow and axe scans in the tested states. |
| WebKit 27.2 in WSL | **13/13 passed** after the temporary library-path correction. This tested the WebKit engine with emulated widths. |
| Firefox 159.0 in WSL | **11/13 passed**, including all five booking paths, replacement-ticket recovery and keyboard navigation. The two acceptance tests that include axe scanning ended with browser content-process crashes. |
| Firefox 159.0 on Windows | The same two acceptance tests crashed when rerun in a fresh Windows harness against the WSL app. Single-worker, software-rendering, and legacy axe attempts in WSL also failed to complete those scans. |
| Firefox 159.0, Playwright browser revision 1578 in WSL | Direct axe scans in fresh pages found zero violations in all four states. A separate run exercised reflow at 320, 390, 768 and 1280 px on upload, review and reopened confirmation. |
| API and checks | **72 API tests passed with real OCR required**. Ruff lint and formatting and the OpenAPI check passed. The web contract check and **8 frontend unit tests** passed. Web lint, typecheck and the production build passed after the booking fix. |

The local Chromium and WebKit suites reported no axe violations on upload, ambiguous review, confirmation, and unreadable-ticket fallback. Supplemental Firefox scans used the same WCAG tags with `axe.run` in separate pages and passed those four states. Two tests in the pinned Firefox runner remain **open**. The audit did not establish the cause of their content-process crashes. Hosted CI exercised Chromium.

- `report evidence and accessibility on upload, review and persisted confirmation`
- `report evidence and accessibility on unreadable ticket fallback`

[Acceptance test source](../frontend/tests/e2e/acceptance.spec.ts)

## Live isolation, privacy and concurrent writes

- An ordinary request from another loopback origin returned 403. An unreviewed save returned 422, a non-JSON reservation request 415, and a well-formed unknown reference 404. Rejected writes left the row count unchanged.
- A successful real OCR upload omitted its fictional filename from the response, left an initially empty process scratch directory empty, and inserted no reservation. The confirmation page used `Cache-Control: no-store` and `Referrer-Policy: no-referrer` and set no cookie in the observed response. References can still appear in local access logs.
- Twelve simultaneous saves with one retry key and the same payload returned one 201 and eleven 200s, one reference and one additional row. Reusing that key with different details returned 409. Eight simultaneous saves with independent keys returned eight 201s and eight distinct saved references.
- After the API restarted with the same SQLite file, both the API and web page returned the original trip. A keyed replay returned 200, the same reference, and the same row count.

The probes used the local app with ordinary requests and defensive dependency checks. Reference-only lookup and the lack of sign-in remain limits of the local prototype.

## Local performance

The measurements used the production web server over loopback on the WSL host. Each serial case had two warm-ups and nine timed requests. Timings include reading the whole response. The homepage check measures HTML only. The scanned-PDF request went through the Next.js proxy and performed real OCR on each submission.

| Request | Observed time |
| --- | --- |
| Homepage HTML | 2.3 ms median, 3.2 ms slowest |
| Scanned PDF through the web proxy | 359.1 ms median, 381.0 ms slowest |
| Six simultaneous scans of the same synthetic PDF | All six returned the expected airport. The batch took 1.20 s and the slowest response took 1.19 s. |

These figures describe this machine and input. Production throughput and browser rendering time were outside this measurement.

## Independent OCR probes

Five new synthetic images cover overnight arrival, 90-degree rotation, low-resolution JPEG, an ETA with no printed airport, and a UTC clock with no local-clock value. The [field labels](../samples/final-qa/expected.json) were written from the intended content before extraction. The generator uses Pillow's built-in font and does not load those labels. The original and Phase 4 fixtures, labels and saved benchmark results are maintained separately.

Both runs extracted **8/18** labeled fields, with five missing and five uncertain. There were no confidently wrong predictions on labeled fields. The baseline confidently filled **1/2** fields without a gold value. The fixed run filled **0/2**. Rotation left all four fields missing, and the low-resolution JPEG yielded only the time. The overnight panel kept the next day's arrival date and time. The UTC-only clock did not yield a local time. [Before JSON](evidence/final-qa/ocr-before.json) · [After JSON](evidence/final-qa/ocr-after.json)

The paired WSL runs returned identical per-ticket outputs before and after the fixes for the original corpus (22/27) and the Phase 4 expansion (15/20). The five audit fixtures also regenerated byte for byte with Pillow 13. Hosted CI for `9749be2` reported 22/27 (81.5%) and 15/20 (75.0%) for those preserved corpora, matching the Phase 4 hosted totals. The five-image QA scores above are from WSL. [Historical benchmark records](phase4-verification.md#extraction-before-correction) · [Phase 6 CI logs](https://github.com/ThaferAbo/RayRide/actions/runs/45430637548/job/138574659791)

To repeat the separate evaluation from `api/`, use `uv run --locked python -m scripts.evaluate_tickets --corpus final-qa`. To regenerate its images, use `uv run --locked python -m scripts.build_final_qa_samples`. An `extracted` exact match counts as correct. Missing and uncertain fields count as misses. Fields without a gold value are tallied separately.

## Screenshots from the running app

- [Before the draft fix](evidence/final-qa/01-stale-after-invalid.png) shows the first ticket's values in manual entry after the replacement failed.
- [After the draft fix](evidence/final-qa/02-clean-replacement-draft.png) shows the empty manual form after the same replacement sequence.
- [Saved confirmation](evidence/final-qa/03-chromium-confirmation.png) shows the persisted synthetic trip after reload.
- [Unreadable ticket at 390 px](evidence/final-qa/04-chromium-mobile-fallback.png) shows the missing fields and recovery controls.
- [Ambiguous ticket in WebKit at 390 px](evidence/final-qa/05-webkit-mobile-review.png) shows the review flags and untouched form.

## Reproducible checks

Start from the published Phase 6 revision `9749be2`, which includes the fixes and new fixture images. The [README](../README.md#prerequisites) documents the normal setup. The Linux audit used `apt-get download` and `dpkg-deb -x` for browser libraries and Tesseract because passwordless sudo was unavailable. WebKit's temporary launcher preserved the audit library path, and Playwright's system-cache preflight was disabled for that isolated launch. WebKit then loaded and exercised the app with those libraries.

Run from `api/` in the clean clone.

```sh
uv sync --locked
uv run --locked ruff check .
uv run --locked ruff format --check .
uv run --locked python -m app.export_openapi --check
RAYRIDE_REQUIRE_OCR_TESTS=1 uv run --locked pytest -q
uv run --locked python -m scripts.evaluate_tickets --corpus original
uv run --locked python -m scripts.evaluate_tickets --corpus phase4
uv run --locked python -m scripts.evaluate_tickets --corpus final-qa
```

Run from `frontend/` after supplying any required operating-system libraries.

```sh
npm ci
npm run contracts:check
npm run lint
npm run typecheck
npm test
npm run build
npx playwright install chromium firefox webkit
npm run test:e2e -- --browser=all --workers=2
```

Use `RAYRIDE_CAPTURE_EVIDENCE=1` for the existing report captures. The dependency checks were `uv audit --locked --no-dev` with uv 0.13.9 and `npm audit --omit=dev`.

## Open verification

- **NFR-2 is open.** The exploratory sessions were AI-assisted and the automated accessibility scans cover selected states. The team still needs 2–3 unaided pilot observations. Screen-reader use has yet to be checked.
- **NFR-5 is open.** A locked install and live rehearsal on WSL verify a clean environment on the original host. Setup on a separate physical machine remains to be recorded.
- **Individual contribution confirmation is open.** The team still needs to confirm named contributions against artifacts or records. [Contribution evidence](attribution.md#team-contributions)
- **Two pinned Firefox failures are open.** The supplemental scans provide evidence for the tested states. [Browser results](#browser-and-automated-results)
- The prototype accepts fictional or anonymized tickets for simulated local booking. OCR can miss rotated, low-resolution, cropped or ambiguous fields. Review is required before saving.

[Pilot and second-machine protocols](phase4-manual-protocols.md)

**Release readiness.** The published Phase 6 revision is ready for a local simulated demo in Chromium. The separate WSL audit also passed the WebKit suite. The four open items above remain part of the handoff. [Release summary](final-report.md#limits-and-handoff)
