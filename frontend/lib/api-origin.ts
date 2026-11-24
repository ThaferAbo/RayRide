const defaultApiUrl = "http://127.0.0.1:8000";
const loopbackHosts = new Set(["127.0.0.1", "localhost", "[::1]"]);

export function readLocalApiOrigin(apiUrl = process.env.RAYRIDE_API_URL ?? defaultApiUrl): URL | null {
  try {
    const origin = new URL(apiUrl);
    if (origin.protocol !== "http:" || !loopbackHosts.has(origin.hostname) ||
        origin.username || origin.password || origin.pathname !== "/" || origin.search || origin.hash) {
      return null;
    }
    return origin;
  } catch {
    return null;
  }
}
