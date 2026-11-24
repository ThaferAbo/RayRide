from typing import Protocol

from .schemas import ExtractionResult, TicketMediaType


class TicketExtractor(Protocol):
    """Phase 1 interface only. Accepts validated bytes and returns editable suggestions."""

    def extract(
        self, content: bytes, *, media_type: TicketMediaType
    ) -> ExtractionResult:
        """Extract candidate fields without retaining uploaded content."""
        ...
