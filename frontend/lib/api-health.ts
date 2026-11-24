import type { paths } from "./api.types";
import { readLocalApiOrigin } from "./api-origin.ts";

type HealthResponse = paths["/health"]["get"]["responses"][200]["content"]["application/json"];

function isHealthy(body: unknown): body is HealthResponse {
  return typeof body === "object" && body !== null &&
    "status" in body && body.status === "ok" &&
    "database" in body && body.database === "ready";
}

export async function readApiHealth(apiUrl?: string): Promise<HealthResponse | null> {
  try {
    const origin = readLocalApiOrigin(apiUrl);
    if (!origin) return null;

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
