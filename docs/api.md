# RayRide CSE491 REST API

The local backend listens at `http://127.0.0.1:8000`. The browser uses Next.js on port 3000, whose ticket, reservation and lookup handlers forward to the loopback API. The examples below call FastAPI directly. The checked-in OpenAPI export describes version `0.3.0` and is the contract source for generated frontend types. [OpenAPI JSON](../api/openapi.json) · [Generated types](../frontend/lib/api.types.ts)

## Routes

| Route | Request | Result |
| --- | --- | --- |
| `GET /health` | No body | `200` with `{"status":"ok","database":"ready"}`, or `503` if the SQLite query fails. Health does not test Tesseract. |
| `POST /api/v1/tickets/extract` | One multipart `ticket` file, PDF, PNG or JPEG | `200 ExtractionResult` with candidate fields and warnings. Validation uses `400`, `413`, `415` and `422`. |
| `POST /api/v1/reservations` | Reviewed JSON up to 8 KiB. Optional `Idempotency-Key`, a version 4 UUID. | `201 ReservationResponse` with `Location` on creation. An identical keyed replay returns `200` and the same reference. Errors include `409`, `413`, `415`, `422` and `503`. |
| `GET /api/v1/reservations/{reference}` | Reference of the form `RR-` followed by 12 uppercase letters or digits | `200 ReservationResponse`, `404` for an unknown reference, `422` for invalid syntax, or `503` on a database error. |

### Ticket extraction

From the repository root, with the API running, call this command. In PowerShell use `curl.exe` for the executable.

```sh
curl --fail-with-body --form 'ticket=@samples/scanned-ticket.pdf;type=application/pdf' http://127.0.0.1:8000/api/v1/tickets/extract
```

The file must end in `.pdf`, `.png`, `.jpg` or `.jpeg`, with matching media type and bytes. The file limit is 10 MiB, with another 16 KiB allowed for multipart framing. PDFs allow up to five pages, 2,400 points on each page dimension, and 20,000 embedded text characters per page. The decoded image limit is 12 million pixels. The configurable OCR stage budget is eight seconds by default.

The method is `pdf_text`, `ocr`, `mixed`, or `unavailable`. Each of `flight_number`, `arrival_airport`, `arrival_date` and `arrival_local_time` has a `status` and `value`. An `extracted` field contains a candidate. An `uncertain` field may contain a tentative value or `null`. A `missing` field has `null`. The traveler must review all suggestions. A valid ticket with little usable text, missing OCR, or an OCR timeout can return `200` with warnings and allow manual entry. A malformed upload, unsupported type or corrupt document returns a typed error. [Upload code](../api/app/ticket_upload.py) · [Extraction code](../api/app/extraction.py)

### Create and look up a reservation

Use the following request body with `Content-Type: application/json`.

```json
{
  "flight_number": "ZZ731",
  "arrival_airport": "AYT",
  "arrival_date": "2026-12-03",
  "arrival_local_time": "14:10",
  "destination": "Antalya city center",
  "reviewed": true
}
```

The flight number must match the uppercase airline/flight pattern in OpenAPI. The airport is exactly three uppercase letters. Send a real calendar date in `YYYY-MM-DD` form and a 24-hour time in `HH:MM`, optionally with seconds and up to six fractional digits. Arrival is a local clock time with no offset. The destination is trimmed and must contain 1 to 200 characters. The server requires the Boolean `true` for `reviewed` and rejects extra fields.

The response repeats the five trip fields, normalizes the time, and includes `reference`, `status: "simulated"`, and a UTC `created_at` timestamp. Use the returned reference in the lookup route. If you supply a version 4 UUID in `Idempotency-Key`, repeat the same key and details after a lost response. A keyed replay with different normalized details returns `409`. Without a key, repeated accepted requests may create separate reservations. [Reservation handler](../api/app/reservations.py)

## Errors and contract maintenance

Error responses contain an object at `detail` with machine-readable `code` and human-readable `message`. Reservation validation can include a `fields` map. The browser-facing proxy also rejects cross-origin writes (`403`), incomplete uploads (`408`), and reports upstream unavailability or timeout (`503` or `504`). The proxy returns the upstream status and JSON with its own response headers. Read `reference` from the response body when calling the proxy. [Proxy code](../frontend/lib/local-api.ts)

After a contract change, run `uv run --locked python -m app.export_openapi` in `api/`, then `npm run contracts:generate` in `frontend/`. The [verification commands](../README.md#verification) check both generated files. With the API running, use [Swagger UI](http://127.0.0.1:8000/docs) when its assets are available, or [raw OpenAPI JSON](http://127.0.0.1:8000/openapi.json) locally.
