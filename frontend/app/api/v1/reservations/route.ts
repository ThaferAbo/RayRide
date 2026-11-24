import { MAX_RESERVATION_BYTES, RESERVATIONS_PATH } from "@/lib/booking-contract";
import { forwardPost } from "@/lib/local-api";

export function POST(request: Request) {
  return forwardPost(request, RESERVATIONS_PATH, {
    contentType: "application/json", maxBytes: MAX_RESERVATION_BYTES, timeoutMs: 6_000, idempotent: true,
  });
}
