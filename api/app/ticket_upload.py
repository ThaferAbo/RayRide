import logging
import re
from dataclasses import dataclass
from pathlib import PurePath
from typing import Literal

from python_multipart import MultipartParser
from python_multipart.exceptions import MultipartParseError
from python_multipart.multipart import parse_options_header
from starlette.requests import ClientDisconnect, Request

from .schemas import TicketMediaType

MAX_TICKET_BYTES = 10 * 1024 * 1024
MAX_REQUEST_BYTES = MAX_TICKET_BYTES + 16 * 1024
_MAX_PART_HEADERS_BYTES = 8 * 1024
_PRIVATE_MULTIPART_LOGGER = logging.Logger("rayride.multipart")
_PRIVATE_MULTIPART_LOGGER.disabled = (
    True  # Parse errors can contain bytes from the request.
)
_EXTENSIONS: dict[str, TicketMediaType] = {
    ".pdf": "application/pdf",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
}


class TicketError(Exception):
    def __init__(self, status: Literal[400, 413, 415, 422], message: str) -> None:
        super().__init__(message)
        self.status = status


@dataclass(frozen=True)
class TicketUpload:
    content: bytes
    media_type: TicketMediaType


class _TicketPart:
    def __init__(self) -> None:
        self.content = bytearray()
        self.media_type: TicketMediaType | None = None
        self.ended = False
        self.headers: dict[bytes, bytes] = {}
        self.header_field = bytearray()
        self.header_value = bytearray()
        self.header_bytes = 0
        self.parts = 0

    def part_begin(self) -> None:
        self.parts += 1
        if self.parts != 1:
            raise TicketError(
                400, "Send exactly one multipart file in the ticket field."
            )

    def _append_header(
        self, target: bytearray, data: bytes, start: int, end: int
    ) -> None:
        self.header_bytes += end - start
        if self.header_bytes > _MAX_PART_HEADERS_BYTES:
            raise TicketError(400, "The ticket upload headers are too large.")
        target.extend(data[start:end])

    def read_header_field(self, data: bytes, start: int, end: int) -> None:
        self._append_header(self.header_field, data, start, end)

    def read_header_value(self, data: bytes, start: int, end: int) -> None:
        self._append_header(self.header_value, data, start, end)

    def header_end(self) -> None:
        field = bytes(self.header_field).lower()
        if field in self.headers:
            raise TicketError(
                400, "The ticket upload contains a duplicate part header."
            )
        self.headers[field] = bytes(self.header_value)
        self.header_field.clear()
        self.header_value.clear()

    def headers_finished(self) -> None:
        disposition, params = parse_options_header(
            self.headers.get(b"content-disposition")
        )
        filename = params.get(b"filename", b"")
        if (
            disposition.lower() != b"form-data"
            or params.get(b"name") != b"ticket"
            or not filename
        ):
            raise TicketError(
                400, "Send exactly one multipart file in the ticket field."
            )
        extension = PurePath(
            filename.decode("latin-1").replace("\\", "/")
        ).suffix.lower()
        self.media_type = _EXTENSIONS.get(extension)
        if self.media_type is None:
            raise TicketError(415, "Upload a PDF, PNG or JPEG ticket.")
        declared, _ = parse_options_header(self.headers.get(b"content-type"))
        if declared.lower() not in (
            b"",
            b"application/octet-stream",
            self.media_type.encode("ascii"),
        ):
            raise TicketError(
                415, "The ticket content type does not match its file extension."
            )
        encoding = (
            self.headers.get(b"content-transfer-encoding", b"binary").strip().lower()
        )
        if encoding not in (b"binary", b"8bit"):
            raise TicketError(400, "Send the ticket as binary multipart data.")

    def part_data(self, data: bytes, start: int, end: int) -> None:
        if len(self.content) + end - start > MAX_TICKET_BYTES:
            raise TicketError(413, "The ticket exceeds the 10 MiB file limit.")
        self.content.extend(data[start:end])

    def end(self) -> None:
        self.ended = True


async def read_ticket_upload(request: Request) -> TicketUpload:
    media_type, params = parse_options_header(request.headers.get("content-type"))
    boundary = params.get(b"boundary", b"")
    if (
        media_type.lower() != b"multipart/form-data"
        or not re.fullmatch(rb"[0-9A-Za-z'()+_,./:=? -]{1,70}", boundary)
        or boundary.endswith(b" ")
    ):
        raise TicketError(400, "Send a multipart/form-data request with a ticket file.")

    length = request.headers.get("content-length")
    if length is not None:
        if not re.fullmatch(r"[0-9]{1,20}", length):
            raise TicketError(400, "The upload Content-Length is invalid.")
        if int(length) > MAX_REQUEST_BYTES:
            raise TicketError(413, "The ticket upload exceeds the request size limit.")

    part = _TicketPart()
    parser = MultipartParser(
        boundary,
        {
            "on_part_begin": part.part_begin,
            "on_header_field": part.read_header_field,
            "on_header_value": part.read_header_value,
            "on_header_end": part.header_end,
            "on_headers_finished": part.headers_finished,
            "on_part_data": part.part_data,
            "on_end": part.end,
        },
    )
    parser.logger = _PRIVATE_MULTIPART_LOGGER
    received = 0
    try:
        async for chunk in request.stream():
            received += len(chunk)
            if received > MAX_REQUEST_BYTES:
                raise TicketError(
                    413, "The ticket upload exceeds the request size limit."
                )
            if chunk:
                parser.write(chunk)
        parser.finalize()
    except (ClientDisconnect, MultipartParseError) as exc:
        raise TicketError(
            400, "The multipart ticket upload is incomplete or malformed."
        ) from exc

    if not part.ended or part.media_type is None:
        raise TicketError(400, "A complete multipart ticket file is required.")
    if not part.content:
        raise TicketError(422, "The uploaded ticket is empty.")
    return TicketUpload(bytes(part.content), part.media_type)
