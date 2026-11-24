"""Create the separate synthetic image fixtures for the final QA audit."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SAMPLES = Path(__file__).resolve().parents[2] / "samples" / "final-qa"


def panel(*lines: str) -> Image.Image:
    image = Image.new("RGB", (1240, 186 + 73 * len(lines)), "#f7f8fa")
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 0, image.width, 100), fill="#18314a")
    draw.text(
        (55, 27),
        "SYNTHETIC FLIGHT RECORD",
        fill="#ffffff",
        font=ImageFont.load_default(size=38),
    )
    font = ImageFont.load_default(size=48)
    for index, line in enumerate(lines):
        draw.text((62, 140 + index * 73), line, fill="#131d2a", font=font)
    return image


def main() -> None:
    SAMPLES.mkdir(exist_ok=True)
    panel(
        "FLIGHT NO. ZZ613",
        "DEPARTURE AIRPORT OSL",
        "DEPARTURE DATE 2027-02-02",
        "DEPARTURE TIME 23:55",
        "ARRIVAL AIRPORT HEL",
        "ARRIVAL DATE 2027-02-03",
        "ARRIVAL TIME 01:10",
    ).save(SAMPLES / "overnight-panel.png")
    panel(
        "FLIGHT NUMBER ZZ815",
        "ARRIVAL AIRPORT LIS",
        "ARRIVAL DATE 2027-01-08",
        "ARRIVAL TIME 12:35",
    ).transpose(Image.Transpose.ROTATE_90).save(SAMPLES / "sideways-strip.png")
    low_resolution = panel(
        "FLIGHT ZZ842",
        "ARRIVAL AIRPORT NCE",
        "ARRIVAL DATE 2027-03-16",
        "ARRIVAL TIME 08:45",
    ).resize((345, 133), Image.Resampling.LANCZOS)
    low_resolution.filter(ImageFilter.GaussianBlur(0.7)).save(
        SAMPLES / "low-resolution.jpeg", quality=19
    )
    panel(
        "FLIGHT ZZ477",
        "ARRIVAL DATE 2027-02-03",
        "ARRIVAL ETA 18:20",
    ).save(SAMPLES / "eta-without-airport.png")
    panel(
        "FLIGHT ZZ524",
        "ARRIVAL AIRPORT ATH",
        "ARRIVAL DATE 2027-02-12",
        "ARRIVAL TIME UTC 18:20",
    ).save(SAMPLES / "utc-without-local-time.png")


if __name__ == "__main__":
    main()
