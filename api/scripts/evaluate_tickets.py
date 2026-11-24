"""Score the checked-in synthetic corpus against the real endpoint before correction."""

import json
from collections import Counter, defaultdict
from pathlib import Path
from tempfile import TemporaryDirectory

from fastapi.testclient import TestClient

from app.main import create_app
from app.settings import Settings

SAMPLES = Path(__file__).resolve().parents[2] / "samples"
MEDIA_TYPES = {".pdf": "application/pdf", ".png": "image/png", ".jpeg": "image/jpeg"}


def main() -> None:
    labels = json.loads((SAMPLES / "expected.json").read_text(encoding="utf-8"))
    scores = defaultdict(Counter)
    with TemporaryDirectory() as temporary:
        settings = Settings(database_path=Path(temporary) / "evaluation.sqlite3")
        with TestClient(create_app(settings)) as client:
            for filename, expected in labels.items():
                path = SAMPLES / filename
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
                print(f"{filename:23} {result['method']:11} {summary(counts)}")

    print("\nAggregate by observed method")
    for method, counts in scores.items():
        print(f"{method:23} {summary(counts)}")


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
