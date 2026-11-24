"""Score the checked-in synthetic corpus against the real endpoint before correction."""

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from tempfile import TemporaryDirectory

from fastapi.testclient import TestClient

from app.main import create_app
from app.settings import Settings

SAMPLES = Path(__file__).resolve().parents[2] / "samples"
MEDIA_TYPES = {".pdf": "application/pdf", ".png": "image/png", ".jpeg": "image/jpeg"}
CORPORA = {
    "original": SAMPLES,
    "phase4": SAMPLES / "phase4",
    "final-qa": SAMPLES / "final-qa",
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--corpus", choices=CORPORA, default="original")
    parser.add_argument(
        "--output", type=Path, help="Write machine-readable evidence for this run"
    )
    args = parser.parse_args()
    corpus = CORPORA[args.corpus]
    labels = json.loads((corpus / "expected.json").read_text(encoding="utf-8"))
    scores = defaultdict(Counter)
    fixtures = []
    with TemporaryDirectory() as temporary:
        settings = Settings(database_path=Path(temporary) / "evaluation.sqlite3")
        with TestClient(create_app(settings)) as client:
            for filename, expected in labels.items():
                path = corpus / filename
                with path.open("rb") as ticket:
                    response = client.post(
                        "/api/v1/tickets/extract",
                        files={
                            "ticket": (filename, ticket, MEDIA_TYPES[path.suffix]),
                        },
                    )
                response.raise_for_status()
                result = response.json()
                counts = Counter()
                for field, expected_value in expected["values"].items():
                    candidate = result[field]
                    status = candidate["status"]
                    if expected_value is None:
                        counts["unlabeled"] += 1
                        if status == "extracted":
                            counts["unlabeled_extracted"] += 1
                    elif status == "extracted":
                        counts[
                            "correct"
                            if candidate["value"] == expected_value
                            else "wrong"
                        ] += 1
                    else:
                        counts[status] += 1
                scores["overall"].update(counts)
                scores[result["method"]].update(counts)
                fixtures.append(
                    {
                        "fixture": filename,
                        "method": result["method"],
                        "expected": expected["values"],
                        "observed": {
                            field: result[field] for field in expected["values"]
                        },
                        "counts": dict(counts),
                        "fully_labeled": all(
                            value is not None for value in expected["values"].values()
                        ),
                        "fully_extracted": counts["correct"] == len(expected["values"]),
                    }
                )
                print(f"{filename:23} {result['method']:11} {summary(counts)}")

    print("\nAggregate by observed method")
    for method, counts in scores.items():
        print(f"{method:23} {summary(counts)}")
    fully_labeled = sum(fixture["fully_labeled"] for fixture in fixtures)
    fully_extracted = sum(fixture["fully_extracted"] for fixture in fixtures)
    print(
        f"\nAll four fields extracted correctly: {fully_extracted}/{fully_labeled} fully labeled tickets"
    )
    if args.output:
        evidence = {
            "corpus": args.corpus,
            "scores_by_method": {
                method: dict(counts) for method, counts in scores.items()
            },
            "fully_labeled_tickets": fully_labeled,
            "fully_extracted_tickets": fully_extracted,
            "fixtures": fixtures,
        }
        args.output.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")


def summary(counts: Counter) -> str:
    known = sum(
        counts[status] for status in ("correct", "wrong", "missing", "uncertain")
    )
    percentage = f" ({counts['correct'] / known:.1%})" if known else ""
    return (
        f"correct {counts['correct']}/{known}{percentage}, wrong {counts['wrong']}, "
        f"missing {counts['missing']}, uncertain {counts['uncertain']}, "
        f"extracted on unlabeled {counts['unlabeled_extracted']}/{counts['unlabeled']}"
    )


if __name__ == "__main__":
    main()
