import argparse
import json

from .main import app
from .settings import API_DIR


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Export the live and planned RayRide API contract."
    )
    parser.add_argument(
        "--check", action="store_true", help="Check the checked-in contract for drift."
    )
    args = parser.parse_args()
    output = API_DIR / "openapi.json"
    contract = json.dumps(app.openapi(), indent=2, sort_keys=True) + "\n"
    if args.check:
        if not output.is_file() or output.read_text(encoding="utf-8") != contract:
            parser.exit(
                1,
                "OpenAPI is out of date. Run uv run --locked python -m app.export_openapi.\n",
            )
    else:
        output.write_text(contract, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
