# Attribution and contribution record

This record covers the published Phase 6 prototype at `9749be2`. Versions come from the npm and uv lockfiles. Licenses below were checked against installed package metadata or upstream notices. The dependency licenses apply to their components. The repository has no top-level license grant for RayRide's own code. [Release revision](https://github.com/ThaferAbo/RayRide/commit/9749be2685a56df789f393071d7ec1ead93f6091) · [npm lockfile](../frontend/package-lock.json) · [uv lockfile](../api/uv.lock)

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
| Pillow 13.0.0 | MIT-CMU. Phase 6 upgraded the historical 12.3.0 dependency following the runtime advisory audit. Keep the notices applicable to the selected build. [Pillow license](https://github.com/python-pillow/Pillow/blob/13.0.0/LICENSE) · [QA audit](final-qa.md#findings-and-fixes) |
| opencv-python-headless 4.14.0.94 | The packaging scripts are MIT, OpenCV is Apache-2.0, and the wheel includes separate component notices, including LGPL-2.1 for FFmpeg. [OpenCV wheel licensing](https://github.com/opencv/opencv-python#licensing) |
| pypdfium2 5.15.2 and bundled PDFium | The binding offers Apache-2.0 or BSD-3-Clause. PDFium uses a BSD-style license. Keep the wheel's PDFium and third-party notices for binary redistribution. [pypdfium2 licensing](https://pypdfium2.readthedocs.io/en/stable/readme.html#licensing) |
| Tesseract 5 and English trained data | Apache-2.0 for Tesseract and upstream tessdata. The system install has platform-specific notices. Phase 6 hosted CI used 5.3.4, the WSL audit used 5.5.0, and the historical Windows rehearsal used UB Mannheim 5.4.0.20240606. [Tesseract](https://github.com/tesseract-ocr/tesseract/blob/main/LICENSE) · [tessdata](https://github.com/tesseract-ocr/tessdata/blob/main/LICENSE) · [Windows release](https://github.com/UB-Mannheim/tesseract/releases/tag/v5.4.0.20240606) |

The npm development tools are MIT for ESLint, `@eslint/js`, the Next.js and React Hooks ESLint plugins, typescript-eslint, PostCSS, openapi-typescript, and the Node and React type packages. TypeScript 5.9.3 and Playwright 1.65.1 use Apache-2.0. The axe Playwright integration 4.14.0 uses MPL-2.0. The Python development packages are MIT for pytest and Ruff, BSD-3-Clause for httpx2 and ReportLab. Chromium is installed separately for tests and carries its own third-party notices. [Web development manifest](../frontend/package.json) · [Python development manifest](../api/pyproject.toml) · [Playwright](https://github.com/microsoft/playwright/blob/main/LICENSE) · [axe-core](https://github.com/dequelabs/axe-core/blob/develop/LICENSE)

These are source handoff credits. An installer, prebuilt web bundle, or container would need the notices for the exact artifacts it ships, including platform-specific wheels and browser binaries where applicable. Use the licenses and third-party notices shipped with those versions.

## Assets and data

| Material | Provenance |
| --- | --- |
| [Coastline hero](../frontend/public/rayride-coast.webp) | Generated for RayRide with OpenAI ImageGen. The prompt is in the implementation log. No stock-photo source or legacy assets were used for this image. [Image prompt](implementation-log.md#hero-artwork-prompt) |
| Manrope typeface | The Manrope Project Authors, copyright 2019. Served from Fontsource `@fontsource-variable/manrope` 5.3.0 under SIL OFL 1.1. [Fontsource](https://fontsource.org/fonts/manrope) · [OFL notice](https://github.com/google/fonts/blob/main/ofl/manrope/OFL.txt) |
| Phosphor icons | Phosphor Icons, copyright 2020. The app uses `@phosphor-icons/react` 2.1.10 under MIT. [MIT notice](https://github.com/phosphor-icons/react/blob/master/LICENSE) |
| [Ticket fixtures](../samples/README.md) | Project-generated fictional documents. The original benchmark, Phase 4 expansion, and Phase 6 QA probes have independent labels recorded separately from the extraction code. No external ticket dataset or real passenger files were used. |
| Report screenshots | Playwright captures of the running prototype with synthetic fixture or manual values. [Phase 4 screenshots](phase4-verification.md#screenshots-for-the-report) · [Phase 6 screenshots](final-qa.md#screenshots-from-the-running-app) |

## AI assistance

OpenAI Codex assisted with parser and usability changes, automated tests, evidence capture, the Phase 5 demo rehearsal and handoff, and this release documentation. For Phase 6, Codex performed the isolated setup and exploratory browser sessions, assisted with synthetic fixtures and independent labels, and implemented the fixes and regression checks documented in the audit. The exploratory sessions were AI-assisted. Human pilot usability is still open. ImageGen produced the app's coastline artwork. The runtime uses local Tesseract and deterministic parsing with no generative model in the reservation flow. [Implementation record](implementation-log.md) · [Phase 6 QA audit](final-qa.md)

## Team contributions

The plan assigns Efkan the frontend and booking flow, Thafer ticket extraction and evaluation, and Alperen the API and persistence. It assigns integration, reporting and the presentation to the group. Those are planned responsibilities. The CSE491 interval after `2a8246e` through `9749be2` contains seven commits attributed on GitHub to the account `Thaelith`. Individual authorship and review still need separate team confirmation.

| Git evidence | Observed changes |
| --- | --- |
| [`bf2d15a`](https://github.com/ThaferAbo/RayRide/commit/bf2d15a) and [`a0a1d82`](https://github.com/ThaferAbo/RayRide/commit/a0a1d82) | Repository hygiene, app and API foundations, SQLite model, setup and initial checks. |
| [`22fe779`](https://github.com/ThaferAbo/RayRide/commit/22fe779) | Ticket intake, OCR and parsing, original fixtures, and extraction tests. |
| [`be528b8`](https://github.com/ThaferAbo/RayRide/commit/be528b8) | Review and confirmation UI, reservation API and browser coverage. |
| [`005aef6`](https://github.com/ThaferAbo/RayRide/commit/005aef6) | Expanded fixtures, parser and usability regressions, privacy and persistence checks, and Phase 4 evidence. |
| [`23c4fb1`](https://github.com/ThaferAbo/RayRide/commit/23c4fb1) | Phase 5 handoff, API and architecture documentation, and presentation materials. |
| [`9749be2`](https://github.com/ThaferAbo/RayRide/commit/9749be2) | Phase 6 audit and fixtures, replacement-draft and ETA fixes, regression tests, and the Pillow upgrade. |

**Individual contribution confirmation is open.** For the submitted report, each member should confirm the specific artifact or activity they completed with a commit, review, meeting note, or test record.
