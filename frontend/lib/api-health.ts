import type { paths } from "./api.types";

type HealthResponse = paths["/health"]["get"]["responses"][200]["content"]["application/json"];

const defaultApiUrl = "http://127.0.0.1:8000";
const loopbackHosts = new Set(["127.0.0.1", "localhost", "[::1]"]);

function isHealthy(body: unknown): body is HealthResponse {
  return typeof body === "object" && body !== null &&
    "status" in body && body.status === "ok" &&
    "database" in body && body.database === "ready";
}

export async function readApiHealth(
  apiUrl = process.env.RAYRIDE_API_URL ?? defaultApiUrl,
): Promise<HealthResponse | null> {
  try {
    const origin = new URL(apiUrl);
    if (origin.protocol !== "http:" || !loopbackHosts.has(origin.hostname) ||
        origin.username || origin.password || origin.pathname !== "/" || origin.search || origin.hash) {
      return null;
    }

    const response = await fetch(new URL("/health", origin), {
      cache: "no-store",
      redirect: "error",
      signal: AbortSignal.timeout(2500),
    });
    if (!response.ok) return null;

    const body: unknown = await response.json();
    return isHealthy(body) ? body : null;
  } catch {
    return null;
  }
}
