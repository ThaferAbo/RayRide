# Phase 4 manual verification protocols

NFR-2 and NFR-5 are **open**. Record only observations from actual volunteers and a separate physical development machine.

## Pilot usability

1. Recruit 2–3 volunteers who have not used RayRide. Get their agreement to take part and label records `P01`, `P02` and `P03`. Record revision `9749be2` for the release pilot. Use an isolated local database and the repository's synthetic tickets.
2. Start each volunteer at the booking page. Give them the scanned sample and the task “Save a simulated transfer to Antalya city center and find its confirmation again.” Observe without explaining where to click. If someone gets blocked, record the unaided outcome before helping. Record assisted completion separately.
3. Repeat with the unreadable PNG and a separate card with the fictional flight details `ZZ969`, `FCO`, `2026-12-19`, `21:20`, and `Fictional Riverside Lodge`. Give the information needed to complete the task and let the participant discover manual entry.
4. Record completion, saved-value accuracy, time or step count, errors, assistance, and one short comment. Report counts with their denominator and flag issues by impact. Leave an unobserved field blank. Keep names, contact information, real tickets, and real booking references out of the notes.

| ID | Device and viewport | Scanned flow complete | Manual fallback complete | Time or steps | Errors and assistance | Observed issue |
| --- | --- | --- | --- | --- | --- | --- |
| P01 | | | | | | |
| P02 | | | | | | |
| P03, if recruited | | | | | | |

## Second-machine setup

1. Use a different physical development machine and a fresh copy of the published Phase 6 revision `9749be2`. Keep the original machine's `.env`, virtual environment, `node_modules`, and SQLite files out of the copy.
2. Follow the [README](../README.md) to install Node 24, npm 11, Python 3.11, uv and Tesseract English data. Record the OS, architecture, revision, tool versions, `tesseract --list-langs` and any setup changes needed.
3. Use a fresh local SQLite file. Start the API and web app. Verify **Operational**, upload `scanned-ticket.pdf`, save a simulated reservation and look it up after restarting the API with the same SQLite file.
4. Run the [release checks](../README.md#verification) with real OCR required. Record exact commands, pass/fail/skip counts and differences from the first machine. Mark NFR-5 verified once setup and the smoke test succeed on that machine. Keep machine-local paths and credentials out of shared notes.

| Revision | Machine and OS | Tool versions | Setup departures | Smoke and restart | Automated checks | Result |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | |

The [final QA audit](final-qa.md) documents AI-assisted browser sessions and a clean WSL setup on the original host. Both manual checks are still open.
