# Synthetic flight tickets

RayRide CSE491 Group 4 created these fixtures for local testing. They contain fictional flight details and no passenger data, receipts, real tickets, or legacy assets. The PDF and raster renderers use built-in fonts. Recreate the files from `api/` with `uv run --locked python -m scripts.build_ticket_samples`.

[`expected.json`](expected.json) was transcribed from the intended examples separately from the extraction code. The generator and the tests use different inputs for artwork and labels. The text and scanned PDFs depict the same flight so their paths can be compared directly. The ambiguous PDF has two candidate legs, including one date shared by both. A `null` field has no single annotated value. The degraded PNG still has source labels for all four fields so an unreadable result counts as a miss.

Run `uv run --locked python -m scripts.evaluate_tickets` from `api/` to measure field accuracy before any manual correction.
