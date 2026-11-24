# Attribution and contribution record

This record covers the CSE491 prototype at `005aef6`. Versions come from [the npm lockfile](../frontend/package-lock.json) and [the uv lockfile](../api/uv.lock). Licenses below were checked against installed package metadata or upstream notices. The dependency licenses apply to their components. The checked-out repository has no top-level license grant for RayRide's own code.

## Runtime dependencies

| Component | License and notices |
| --- | --- |
| Next.js 16.4.6, React and React DOM 19.3.1 | MIT. [Next.js](https://github.com/vercel/next.js/blob/canary/license.md) · [React](https://github.com/facebook/react/blob/main/LICENSE) |
| Tailwind CSS and its PostCSS integration 4.3.5 | MIT. These build-time tools produce the app's CSS. [Tailwind CSS](https://github.com/tailwindlabs/tailwindcss/blob/main/LICENSE) |
| FastAPI 0.165.0 | MIT. [FastAPI](https://github.com/fastapi/fastapi/blob/master/LICENSE) |
| Pydantic 2.14.4 and pydantic-settings 2.16.3 | MIT. [Pydantic](https://github.com/pydantic/pydantic/blob/main/LICENSE) · [Pydantic Settings](https://github.com/pydantic/pydantic-settings/blob/main/LICENSE) |
| Uvicorn 0.54.0 and python-multipart 0.0.34 | BSD-3-Clause and Apache-2.0, respectively. [Uvicorn](https://github.com/encode/uvicorn/blob/main/LICENSE.md) · [python-multipart](https://github.com/Kludex/python-multipart/blob/main/LICENSE.txt) |
| SQLAlchemy 2.0.58 and SQLite | MIT and public domain, respectively. [SQLAlchemy](https://github.com/sqlalchemy/sqlalchemy/blob/main/LICENSE) · [SQLite](https://sqlite.org/copyright.html) |
| NumPy 2.4.6 | BSD-3-Clause for NumPy. The wheel's combined metadata also lists 0BSD, MIT, Zlib and CC0-1.0. Refer to the native wheel's included notices when packaging. [NumPy](https://github.com/numpy/numpy/blob/main/LICENSE.txt) |
| Pillow 12.3.0 | MIT-CMU. Keep the license and the notices applicable to the selected build. [Pillow](https://github.com/python-pillow/Pillow/blob/main/LICENSE) |
| opencv-python-headless 4.14.0.94 | The packaging scripts are MIT, OpenCV is Apache-2.0, and the wheel includes separate component notices, including LGPL-2.1 for FFmpeg. [OpenCV wheel licensing](https://github.com/opencv/opencv-python#licensing) |
| pypdfium2 5.15.2 and bundled PDFium | The binding offers Apache-2.0 or BSD-3-Clause. PDFium uses a BSD-style license. Keep the wheel's PDFium and third-party notices for binary redistribution. [pypdfium2 licensing](https://pypdfium2.readthedocs.io/en/stable/readme.html#licensing) |
| Tesseract 5 and English trained data | Apache-2.0 for Tesseract and upstream tessdata. The system install has platform-specific notices. The Windows rehearsal used the UB Mannheim build. [Tesseract](https://github.com/tesseract-ocr/tesseract/blob/main/LICENSE) · [tessdata](https://github.com/tesseract-ocr/tessdata/blob/main/LICENSE) · [Windows release](https://github.com/UB-Mannheim/tesseract/releases/tag/v5.4.0.20240606) |

The npm development tools are MIT for ESLint, `@eslint/js`, the Next.js and React Hooks ESLint plugins, typescript-eslint, PostCSS, openapi-typescript, and the Node and React type packages. TypeScript and Playwright use Apache-2.0. The axe Playwright integration uses MPL-2.0. The Python development packages are MIT for pytest and Ruff, BSD-3-Clause for httpx2 and ReportLab. Chromium is installed separately for tests and carries its own third-party notices. [Web development manifest](../frontend/package.json) · [Python development manifest](../api/pyproject.toml) · [Playwright](https://github.com/microsoft/playwright/blob/main/LICENSE) · [axe-core](https://github.com/dequelabs/axe-core/blob/develop/LICENSE)

These are source handoff credits. An installer, prebuilt web bundle, or container would need the notices for the exact artifacts it ships, including platform-specific wheels and browser binaries where applicable. Use the licenses and third-party notices shipped with those versions.

## Assets and data

| Material | Provenance |
| --- | --- |
| [Coastline hero](../frontend/public/rayride-coast.webp) | Generated for RayRide with OpenAI ImageGen. The prompt is in the implementation log. No stock-photo source or legacy assets were used for this image. [Image prompt](implementation-log.md#hero-artwork-prompt) |
| Manrope typeface | The Manrope Project Authors, copyright 2019. Served from Fontsource `@fontsource-variable/manrope` 5.3.0 under SIL OFL 1.1. [Fontsource](https://fontsource.org/fonts/manrope) · [OFL notice](https://github.com/google/fonts/blob/main/ofl/manrope/OFL.txt) |
| Phosphor icons | Phosphor Icons, copyright 2020. The app uses `@phosphor-icons/react` 2.1.10 under MIT. [MIT notice](https://github.com/phosphor-icons/react/blob/master/LICENSE) |
| [Original and expanded ticket fixtures](../samples/README.md) | Project-generated fictional documents. The two label sets are recorded separately from the extraction code. No external ticket dataset or real passenger files were used. |
| [Report screenshots](phase4-verification.md#screenshots-for-the-report) | Playwright captures of the running prototype with synthetic fixture or manual values. |

## AI assistance

OpenAI Codex assisted with Phase 4 parser and usability changes, automated tests, evidence capture and documentation. Codex also audited the published test evidence, rehearsed the demo and drafted the Phase 5 handoff. ImageGen produced the app's coastline artwork. The runtime uses local Tesseract and deterministic parsing. No generative model is called during a reservation. The team should review this disclosure and add any other AI assistance it can verify before submitting. [Phase 4 and 5 records](implementation-log.md#phase-4-acceptance-testing-reliability-and-usability)

## Team contributions

The plan assigns Efkan the frontend and booking flow, Thafer ticket extraction and evaluation, and Alperen the API and persistence. It assigns integration, reporting and the presentation to the group. Those are planned responsibilities. The Git evidence for the CSE491 interval after `2a8246e` through `005aef6` credits five commits to the GitHub account `Thaelith`. That record alone does not establish which named teammate wrote or reviewed an individual change.

| Git evidence | Observed changes |
| --- | --- |
| [`bf2d15a`](https://github.com/ThaferAbo/RayRide/commit/bf2d15a) and [`a0a1d82`](https://github.com/ThaferAbo/RayRide/commit/a0a1d82) | Repository hygiene, app and API foundations, SQLite model, setup and initial checks. |
| [`22fe779`](https://github.com/ThaferAbo/RayRide/commit/22fe779) | Ticket intake, OCR and parsing, original fixtures, and extraction tests. |
| [`be528b8`](https://github.com/ThaferAbo/RayRide/commit/be528b8) | Review and confirmation UI, reservation API and browser coverage. |
| [`005aef6`](https://github.com/ThaferAbo/RayRide/commit/005aef6) | Expanded fixtures, parser and usability regressions, privacy and persistence checks, and Phase 4 evidence. |

Individual CSE491 contributions beyond that Git record are **awaiting team confirmation**. For the submitted report, each member should confirm the specific artifact or activity they completed, with a commit, review, meeting note, or test record. Leave unsupported merit and percentages blank. Phase 5 handoff edits were prepared with Codex assistance and are currently working-tree changes.
