import { MagnifyingGlassIcon, TicketIcon } from "@phosphor-icons/react/ssr";
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { REFERENCE_PATTERN } from "@/lib/booking-contract";

export const metadata: Metadata = { title: "Find a reservation | RayRide" };

export default async function FindReservation({ searchParams }: PageProps<"/reservations">) {
  const query = (await searchParams).reference;
  const value = typeof query === "string" ? query.trim().toUpperCase() : "";
  if (REFERENCE_PATTERN.test(value)) redirect(`/reservations/${value}`);
  const invalid = query !== undefined;

  return (
    <div className="shell narrow-page">
      <section className="panel" aria-labelledby="find-title">
        <div className="confirmation-header">
          <span className="side-icon" aria-hidden="true"><TicketIcon size={22} /></span>
          <div>
            <h1 id="find-title" className="page-title">Find a reservation</h1>
            <p className="panel-intro">Enter the reference from your simulated confirmation.</p>
          </div>
        </div>
        <form action="/reservations" method="get" className="mt-6">
          <div className="field">
            <label htmlFor="reservation-reference" className="field-label">Reservation reference</label>
            <input id="reservation-reference" name="reference" required defaultValue={value.slice(0, 25)}
              placeholder="RR-ABC123DEF456" autoComplete="off" autoCapitalize="characters"
              aria-invalid={invalid} aria-describedby={invalid ? "reference-error" : undefined} />
            {invalid && <p id="reference-error" className="field-error" role="alert">Enter a reference in the format RR-ABC123DEF456.</p>}
          </div>
          <div className="panel-actions panel-actions-end">
            <button type="submit" className="button button-primary"><MagnifyingGlassIcon size={17} aria-hidden="true" /> Look up reservation</button>
          </div>
        </form>
      </section>
    </div>
  );
}
