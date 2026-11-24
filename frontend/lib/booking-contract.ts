import type { components } from "./api.types";

export type Extraction = components["schemas"]["ExtractionResult"];
export type Reservation = components["schemas"]["ReservationResponse"];
export type ReviewedReservation = components["schemas"]["ReservationRequest"];
export type TripDraft = Omit<ReviewedReservation, "reviewed">;
export type FlightField = Exclude<keyof TripDraft, "destination">;
export type FieldErrors = Partial<Record<keyof TripDraft | "reviewed", string>>;

export const TICKET_PATH = "/api/v1/tickets/extract";
export const RESERVATIONS_PATH = "/api/v1/reservations";
export const MAX_TICKET_BYTES = 10 * 1024 * 1024;
export const MAX_RESERVATION_BYTES = 8 * 1024;
export const REFERENCE_PATTERN = /^RR-[A-Z0-9]{12}$/;

export const FLIGHT_FIELDS: FlightField[] = ["flight_number", "arrival_airport", "arrival_date", "arrival_local_time"];
export const EMPTY_TRIP: TripDraft = {
  flight_number: "", arrival_airport: "", arrival_date: "", arrival_local_time: "", destination: "",
};

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function isExtraction(value: unknown): value is Extraction {
  if (!isObject(value) || typeof value.method !== "string" ||
      !["pdf_text", "ocr", "mixed", "unavailable"].includes(value.method) ||
      !Array.isArray(value.warnings) || !value.warnings.every((warning) => typeof warning === "string")) return false;
  return FLIGHT_FIELDS.every((name) => {
    const field = value[name];
    if (!isObject(field)) return false;
    if (field.status === "extracted") return typeof field.value === "string";
    if (field.status === "missing") return field.value === null;
    return field.status === "uncertain" && (field.value === null || typeof field.value === "string");
  });
}

export function isReservation(value: unknown): value is Reservation {
  return isObject(value) && value.status === "simulated" && typeof value.reference === "string" &&
    REFERENCE_PATTERN.test(value.reference) && [...FLIGHT_FIELDS, "destination", "created_at"].every((field) => typeof value[field] === "string");
}

export function normalizedTrip(draft: TripDraft): TripDraft {
  return {
    flight_number: draft.flight_number.trim().toUpperCase().replace(/[\s-]/g, ""),
    arrival_airport: draft.arrival_airport.trim().toUpperCase(),
    arrival_date: draft.arrival_date.trim(),
    arrival_local_time: draft.arrival_local_time.trim(),
    destination: draft.destination.trim(),
  };
}

export function validateTrip(trip: TripDraft, reviewed: boolean): FieldErrors {
  const errors: FieldErrors = {};
  if (!/^(?:[A-Z][A-Z0-9]|[0-9][A-Z])\d{1,4}[A-Z]?$/.test(trip.flight_number)) {
    errors.flight_number = "Enter a flight number such as ZZ731.";
  }
  if (!/^[A-Z]{3}$/.test(trip.arrival_airport)) errors.arrival_airport = "Enter a three-letter airport code.";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(trip.arrival_date)) errors.arrival_date = "Enter an arrival date.";
  if (!/^(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d(?:\.\d{1,6})?)?$/.test(trip.arrival_local_time)) {
    errors.arrival_local_time = "Enter a local 24-hour time such as 14:10.";
  }
  if (!trip.destination || Array.from(trip.destination).length > 200) {
    errors.destination = "Enter a destination of up to 200 characters.";
  }
  if (!reviewed) errors.reviewed = "Confirm that you reviewed these trip details.";
  return errors;
}
