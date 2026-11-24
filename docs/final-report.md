# RayRide CSE491 final report

**AI-Assisted Airport Transfer Reservation System · Group 4 · Fall 2026–2027**

Efkan, Thafer and Alperen are the project team listed in the implementation plan. The verified prototype revision is [`005aef6f59fd570f3b83ff35e83664233973fd7a`](https://github.com/ThaferAbo/RayRide/commit/005aef6f59fd570f3b83ff35e83664233973fd7a). The Phase 5 documents accompany that application revision.

## What the prototype delivers

RayRide helps a traveler prepare an airport-transfer request from a flight ticket. It accepts a supported file, attempts to extract the flight number and arrival details locally, and marks each suggestion as extracted, uncertain or missing. The traveler can correct any value or enter the trip manually. An explicit review and a validated destination are required before the service saves a simulated reservation. The traveler can retrieve it by reference.

Next.js serves the booking flow and forwards selected requests to FastAPI over loopback. PDFium reads embedded PDF text or renders pages for OCR. OpenCV prepares images for local English Tesseract, and a rule-based parser derives candidate fields. SQLAlchemy saves reviewed fields in SQLite. The design preserves the airport's local arrival time and stores the record-creation time separately in UTC. Raw tickets and OCR transcripts are not retained by the app. [Architecture, database and privacy](architecture.md) · [REST API contract](api.md)

## Acceptance evidence

| Evidence | Observed result |
| --- | --- |
| Required workflows | Text PDF, scanned PDF, JPEG, ambiguous ticket with a correction, and unreadable ticket with manual entry each produced a saved simulated confirmation. |
| Validation and recovery | Invalid files and incomplete review blocked booking. Error and timeout paths allowed recovery. SQLite rejected a failed write without leaving a row, and a committed reservation was retrievable after an API restart. Retrying an identical keyed request returned the same reference. |
| Accessibility and responsive checks | Automated axe checks found no violations in the four tested states. Chromium checks exercised keyboard focus and no horizontal overflow at 320, 390, 768 and 1280 px. |
| Windows acceptance run | 70 API tests, 8 frontend unit tests and 12 Chromium tests passed with real OCR. Contract checks, lint, formatting checks and production build passed. |
| Hosted Ubuntu 24.04 checks | The run for `005aef6` passed the same 70 API, 8 frontend unit and 12 Chromium tests, both corpus evaluations and the service smoke checks. |
| Phase 5 local rehearsal | Scanned-ticket review and reference lookup passed. The unreadable-ticket fallback saved a second simulated reservation from manual entry. Browser access to external sites was blocked. [Rehearsal record](final-demo.md#rehearsal-record) |

The traceability matrix covers all FR-1–FR-8 and NFR-1–NFR-5. All eight functional requirements and the local checks for NFR-1, NFR-3 and NFR-4 have evidence. NFR-2 and NFR-5 are open. [Requirements matrix, expected and observed results, and commands](phase4-verification.md) · [Hosted run](https://github.com/ThaferAbo/RayRide/actions/runs/45394288030)

### Extraction before review

| Corpus | Windows | Hosted Ubuntu | Wrong confident labeled values |
| --- | ---: | ---: | ---: |
| Original, 8 synthetic tickets | 21/27 (77.8%) | 22/27 (81.5%) | 0 in each run |
| Expansion, 7 synthetic tickets | 14/20 (70.0%) | 15/20 (75.0%) | 0 in each run |

A match requires an exact normalized value marked `extracted`. Missing and uncertain labeled values count as misses. Fields without a single gold value were tracked separately and had no confident output in either run. On Windows the original corpus had four missing and two uncertain labeled values. The expansion had six uncertain labeled values. On hosted Ubuntu the counts were four missing and one uncertain for the original corpus, and five uncertain for the expansion. Scores differ by environment. The evidence does not isolate the cause. These small English-language synthetic samples cannot establish accuracy across airline layouts or languages. [Windows original JSON](evidence/phase4/ocr-original.json) · [Windows expansion JSON](evidence/phase4/ocr-expansion.json) · [Hosted evaluation logs](https://github.com/ThaferAbo/RayRide/actions/runs/45394288030/job/138445797141)

### Report figures

1. [Ticket upload](evidence/phase4/report-01-upload.png) shows the accepted formats, size limit and manual entry.
2. [Mobile review](evidence/phase4/report-02-review.png) shows uncertainty after reading a two-leg ticket.
3. [Saved confirmation](evidence/phase4/report-03-confirmation.png) shows the reviewed trip, simulation label and reference.
4. [Manual fallback](evidence/phase4/report-04-manual-fallback.png) shows missing-field feedback for the unreadable image.

## Limits and handoff

The prototype is ready for a local simulated demo. It uses no real provider, payment or driver dispatch. Reference lookup relies on local access and possession of the reference. There is no sign-in, and accessibility results are limited to the reported browser checks. The legacy Flutter app and local .NET solution are independent of the demo.

| Pending item | Evidence needed |
| --- | --- |
| NFR-2 pilot usability | Observe 2–3 volunteers using the flow unaided and record outcomes and issues. There are no pilot results yet. |
| NFR-5 second development machine | Follow the clean setup and smoke protocol on another machine. The hosted CI run supplies separate cross-platform automation evidence. |
| Individual contributions | Confirm who completed or reviewed each named artifact. The commit records establish the `Thaelith` account and affected files. The team's individual attribution is pending. |
| Delivery | The team must confirm the presentation setup and final submission format, then submit and present the work. |

[Manual protocols](phase4-manual-protocols.md) · [Licenses, asset credits, AI assistance and contribution evidence](attribution.md) · [Presentation outline and live demo](final-demo.md) · [CSE492 roadmap](cse492-roadmap.md)
