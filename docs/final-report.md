# RayRide CSE491 final report

**AI-Assisted Airport Transfer Reservation System · Group 4 · Fall 2026–2027**

Efkan, Thafer and Alperen are the project team listed in the implementation plan. The published Phase 6 release revision is `9749be2685a56df789f393071d7ec1ead93f6091`. The latest hosted check for that revision passed on 24 November 2026. [Published revision](https://github.com/ThaferAbo/RayRide/commit/9749be2685a56df789f393071d7ec1ead93f6091) · [Hosted CI](https://github.com/ThaferAbo/RayRide/actions/runs/45430637548)

## What the prototype delivers

RayRide helps a traveler prepare an airport-transfer request from a flight ticket. It accepts a supported file, attempts to extract the flight number and arrival details locally, and marks each suggestion as extracted, uncertain or missing. The traveler can correct any value or enter the trip manually. An explicit review and a validated destination are required before the service saves a simulated reservation. The traveler can retrieve it by reference.

Next.js serves the booking flow and forwards selected requests to FastAPI over loopback. PDFium reads embedded PDF text or renders pages for OCR. OpenCV prepares images for local English Tesseract, and a rule-based parser derives candidate fields. SQLAlchemy saves reviewed fields in SQLite. The design preserves the airport's local arrival time and stores the record-creation time separately in UTC. Raw tickets and OCR transcripts are not retained by the app. [Architecture, database and privacy](architecture.md) · [REST API contract](api.md)

## Acceptance evidence

| Evidence | Observed result |
| --- | --- |
| Required workflows | Text PDF, scanned PDF, JPEG, ambiguous ticket with a correction, and unreadable ticket with manual entry each produced a saved simulated confirmation. |
| Validation and recovery | Invalid files and incomplete review blocked booking. Error and timeout paths allowed recovery. SQLite rejected a failed write without leaving a row, and a committed reservation was retrievable after an API restart. Retrying an identical keyed request returned the same reference. |
| Phase 6 hosted CI on Ubuntu 24.04 | **72 API tests with real OCR, 8 frontend unit tests, and 13 Chromium tests passed.** Contract checks, lint, formatting, typecheck, production build, both preserved corpus evaluations, and API/web smoke checks passed. [Run logs](https://github.com/ThaferAbo/RayRide/actions/runs/45430637548/job/138574659791) |
| Phase 6 independent QA on WSL 2 | **72 API, 8 frontend unit, 13/13 Chromium, and 13/13 WebKit tests passed.** Firefox passed 11/13 in the pinned runner. Two combined acceptance tests crashed. Direct axe scans on Firefox browser revision 1578 covered four states without violations. The audit also verified keyboard focus, reflow at 320–1280 px, concurrent saves, and retrieval after restart. [QA results and limits](final-qa.md#browser-and-automated-results) |
| Historical Phase 4 acceptance | The local Windows run and hosted Ubuntu CI for `005aef6` each passed 70 API, 8 frontend unit, and 12 Chromium tests with real OCR. [Phase 4 evidence](phase4-verification.md) |
| Historical Phase 5 rehearsal at `005aef6` | Scanned-ticket review and lookup passed. Manual entry saved a second reservation after OCR failed. External browser requests were blocked. [Rehearsal record](final-demo.md#rehearsal-record) |

The traceability matrix covers FR-1–FR-8 and NFR-1–NFR-5. All eight functional requirements and the local checks for NFR-1, NFR-3 and NFR-4 have evidence. NFR-2 and NFR-5 remain open. [Requirements matrix and workflow evidence](phase4-verification.md)

Phase 6 cleared stale form values after a ticket replacement, corrected the ETA-as-airport error, and updated Pillow from 12.3.0 to 13.0.0. The backend and browser suites include regression checks for the two behavior fixes. [QA findings and fixes](final-qa.md#findings-and-fixes) · [Locked dependencies](attribution.md#runtime-dependencies)

### Extraction before review

| Preserved corpus | Phase 4 Windows | Phase 4 hosted Ubuntu | Phase 6 hosted Ubuntu |
| --- | ---: | ---: | ---: |
| Original, 8 synthetic tickets | 21/27 (77.8%) | 22/27 (81.5%) | 22/27 (81.5%) |
| Phase 4 expansion, 7 synthetic tickets | 14/20 (70.0%) | 15/20 (75.0%) | 15/20 (75.0%) |

A match requires an exact normalized value marked `extracted`. Missing and uncertain labeled values count as misses. Across the reported runs, the preserved corpora had zero confidently wrong labeled values and zero confident fills on fields without a single expected value. The two hosted runs both reported four missing and one uncertain value for the original corpus, and five uncertain values for the expansion. The paired WSL checks also returned identical per-ticket results before and after the Phase 6 fixes. These small English-language synthetic samples cannot establish accuracy across airline layouts or languages. [Phase 4 benchmark records](phase4-verification.md#extraction-before-correction) · [Phase 6 hosted evaluation logs](https://github.com/ThaferAbo/RayRide/actions/runs/45430637548/job/138574659791)

The separate five-image QA set scored **8/18 (44.4%)** labeled fields both before and after the fixes in WSL. The number of confidently filled fields without an expected value fell from **1/2 to 0/2**. Rotation and low resolution remain weaknesses. The hosted workflow scores the two preserved corpora. [Separate QA corpus and raw results](final-qa.md#independent-ocr-probes)

### Report figures

1. [Ticket upload](evidence/phase4/report-01-upload.png) shows the accepted formats, size limit and manual entry.
2. [Mobile review](evidence/phase4/report-02-review.png) shows uncertainty after reading a two-leg ticket.
3. [Saved confirmation](evidence/phase4/report-03-confirmation.png) shows the reviewed trip, simulation label and reference.
4. [Manual fallback](evidence/phase4/report-04-manual-fallback.png) shows missing-field feedback for the unreadable image.

## Limits and handoff

The published Phase 6 revision is ready for a local simulated demo in Chromium. The audit also passed the WebKit suite. Reference lookup relies on local access and possession of the reference. The prototype uses no sign-in, real provider, payment, or driver dispatch. Accessibility results cover the tested browser states. The legacy Flutter app and local .NET solution are independent of the demo.

| Pending item | Evidence needed |
| --- | --- |
| NFR-2 pilot usability | Observe 2–3 volunteers using the flow unaided and record outcomes and issues. There are no pilot results yet. |
| NFR-5 second development machine | Follow the clean setup and smoke protocol on another machine. The hosted CI run supplies separate cross-platform automation evidence. |
| Individual contributions | Confirm who completed or reviewed each named artifact. The commit records establish the `Thaelith` account and affected files. The team's individual attribution is pending. |
| Two pinned Firefox test failures | Investigate the crashes in the upload/review/confirmation and unreadable-fallback acceptance tests. The separate successful axe scans leave both test failures open. [Browser results](final-qa.md#browser-and-automated-results) |
| Delivery | The team must confirm the presentation setup and final submission format, then submit and present the work. |

[Manual protocols](phase4-manual-protocols.md) · [Licenses, asset credits, AI assistance and contribution evidence](attribution.md) · [Presentation outline and live demo](final-demo.md) · [CSE492 roadmap](cse492-roadmap.md)

The [Phase 6 QA screenshots](final-qa.md#screenshots-from-the-running-app) show the replacement-draft fix, saved confirmation, and mobile recovery and review.
