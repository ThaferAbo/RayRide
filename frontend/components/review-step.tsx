import { ArrowLeftIcon, ArrowRightIcon, WarningCircleIcon } from "@phosphor-icons/react";
import type { FormEvent } from "react";
import type { Extraction, FieldErrors, FlightField, TripDraft } from "@/lib/booking-contract";

const flightInputs: { name: FlightField; label: string; placeholder?: string; type?: "date"; help?: string }[] = [
  { name: "flight_number", label: "Flight number", placeholder: "e.g. ZZ731" },
  { name: "arrival_airport", label: "Arrival airport", placeholder: "e.g. AYT", help: "Three-letter airport code" },
  { name: "arrival_date", label: "Arrival date", type: "date" },
  { name: "arrival_local_time", label: "Arrival time", placeholder: "e.g. 14:10", help: "Local time at the arrival airport" },
];

export function ReviewStep({ trip, source, reviewed, errors, failure, pending, onChange, onReview, onBack, onSubmit }: {
  trip: TripDraft;
  source: Extraction | null;
  reviewed: boolean;
  errors: FieldErrors;
  failure: string;
  pending: boolean;
  onChange: (field: keyof TripDraft, value: string) => void;
  onReview: (reviewed: boolean) => void;
  onBack: () => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
}) {
  const reviewNote = source?.method === "unavailable"
    ? "We couldn’t read this ticket. Enter the flight details below or try another file."
    : source?.warnings.find((warning) => !/^Review the uncertain|^Enter the missing/.test(warning));

  return (
    <section className="panel" aria-labelledby="review-title">
      <h2 className="panel-title" id="review-title" tabIndex={-1}>Review your flight details</h2>
      <p className="panel-intro">Check the arrival details against your ticket and choose a destination.</p>
      {reviewNote && <div className="notice notice-review" role="status"><WarningCircleIcon size={18} aria-hidden="true" />{reviewNote}</div>}
      {pending && <p className="sr-only" role="status">Saving the simulated reservation.</p>}
      <form noValidate onSubmit={onSubmit}>
        <fieldset disabled={pending}>
          <div className="field-grid">
            {flightInputs.map(({ name, label, placeholder, type, help }) => {
              const suggested = source?.[name];
              const changed = suggested && (suggested.value ?? "") !== trip[name];
              const status = changed ? (trip[name].trim() ? "edited" : "missing") : suggested?.status;
              const error = errors[name];
              const description = [status && `${name}-status`, help && `${name}-help`, error && `${name}-error`].filter(Boolean).join(" ");
              return (
                <div key={name} className="field">
                  <div className="field-label">
                    <label htmlFor={name}>{label}</label>
                    {status && <span id={`${name}-status`} className={`badge badge-${status}`}>{status[0].toUpperCase() + status.slice(1)}</span>}
                  </div>
                  <input id={name} name={name} type={type ?? "text"} value={trip[name]} placeholder={placeholder}
                    autoComplete="off" spellCheck={false} autoCapitalize={name === "arrival_local_time" ? "off" : "characters"}
                    required aria-invalid={Boolean(error)} aria-describedby={description || undefined}
                    onChange={(event) => onChange(name, event.currentTarget.value)} />
                  {help && <p className="field-help" id={`${name}-help`}>{help}</p>}
                  {error && <p className="field-error" id={`${name}-error`}>{error}</p>}
                </div>
              );
            })}
            <div className="field field-wide">
              <div className="field-label"><label htmlFor="destination">Destination</label></div>
              <input id="destination" name="destination" value={trip.destination} placeholder="Hotel, neighborhood or address"
                autoComplete="off" required aria-invalid={Boolean(errors.destination)}
                aria-describedby={errors.destination ? "destination-error" : undefined}
                list={trip.arrival_airport.trim().toUpperCase() === "AYT" ? "antalya-destinations" : undefined}
                onChange={(event) => onChange("destination", event.currentTarget.value)} />
              <datalist id="antalya-destinations">
                <option>Antalya city center</option><option>Lara</option><option>Belek</option><option>Kemer</option><option>Side</option>
              </datalist>
              {errors.destination && <p className="field-error" id="destination-error">{errors.destination}</p>}
            </div>
          </div>
          <label className="review-box" htmlFor="reviewed">
            <input type="checkbox" id="reviewed" checked={reviewed} required aria-invalid={Boolean(errors.reviewed)}
              aria-describedby={errors.reviewed ? "reviewed-error" : undefined}
              onChange={(event) => onReview(event.currentTarget.checked)} />
            I’ve reviewed the flight details and destination for this simulated reservation.
          </label>
          {errors.reviewed && <p className="field-error" id="reviewed-error">{errors.reviewed}</p>}
        </fieldset>
        {failure && <div className="notice notice-error" role="alert"><WarningCircleIcon size={18} aria-hidden="true" />{failure}</div>}
        <div className="panel-actions">
          <button type="button" className="button button-outline" disabled={pending} onClick={onBack}>
            <ArrowLeftIcon size={17} aria-hidden="true" /> Back to ticket
          </button>
          <button type="submit" className="button button-primary" disabled={pending}>
            {pending ? "Saving reservation…" : "Create simulated reservation"}
            <ArrowRightIcon size={17} aria-hidden="true" />
          </button>
        </div>
      </form>
    </section>
  );
}
