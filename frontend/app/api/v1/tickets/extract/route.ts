import { MAX_TICKET_BYTES, TICKET_PATH } from "@/lib/booking-contract";
import { forwardPost } from "@/lib/local-api";

export function POST(request: Request) {
  return forwardPost(request, TICKET_PATH, {
    contentType: "multipart/form-data", maxBytes: MAX_TICKET_BYTES + 16 * 1024, timeoutMs: 40_000,
  });
}
