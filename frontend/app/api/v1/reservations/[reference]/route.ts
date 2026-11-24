import { REFERENCE_PATTERN, RESERVATIONS_PATH } from "@/lib/booking-contract";
import { callLocalApi } from "@/lib/local-api";

export async function GET(request: Request, context: RouteContext<"/api/v1/reservations/[reference]">) {
  const { reference } = await context.params;
  if (!REFERENCE_PATTERN.test(reference)) {
    return Response.json({ detail: { code: "invalid_reservation", message: "Enter a valid reservation reference." } }, {
      status: 422, headers: { "cache-control": "no-store" },
    });
  }
  return callLocalApi(`${RESERVATIONS_PATH}/${reference}`, 4_000, { signal: request.signal });
}
