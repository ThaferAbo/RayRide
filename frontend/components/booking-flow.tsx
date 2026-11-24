"use client";

import { ClockIcon, ShieldCheckIcon } from "@phosphor-icons/react";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState, type FormEvent } from "react";
import {
  EMPTY_TRIP, FLIGHT_FIELDS, MAX_TICKET_BYTES, RESERVATIONS_PATH, TICKET_PATH,
  isExtraction, isReservation, normalizedTrip, validateTrip, type Extraction, type FieldErrors, type ReviewedReservation, type TripDraft,
} from "@/lib/booking-contract";
import { BookingSteps } from "./booking-steps";
import { ReviewStep } from "./review-step";
import { TicketStep } from "./ticket-step";

class RequestError extends Error {
  fields: FieldErrors;
  constructor(message: string, fields: FieldErrors = {}) {
    super(message);
    this.fields = fields;
  }
}

async function apiJson(url: string, options: RequestInit, fallback: string): Promise<unknown> {
  const response = await fetch(url, { ...options, cache: "no-store", credentials: "same-origin" });
  const body = await response.json().catch(() => null);
  if (!response.ok || !body) {
    const message = typeof body?.detail?.message === "string" ? body.detail.message : fallback;
    const fields: FieldErrors = {};
    for (const name of [...FLIGHT_FIELDS, "destination", "reviewed"] as const) {
      const error = body?.detail?.fields?.[name];
      if (typeof error === "string") fields[name] = error;
    }
    throw new RequestError(message, fields);
  }
  return body;
}

function showFirstError(errors: FieldErrors) {
  const field = ([...FLIGHT_FIELDS, "destination", "reviewed"] as const).find((name) => errors[name]);
  if (field) requestAnimationFrame(() => document.getElementById(field)?.focus());
}

export function BookingFlow() {
  const router = useRouter();
  const [step, setStep] = useState<1 | 2>(1);
  const [file, setFile] = useState<File | null>(null);
  const [source, setSource] = useState<Extraction | null>(null);
  const [trip, setTrip] = useState<TripDraft>(EMPTY_TRIP);
  const [reviewed, setReviewed] = useState(false);
  const [pending, setPending] = useState<"ticket" | "save" | null>(null);
  const [failure, setFailure] = useState("");
  const [errors, setErrors] = useState<FieldErrors>({});
  const active = useRef<AbortController | null>(null);
  const attempt = useRef<{ payload: string; key: string } | null>(null);

  useEffect(() => () => { active.current?.abort(); }, []);
  useEffect(() => {
    if (step === 2) document.getElementById("review-title")?.focus();
  }, [step]);

  function pickFile(next: File) {
    setFailure("");
    if (!/\.(pdf|png|jpe?g)$/i.test(next.name)) {
      setFile(null);
      setFailure("Choose a PDF, PNG or JPEG ticket, or enter flight details manually.");
    } else if (!next.size || next.size > MAX_TICKET_BYTES) {
      setFile(null);
      setFailure(next.size ? "Choose a ticket no larger than 10 MiB." : "This file is empty. Choose another ticket.");
    } else {
      setFile(next);
    }
  }

  function openReview(extraction: Extraction | null) {
    active.current?.abort();
    active.current = null;
    setPending(null);
    setFailure("");
    setErrors({});
    setReviewed(false);
    setFile(null);
    setSource(extraction);
    if (extraction) setTrip((previous) => ({
      flight_number: extraction.flight_number.value ?? "", arrival_airport: extraction.arrival_airport.value ?? "",
      arrival_date: extraction.arrival_date.value ?? "", arrival_local_time: extraction.arrival_local_time.value ?? "",
      destination: previous.destination,
    }));
    setStep(2);
  }

  async function extract() {
    if (!file || active.current) return;
    const request = new AbortController();
    active.current = request;
    setPending("ticket");
    setFailure("");
    const form = new FormData();
    form.append("ticket", file);
    try {
      const extraction = await apiJson(TICKET_PATH, {
        method: "POST", body: form, signal: AbortSignal.any([request.signal, AbortSignal.timeout(55_000)]),
      }, "We couldn't read the ticket. Try again or enter details manually.");
      if (!isExtraction(extraction)) throw new RequestError("We couldn't read the ticket. Try again or enter details manually.");
      if (active.current === request) openReview(extraction);
    } catch (error) {
      if (active.current === request) setFailure(error instanceof RequestError ? error.message : "The ticket request could not finish. Try again or enter details manually.");
    } finally {
      if (active.current === request) {
        active.current = null;
        setPending(null);
      }
    }
  }

  function changeField(field: keyof TripDraft, value: string) {
    setTrip((previous) => ({ ...previous, [field]: value }));
    setReviewed(false);
    setErrors((previous) => ({ ...previous, [field]: undefined, reviewed: undefined }));
    setFailure("");
  }

  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (active.current) return;
    const normalized = normalizedTrip(trip);
    const validation = validateTrip(normalized, reviewed);
    setErrors(validation);
    setFailure("");
    if (Object.keys(validation).length) {
      showFirstError(validation);
      return;
    }

    const details: ReviewedReservation = { ...normalized, reviewed: true };
    const payload = JSON.stringify(details);
    if (attempt.current?.payload !== payload) attempt.current = { payload, key: crypto.randomUUID() };
    const request = new AbortController();
    active.current = request;
    setPending("save");
    let confirmed = false;
    try {
      const reservation = await apiJson(RESERVATIONS_PATH, {
        method: "POST", headers: { "content-type": "application/json", "idempotency-key": attempt.current.key },
        body: payload, signal: AbortSignal.any([request.signal, AbortSignal.timeout(18_000)]),
      }, "We couldn't confirm the reservation. Retry with the same trip details.");
      if (!isReservation(reservation)) {
        throw new RequestError("We couldn't confirm the reservation. Retry with the same trip details.");
      }
      confirmed = true;
      router.push(`/reservations/${reservation.reference}`);
    } catch (error) {
      if (request.signal.aborted) return;
      const fields = error instanceof RequestError ? error.fields : {};
      setErrors(fields);
      setFailure(error instanceof RequestError ? error.message : "The reservation request did not finish. Retry with the same trip details.");
      showFirstError(fields);
    } finally {
      if (!confirmed) {
        active.current = null;
        setPending(null);
      }
    }
  }

  return (
    <section aria-label="Book a simulated reservation">
      <BookingSteps current={step} />
      <div className="booking-grid">
        {step === 1 ? (
          <TicketStep file={file} pending={pending === "ticket"} error={failure}
            onPick={pickFile} onExtract={extract} onManual={() => openReview(null)} />
        ) : (
          <ReviewStep trip={trip} source={source} reviewed={reviewed} errors={errors} failure={failure}
            pending={pending === "save"} onChange={changeField} onSubmit={save}
            onReview={(checked) => { setReviewed(checked); setErrors((previous) => ({ ...previous, reviewed: undefined })); }}
            onBack={() => { setStep(1); setFailure(""); setErrors({}); setReviewed(false); }} />
        )}
        <aside className="side-rail" aria-label="Booking information">
          <section className="side-card">
            <span className="side-icon"><ShieldCheckIcon size={20} aria-hidden="true" /></span>
            <div><h2>Ticket privacy</h2><p>Ticket files are processed locally and discarded. Only the trip details you confirm are saved.</p></div>
          </section>
          <section className="side-card">
            <span className="side-icon"><ClockIcon size={20} aria-hidden="true" /></span>
            <div><h2>Check the local arrival time</h2><p>Use the date and time at your arrival airport. For connecting flights, review the leg you want a transfer from.</p></div>
          </section>
        </aside>
      </div>
    </section>
  );
}
