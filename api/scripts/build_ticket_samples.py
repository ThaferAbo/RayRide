"""Build the fictional extraction fixtures without reading the expected labels."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen.canvas import Canvas

SAMPLES = Path(__file__).resolve().parents[2] / "samples"
PAGE = (612, 432)
REFERENCE_LINES = (
    "Flight number: ZZ 731",
    "Departure airport: Istanbul (IST)",
    "Departure date: 02 Dec 2026",
    "Departure time: 11:45 AM",
    "Arrival airport: Antalya (AYT)",
    "Arrival date: 03 Dec 2026",
    "Arrival time: 2:10 PM",
)


def text_page(canvas: Canvas, lines: tuple[str, ...]) -> None:
    canvas.setFont("Helvetica-Bold", 23)
    canvas.drawString(42, 390, "Fictional flight ticket")
    canvas.setFont("Helvetica", 10)
    canvas.drawString(42, 369, "RAYRIDE CSE491 TEST FIXTURE")
    canvas.line(42, 356, 570, 356)
    canvas.setFont("Helvetica", 16)
    for index, line in enumerate(lines):
        canvas.drawString(42, 326 - index * 25, line)
    canvas.showPage()


def raster_ticket(
    lines: tuple[str, ...], *, paper: int = 252, ink: int = 20
) -> Image.Image:
    image = Image.new("L", (1450, 1024), paper)
    draw = ImageDraw.Draw(image)
    draw.text(
        (82, 80), "Fictional flight ticket", font=ImageFont.load_default(67), fill=ink
    )
    draw.text(
        (82, 172),
        "RAYRIDE CSE491 TEST FIXTURE",
        font=ImageFont.load_default(31),
        fill=ink,
    )
    draw.line((82, 235, 1368, 235), fill=paper - 80, width=3)
    body_font = ImageFont.load_default(48)
    for index, line in enumerate(lines):
        draw.text((82, 290 + index * 63), line, font=body_font, fill=ink)
    return image


def raster_page(canvas: Canvas, lines: tuple[str, ...]) -> None:
    canvas.drawImage(
        ImageReader(raster_ticket(lines)), 0, 0, width=PAGE[0], height=PAGE[1]
    )
    canvas.showPage()


def pdf(name: str) -> Canvas:
    canvas = Canvas(str(SAMPLES / name), pagesize=PAGE, invariant=1, pageCompression=1)
    canvas.setTitle("Fictional RayRide test ticket")
    canvas.setAuthor("RayRide CSE491 Group 4")
    return canvas


def main() -> None:
    SAMPLES.mkdir(exist_ok=True)
    direct = pdf("text-ticket.pdf")
    text_page(direct, REFERENCE_LINES)
    direct.save()

    scan = pdf("scanned-ticket.pdf")
    raster_page(scan, REFERENCE_LINES)
    scan.save()

    raster_ticket(
        (
            "Flight: QX 482",
            "Departure",
            "Airport: CDG",
            "Time: 09:15",
            "Arrival",
            "Airport: FRA",
            "Date: 2026-12-08",
            "Time: 10:40",
        )
    ).save(SAMPLES / "image-ticket.png", optimize=True)

    raster_ticket(
        (
            "Flight: 6E 318",
            "From: LGW",
            "Arrives: Amsterdam (AMS)",
            "Arrival date: December 9, 2026",
            "Arrival time: 08:05",
        ),
        paper=237,
        ink=50,
    ).save(SAMPLES / "image-ticket.jpeg", quality=82)

    ambiguous = pdf("ambiguous-ticket.pdf")
    text_page(
        ambiguous,
        (
            "Flight: ZZ 120",
            "Arrival: CDG 2026-12-10 10:15",
            "Flight: ZZ 305",
            "Arrival: FRA 2026-12-10 14:50",
        ),
    )
    ambiguous.save()

    incomplete = pdf("missing-fields.pdf")
    text_page(
        incomplete,
        (
            "Flight: ZZ 154",
            "Departure airport: IST",
            "Departure date: 2026-12-11",
            "Departure time: 14:19",
            "Arrival airport: AYT",
        ),
    )
    incomplete.save()

    mixed = pdf("mixed-ticket.pdf")
    text_page(mixed, ("Flight: WN 210", "Arrival airport: MAD"))
    raster_page(mixed, ("Arrival date: 14 Dec 2026", "Arrival time: 6:45 PM"))
    mixed.save()

    unreadable = raster_ticket(
        (
            "Flight: ZZ 969",
            "Arrival airport: FCO",
            "Arrival date: 2026-12-19",
            "Arrival time: 21:20",
        )
    )
    unreadable = unreadable.resize((30, 19), Image.Resampling.BOX).filter(
        ImageFilter.GaussianBlur(1.2)
    )
    unreadable = (
        ImageEnhance.Contrast(unreadable)
        .enhance(0.12)
        .resize((1450, 1024), Image.Resampling.BICUBIC)
    )
    unreadable.save(SAMPLES / "unreadable-ticket.png", optimize=True)


if __name__ == "__main__":
    main()
