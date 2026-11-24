# Synthetic flight tickets

RayRide CSE491 Group 4 created these fixtures for local testing. They contain fictional flight details and no passenger data, receipts, real tickets, or legacy assets. The PDF and raster renderers use built-in fonts. Recreate the files from `api/` with `uv run --locked python -m scripts.build_ticket_samples`.

[`expected.json`](expected.json) was transcribed from the intended examples separately from the extraction code. The generator and the tests use different inputs for artwork and labels. The text and scanned PDFs depict the same flight so their paths can be compared directly. The ambiguous PDF has two candidate legs, including one date shared by both. A `null` field has no single annotated value. The degraded PNG still has source labels for all four fields so an unreadable result counts as a miss.

Run `uv run --locked python -m scripts.evaluate_tickets` from `api/` to measure field accuracy before any manual correction.

## Phase 4 expansion

The seven files in `phase4/` exercise two-column labels, an explicit terminal, codeshares, date and clock ambiguity, a dark image, a tilted low-contrast JPEG, and a cropped ticket. All flight details and the cropped ticket's passenger marker are fictional. The expansion's [independently recorded labels](phase4/expected.json) were written from the intended source data before running the extractor. The generator does not read the labels. A `null` has no single gold value, and `review` lists fields that require review or manual entry.

From `api/`, reproduce the expansion with `uv run --locked python -m scripts.build_phase4_samples` and score it with `uv run --locked python -m scripts.evaluate_tickets --corpus phase4`. The default `--corpus original` still uses the eight original files and their original labels. [Observed results](../docs/phase4-verification.md#extraction-before-correction)
