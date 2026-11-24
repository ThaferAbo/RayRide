import { readApiHealth } from "../lib/api-health";

export const dynamic = "force-dynamic";

export default async function Home() {
  const apiReady = (await readApiHealth()) !== null;

  return (
    <div className="mx-auto max-w-5xl px-6 sm:px-10">
      <header className="flex flex-wrap items-center justify-between gap-3 border-b border-rule py-6">
        <span className="text-lg font-bold tracking-tight">RayRide</span>
        <span className="text-sm text-muted">CSE491 · Group 4</span>
      </header>

      <main className="grid gap-10 pt-14 pb-20 md:grid-cols-[1fr_19rem] md:items-start md:gap-14 md:pt-24">
        <div>
          <h1 className="text-4xl leading-tight font-semibold tracking-tight sm:text-5xl">Prototype status</h1>
          <p className="mt-5 max-w-md text-base leading-7 text-muted">
            Phase 1 connects the airport transfer prototype to its local API and database.
            Ticket processing and simulated reservations are planned for later phases.
          </p>
        </div>

        <section aria-labelledby="health-title" className="border-t-2 border-accent bg-white p-6">
          <h2 id="health-title" className="text-base font-semibold">API and SQLite</h2>
          <p role="status" className="mt-3 flex items-center gap-2 text-sm font-semibold">
            <span aria-hidden="true" className={`size-2 rounded-full ${apiReady ? "bg-accent" : "bg-muted"}`} />
            {apiReady ? "Operational" : "Unavailable"}
          </p>
          <p className="mt-2 text-sm leading-6 text-muted">
            {apiReady ? "The API responded and the database is ready." : "Check that the local API is running, then refresh."}
          </p>
          <form action="/" method="get" className="mt-5">
            <button type="submit" className="cursor-pointer border border-accent px-3 py-2 text-sm font-semibold text-accent hover:bg-canvas focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent">
              Refresh status
            </button>
          </form>
        </section>
      </main>
    </div>
  );
}
