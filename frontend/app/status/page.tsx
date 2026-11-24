import { readApiHealth } from "@/lib/api-health";

export const dynamic = "force-dynamic";

export default async function StatusPage() {
  const apiReady = (await readApiHealth()) !== null;
  return (
    <div className="shell narrow-page">
      <section className="panel" aria-labelledby="health-title">
        <h1 id="health-title" className="page-title">System status</h1>
        <p className="muted mt-2">Local API and SQLite</p>
        <p role="status" className="mt-5 flex items-center gap-2 font-bold">
          <span aria-hidden="true" className={`size-2 rounded-full ${apiReady ? "bg-success" : "bg-danger"}`} />
          {apiReady ? "Operational" : "Unavailable"}
        </p>
        <p className="muted mt-2">
          {apiReady ? "The API responded and the database is ready." : "Check that the local API is running, then refresh."}
        </p>
        <form action="/status" method="get" className="mt-6">
          <button type="submit" className="button button-outline">Refresh status</button>
        </form>
      </section>
    </div>
  );
}
