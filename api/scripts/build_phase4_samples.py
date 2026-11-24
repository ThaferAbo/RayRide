"""Generate a separate synthetic corpus. The original benchmark stays unchanged."""

from pathlib import Path

from PIL import ImageDraw, ImageFilter
from reportlab.pdfgen.canvas import Canvas

from .build_ticket_samples import raster_ticket

OUTPUT = Path(__file__).resolve().parents[2] / "samples" / "phase4"


def _pdf(filename: str, heading: str, rows: tuple[str, ...]) -> None:
    canvas = Canvas(str(OUTPUT / filename), pagesize=(648, 420), invariant=1)
    canvas.setTitle(heading)
    canvas.setAuthor("RayRide CSE491 Group 4")
    canvas.setFont("Helvetica-Bold", 21)
    canvas.drawString(42, 370, heading)
    canvas.setFont("Helvetica", 11)
    canvas.drawString(42, 345, "SYNTHETIC ITINERARY FOR RAYRIDE TESTS")
    canvas.line(42, 330, 606, 330)
    canvas.setFont("Courier", 12)
    for index, row in enumerate(rows):
        canvas.drawString(42, 298 - 32 * index, row)
    canvas.save()


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    _pdf(
        "terminal-layout.pdf",
        "Terminal itinerary",
        (
            "Flight number: ZZ 471",
            "Departure airport: VIE | Arrival airport: MUC Terminal 2",
            "Departure date: 27 Feb 2027 | Arrival date: 28 Feb 2027",
            "Departure time: 19:55 | Arrival time: 9:25 PM",
        ),
    )
    _pdf(
        "parallel-columns.pdf",
        "Two-column boarding sheet",
        (
            "Flight: ZZ 631",
            "DEPARTURE               | ARRIVAL",
            "Airport: BER            | --",
            "Date: 2027-06-15        | --",
            "Time: 07:05             | --",
        ),
    )
    _pdf(
        "clock-qualifiers.pdf",
        "Dates and clocks on an itinerary",
        (
            "Flight: ZZ 992",
            "Arrival airport: LYS",
            "Arrival date: 03/04/2027",
            "Arrival time: 20:10 UTC+03:00",
        ),
    )
    _pdf(
        "codeshare.pdf",
        "Two flight identifiers",
        (
            "Flight: ZZ 520 / XX 809",
            "Arrival airport: EDI",
            "Arrival date: 2027-06-14",
            "Arrival time: 09:35",
        ),
    )

    dark = raster_ticket(
        (
            "FLIGHT",
            "ZZ 712",
            "Arrival",
            "Airport: BCN",
            "Date: 2027-05-13",
            "Time: 8:25 PM",
        ),
        paper=82,
        ink=236,
    )
    # raster_ticket's line decoration is built for light paper. Keep it visible on dark paper.
    ImageDraw.Draw(dark).line((82, 235, 1368, 235), fill=135, width=3)
    dark.save(OUTPUT / "dark-board.png", optimize=True)

    slanted = raster_ticket(
        (
            "Flight: ZZ 853",
            "Departure airport: NCE",
            "Arrival airport: BRS",
            "Arrival date: 2027-06-05",
            "Arrival time: 06:45",
        ),
        paper=202,
        ink=118,
    )
    slanted = slanted.resize((755, 534)).rotate(3, fillcolor=202)
    slanted.filter(ImageFilter.GaussianBlur(0.45)).save(
        OUTPUT / "slanted-receipt.jpeg", quality=49
    )

    cropped = raster_ticket(
        (
            "Flight: ZZ 428",
            "Arrival date: 2027-06-18",
            "Passenger: FICTIONAL TEST PERSON",
            "Arrival airport: OSL",
            "Arrival time: 22:26",
        )
    ).crop((0, 0, 1450, 477))
    cropped.save(OUTPUT / "cropped-ticket.png", optimize=True)


if __name__ == "__main__":
    main()
