# CSE491 presentation and live demo

**Group 4 · RayRide · Fall 2026–2027**

## Presentation outline

Use about seven minutes before questions, or adjust to the allotted slot.

| Time | Slide or live view | What to show |
| --- | --- | --- |
| 0:00–0:45 | Goal and scope | A traveler reviews flight details before saving a simulated airport transfer. Show the [upload screen](evidence/phase4/report-01-upload.png). |
| 0:45–1:45 | Architecture | Trace the browser to Next.js and FastAPI. Show where PDF text, local OCR and SQLite fit. Explain the difference between arrival local time and UTC creation time. [Diagrams](architecture.md) |
| 1:45–3:30 | Live scanned-ticket flow | Extract four fields, demonstrate the review requirement, save, and retrieve the same reservation by reference. |
| 3:30–4:45 | Live unreadable-ticket flow | Show the missing-field warning and save through manual entry using the fictional details below. |
| 4:45–6:10 | Results and limitations | Show the five successful workflows and both OCR denominators. Explain that human usability and a second development machine remain open. [Acceptance evidence](phase4-verification.md) |
| 6:10–7:00 | Next semester and credits | Discuss improving ambiguous extraction, access control, and staged integration. Credit the assets and disclose AI assistance. Use only contributions that can be evidenced. [Roadmap](cse492-roadmap.md) · [Credits](attribution.md) |

Before presenting, each speaker should be able to explain why an uncertain value needs review, what SQLite stores, and what happens if a save reply is lost. For questions about evidence, show the field-level benchmark files or the linked CI logs.

## Prepare the offline run

1. Use app revision `005aef6f59fd570f3b83ff35e83664233973fd7a`. Record `git rev-parse HEAD` on the presentation machine. If using a later documentation revision, verify that `git diff 005aef6 -- frontend/ api/ samples/` is empty. Use [the prerequisite and Tesseract instructions](../README.md#prerequisites) and verify `eng` with `--list-langs`.
2. While online, run `uv sync --locked` in `api/` and `npm ci` and `npm run build` in `frontend/`. Ensure the browser is already installed. The rehearsal used the production build.
3. Choose an unused demo SQLite filename. From the repository root in PowerShell, start the API in terminal one.

   ```powershell
   cd api
   $env:RAYRIDE_DATABASE_PATH = 'data/rayride-final-demo.sqlite3'
   uv run --offline --locked uvicorn app.main:app --host 127.0.0.1 --port 8000
   ```

   On POSIX, replace the assignment with `export RAYRIDE_DATABASE_PATH=data/rayride-final-demo.sqlite3`.

4. From the repository root in terminal two, start the production web app. Use the default server-only API origin `http://127.0.0.1:8000`. Disable Next.js telemetry for the demo.

   ```powershell
   cd frontend
   $env:NEXT_TELEMETRY_DISABLED = '1'
   npm start
   ```

   On POSIX, replace the assignment with `export NEXT_TELEMETRY_DISABLED=1`.

5. Disconnect Internet access if the presentation setup allows it. Open [System status](http://127.0.0.1:3000/status) and confirm **Operational**. The live flow uses local assets and loopback services. Keep the two samples and the saved screenshots available locally.

## Live steps

### Normal path

1. On the [booking page](http://127.0.0.1:3000), use **Choose a file** to select `samples/scanned-ticket.pdf`. Click **Extract flight details**. Point out `ZZ731`, `AYT`, `2026-12-03`, and `14:10:00`, all marked **Extracted**.
2. Enter **Antalya city center**. Click **Create simulated reservation** once while the checkbox is unchecked. Show the validation message. Check the review box and save.
3. Show **Simulation only**, the saved details and the generated reference. Keep the actual reference shown in this run. Reload the page, then open **Find a reservation**, enter the same reference, and select **Look up reservation**.

### OCR failure and recovery

1. Select **Create another reservation**, choose `samples/unreadable-ticket.png`, and click **Extract flight details**. Show the warning and four **Missing** fields.
2. Enter `ZZ969`, `FCO`, `2026-12-19`, `21:20`, and **Fictional Riverside Lodge**. Check review and save. The confirmation should display `21:20:00` local time.
3. If time permits, show `samples/ambiguous-ticket.pdf` to explain why a field can be uncertain without a reliable single value.

## If the live demo is interrupted

If the status page cannot reach the API, check the API terminal, port and database path. If OCR is missing, show the manual path and use `samples/text-ticket.pdf` for the embedded-text path. If a save reply is lost, retry with the same values in the open form. If the app cannot be restarted in time, use the existing captures and label them as prior evidence. [Upload](evidence/phase4/report-01-upload.png) · [Review](evidence/phase4/report-02-review.png) · [Representative saved confirmation](evidence/phase4/report-03-confirmation.png) · [Manual fallback](evidence/phase4/report-04-manual-fallback.png)

## Rehearsal record

Both paths passed on 24 November 2026 at application revision `005aef6` on Windows 11 Pro. The production Next.js build used Node 24.14.0 and npm 11.9.0. FastAPI ran under Python 3.11.15 via uv 0.11.24 with Tesseract 5.4.0.20240606 and `eng`. It used a fresh, isolated SQLite file. The API started with `uv --offline` and Chromium was configured to block external HTTP and HTTPS before opening the app on port 3000.

| Check | Observed |
| --- | --- |
| Services | The status page reported **Operational**. |
| Scanned PDF | Four suggestions matched. The unchecked review blocked saving. After review, the confirmation saved and reloaded, and reference lookup returned the same trip. |
| Unreadable PNG at 390 px | Four fields showed **Missing**. Manual entry saved a second simulated reservation with `ZZ969` and `21:20:00` at FCO. |

This rehearsal verifies the live steps on one machine. The team will present the live demo and collect the open manual evidence. [Acceptance checks](phase4-verification.md) · [Manual protocols](phase4-manual-protocols.md)
