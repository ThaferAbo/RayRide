import { ArrowLeftIcon, CheckCircleIcon } from "@phosphor-icons/react/ssr";
import type { Metadata } from "next";
import Link from "next/link";
import { BookingSteps } from "@/components/booking-steps";
import { CopyReference } from "@/components/copy-reference";
import { REFERENCE_PATTERN, RESERVATIONS_PATH, isReservation } from "@/lib/booking-contract";
import { callLocalApi } from "@/lib/local-api";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Reservation confirmation | RayRide", robots: { index: false, follow: false } };

export default async function Confirmation({ params }: PageProps<"/reservations/[reference]">) {
  const { reference } = await params;
  if (!REFERENCE_PATTERN.test(reference)) return <MissingReservation />;

  const response = await callLocalApi(`${RESERVATIONS_PATH}/${reference}`, 4_000);
  if (response.status === 404) return <MissingReservation />;
  const saved: unknown = response.ok ? await response.json() : null;
  if (!isReservation(saved) || saved.reference !== reference) {
    return (
      <div className="shell narrow-page">
        <section className="panel" aria-labelledby="load-title">
          <h1 className="page-title" id="load-title">Confirmation unavailable</h1>
          <p className="panel-intro">We couldn’t load the reservation right now. Keep this reference and try loading it again.</p>
          <strong className="reference-value">{reference}</strong>
          <div className="panel-actions">
            <Link href="/reservations" className="text-action">Find a reservation</Link>
            <form method="get" action={`/reservations/${reference}`}><button className="button button-primary">Try again</button></form>
          </div>
        </section>
      </div>
    );
  }

  return (
    <div className="shell narrow-page">
      <Link href="/" className="text-action confirmation-back"><ArrowLeftIcon size={17} aria-hidden="true" /> Back to RayRide</Link>
      <BookingSteps current={3} />
      <section className="panel" aria-labelledby="confirmation-title">
        <div className="confirmation-header">
          <span className="confirmation-icon" aria-hidden="true"><CheckCircleIcon size={27} weight="fill" /></span>
          <div>
            <span className="badge badge-simulation">Simulation only</span>
            <h1 id="confirmation-title" className="page-title mt-2">Reservation saved</h1>
            <p className="panel-intro">Keep the reference to find this confirmation again. No transfer provider was contacted.</p>
          </div>
        </div>
        <div className="reference-line">
          <div><span className="fine-print">Reservation reference</span><strong className="reference-value">{saved.reference}</strong></div>
          <CopyReference reference={saved.reference} />
        </div>
        <dl className="summary-grid" aria-label="Saved trip details">
          <div><dt>Flight number</dt><dd>{saved.flight_number}</dd></div>
          <div><dt>Arrival airport</dt><dd>{saved.arrival_airport}</dd></div>
          <div><dt>Arrival date</dt><dd>{saved.arrival_date}</dd></div>
          <div><dt>Arrival time (local)</dt><dd>{saved.arrival_local_time}</dd></div>
          <div className="summary-wide"><dt>Destination</dt><dd>{saved.destination}</dd></div>
        </dl>
        <div className="panel-actions panel-actions-end"><Link className="button button-primary" href="/">Create another reservation</Link></div>
      </section>
    </div>
  );
}

function MissingReservation() {
  return (
    <div className="shell narrow-page">
      <section className="panel" aria-labelledby="missing-title">
        <h1 id="missing-title" className="page-title">Reservation not found</h1>
        <p className="panel-intro">Check the reference on your simulated confirmation and try again.</p>
        <div className="panel-actions panel-actions-end"><Link href="/reservations" className="button button-primary">Find a reservation</Link></div>
      </section>
    </div>
  );
}
