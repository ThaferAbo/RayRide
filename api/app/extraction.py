import csv
import math
import os
import subprocess
from contextlib import closing
from io import BytesIO, StringIO
from threading import Lock
from time import monotonic
from typing import Protocol

import cv2
import numpy as np
import pypdfium2 as pdfium
from numpy.typing import NDArray
from PIL import Image, ImageOps, UnidentifiedImageError

from .schemas import ExtractionResult, TicketMediaType
from .ticket_fields import TicketLine, parse_embedded_ticket, parse_ticket
from .ticket_upload import TicketError

MAX_PDF_PAGES = 5
MAX_IMAGE_PIXELS = 12_000_000
MAX_PDF_PAGE_POINTS = 2_400
MAX_TEXT_PER_PAGE = 20_000
MIN_WORD_CONFIDENCE = 65
_PDFIUM_LOCK = Lock()
_SIGNATURES: dict[TicketMediaType, bytes] = {
    "application/pdf": b"%PDF-",
    "image/png": b"\x89PNG\r\n\x1a\n",
    "image/jpeg": b"\xff\xd8\xff",
}

Pixels = NDArray[np.uint8]


class TicketExtractor(Protocol):
    """Accepts ticket bytes and returns editable suggestions without retaining the upload."""

    def extract(
        self, content: bytes, *, media_type: TicketMediaType
    ) -> ExtractionResult:
        """Extract candidate fields without retaining uploaded content."""
        ...


class LocalTicketExtractor:
    def __init__(self, *, executable: str, timeout_seconds: float) -> None:
        self.executable = executable
        self.timeout_seconds = timeout_seconds

    def extract(
        self, content: bytes, *, media_type: TicketMediaType
    ) -> ExtractionResult:
        if not content.startswith(_SIGNATURES[media_type]):
            raise TicketError(
                415, "The file bytes do not match the selected ticket format."
            )
        if media_type == "application/pdf":
            return self._extract_pdf(content)
        return self._read_ocr([_read_image(content, media_type)])

    def _extract_pdf(self, content: bytes) -> ExtractionResult:
        if not content.rstrip().endswith(b"%%EOF"):
            raise TicketError(
                422, "The PDF is incomplete or damaged. Try another copy."
            )

        embedded: list[list[TicketLine]] = []
        warnings: list[str] = []
        images: list[Pixels] = []
        try:
            # PDFium must only be called by one thread at a time, including unrelated documents.
            with _PDFIUM_LOCK, closing(pdfium.PdfDocument(content)) as document:
                page_count = len(document)
                if not page_count:
                    raise TicketError(422, "The PDF does not contain any pages.")
                if page_count > MAX_PDF_PAGES:
                    raise TicketError(413, "Upload a PDF with at most five pages.")

                sizes = []
                for index in range(page_count):
                    with closing(document[index]) as page:
                        width, height = page.get_size()
                        if not all(
                            math.isfinite(n) and 0 < n <= MAX_PDF_PAGE_POINTS
                            for n in (width, height)
                        ):
                            raise TicketError(
                                413,
                                "The PDF page dimensions exceed the supported limit.",
                            )
                        sizes.append((width, height))
                        try:
                            with closing(page.get_textpage()) as text_page:
                                count = text_page.count_chars()
                                if count > MAX_TEXT_PER_PAGE:
                                    raise TicketError(
                                        413,
                                        "A PDF page exceeds the 20,000-character text limit.",
                                    )
                                text = (
                                    text_page.get_text_range(errors="replace")
                                    if count
                                    else ""
                                )
                        except pdfium.PdfiumError:
                            text = ""
                        embedded.append(
                            [
                                TicketLine(line)
                                for line in text.splitlines()
                                if line.strip()
                            ]
                        )

                direct = parse_embedded_ticket(embedded)
                if direct is not None:
                    return direct

                for index, (width, height) in enumerate(sizes):
                    scale = min(
                        3.0,
                        2_150 / max(width, height),
                        math.sqrt(2_950_000 / (width * height)),
                    )
                    try:
                        with (
                            closing(document[index]) as page,
                            closing(page.render(scale=scale, grayscale=True)) as bitmap,
                        ):
                            images.append(bitmap.to_numpy().copy())
                    except pdfium.PdfiumError:
                        warnings.append(
                            "A PDF page could not be rendered. Enter any missing fields manually."
                        )
        except pdfium.PdfiumError as exc:
            raise TicketError(
                422, "The PDF is damaged or password-protected. Try an unlocked copy."
            ) from exc

        return self._read_ocr(images, embedded=embedded, warnings=warnings)

    def _read_ocr(
        self,
        images: list[Pixels],
        *,
        embedded: list[list[TicketLine]] | None = None,
        warnings: list[str] | None = None,
    ) -> ExtractionResult:
        embedded = embedded or []
        warnings = list(warnings or [])
        recognized = []
        deadline = monotonic() + self.timeout_seconds
        for image in images:
            try:
                payload = _prepare_image(image)
                remaining = deadline - monotonic()
                if remaining <= 0:
                    raise subprocess.TimeoutExpired(
                        self.executable, self.timeout_seconds
                    )
                recognized.append(_ocr_lines(self._tesseract(payload, remaining)))
            except subprocess.TimeoutExpired:
                warnings.append(
                    "OCR timed out. Enter any missing fields manually or try a clearer ticket."
                )
                break
            except FileNotFoundError:
                warnings.append(
                    "Tesseract OCR is unavailable. Enter any missing fields manually."
                )
                break
            except (cv2.error, OSError, subprocess.CalledProcessError):
                warnings.append(
                    "OCR could not read a page. Check Tesseract and its English language data or enter missing fields manually."
                )
            except ValueError:
                warnings.append(
                    "OCR text exceeds the processing limit for a page. Enter any missing fields manually."
                )

        has_text, has_ocr = any(embedded), any(recognized)
        if not has_ocr and not warnings:
            warnings.append(
                "OCR found no readable text. Try a clearer ticket or enter fields manually."
            )
        method = (
            "mixed"
            if has_text and has_ocr
            else "pdf_text"
            if has_text
            else "ocr"
            if has_ocr
            else "unavailable"
        )
        return parse_ticket([*embedded, *recognized], method, dict.fromkeys(warnings))

    def _tesseract(self, png: bytes, timeout: float) -> str:
        result = subprocess.run(
            [
                self.executable,
                "stdin",
                "stdout",
                "-l",
                "eng",
                "--psm",
                "6",
                "--dpi",
                "300",
                "-c",
                "tessedit_create_tsv=1",
            ],
            input=png,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=timeout,
            check=True,
            env=os.environ | {"OMP_THREAD_LIMIT": "1"},
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0,
        )
        return result.stdout.decode("utf-8", errors="replace")


def _read_image(content: bytes, media_type: TicketMediaType) -> Pixels:
    expected = "PNG" if media_type == "image/png" else "JPEG"
    try:
        with Image.open(BytesIO(content), formats=[expected]) as image:
            if image.width * image.height > MAX_IMAGE_PIXELS:
                raise TicketError(
                    413, "Image tickets may contain at most 12 million pixels."
                )
            if getattr(image, "is_animated", False):
                raise TicketError(422, "Upload a single-frame PNG or JPEG ticket.")
            image.verify()
        with Image.open(BytesIO(content), formats=[expected]) as image:
            oriented = ImageOps.exif_transpose(image)
            gray = oriented.convert("L")
            if "A" in oriented.getbands() or "transparency" in oriented.info:
                alpha = oriented.convert("RGBA").getchannel("A")
                flattened = Image.new("L", gray.size, 255)
                flattened.paste(gray, mask=alpha)
                gray = flattened
            return np.asarray(gray)
    except Image.DecompressionBombError as exc:
        raise TicketError(
            413, "Image tickets may contain at most 12 million pixels."
        ) from exc
    except (UnidentifiedImageError, OSError, SyntaxError, ValueError) as exc:
        raise TicketError(
            422, "The image is damaged or unreadable. Try another copy."
        ) from exc


def _prepare_image(gray: Pixels) -> bytes:
    height, width = gray.shape
    scale = min(
        2.0 if max(width, height) < 1_100 else 1.0,
        2_150 / max(width, height),
        math.sqrt(2_950_000 / (width * height)),
    )
    if scale != 1.0:
        gray = cv2.resize(
            gray,
            (max(1, int(width * scale)), max(1, int(height * scale))),
            interpolation=cv2.INTER_AREA if scale < 1 else cv2.INTER_CUBIC,
        )
    _, high_contrast = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)
    # Invert dark paper so Tesseract receives dark text on a light background.
    if np.mean(high_contrast) < 110:
        high_contrast = cv2.bitwise_not(high_contrast)
    ok, payload = cv2.imencode(".png", high_contrast)
    if not ok:
        raise OSError("OCR preprocessing could not encode the image.")
    return payload.tobytes()


def _ocr_lines(tsv: str) -> list[TicketLine]:
    lines: dict[tuple[str, str, str], list[tuple[str, bool]]] = {}
    remaining = MAX_TEXT_PER_PAGE
    reader = csv.DictReader(StringIO(tsv), delimiter="\t", quoting=csv.QUOTE_NONE)
    for row in reader:
        text = (row.get("text") or "").strip()
        if row.get("level") != "5" or not text:
            continue
        if len(text) + 1 > remaining:
            raise ValueError("OCR text limit exceeded.")
        remaining -= len(text) + 1
        try:
            reliable = float(row.get("conf") or "-1") >= MIN_WORD_CONFIDENCE
        except ValueError:
            reliable = False
        key = tuple(
            row.get(column) or "" for column in ("block_num", "par_num", "line_num")
        )
        lines.setdefault(key, []).append((text, reliable))
    return [
        TicketLine(
            " ".join(word for word, _ in words), all(reliable for _, reliable in words)
        )
        for words in lines.values()
    ]
