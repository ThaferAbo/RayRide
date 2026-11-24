import { readLocalApiOrigin } from "./api-origin.ts";

const MAX_RESPONSE_BYTES = 64 * 1024;
const responseHeaders = { "cache-control": "no-store", "x-content-type-options": "nosniff" };

class BodyLimitError extends Error {}

function failure(status: number, code: string, message: string) {
  return Response.json({ detail: { code, message } }, { status, headers: responseHeaders });
}

async function boundedBody(body: ReadableStream<Uint8Array> | null, limit: number, signal: AbortSignal) {
  signal.throwIfAborted();
  if (!body) return new Uint8Array();
  const reader = body.getReader();
  const cancel = () => { void reader.cancel().catch(() => undefined); };
  signal.addEventListener("abort", cancel, { once: true });
  const chunks: Uint8Array[] = [];
  let length = 0;
  try {
    for (;;) {
      const { done, value } = await reader.read();
      signal.throwIfAborted();
      if (done) break;
      length += value.byteLength;
      if (length > limit) {
        cancel();
        throw new BodyLimitError();
      }
      chunks.push(value);
    }
  } finally {
    signal.removeEventListener("abort", cancel);
    reader.releaseLock();
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return bytes;
}

export async function callLocalApi(path: string, timeoutMs: number, init?: RequestInit) {
  const origin = readLocalApiOrigin();
  if (!origin) return failure(503, "api_unavailable", "The local API is unavailable. Try again in a moment.");
  const deadline = AbortSignal.timeout(timeoutMs);
  const signal = init?.signal ? AbortSignal.any([deadline, init.signal]) : deadline;
  try {
    const url = new URL(path, origin);
    if (url.origin !== origin.origin) throw new Error("Unexpected API origin");
    const upstream = await fetch(url, { ...init, signal, cache: "no-store", redirect: "error" });
    if (!upstream.headers.get("content-type")?.startsWith("application/json")) {
      await upstream.body?.cancel();
      throw new Error("Unexpected API response type");
    }
    const reply: unknown = JSON.parse(new TextDecoder().decode(await boundedBody(upstream.body, MAX_RESPONSE_BYTES, signal)));
    return Response.json(reply, { status: upstream.status, headers: responseHeaders });
  } catch {
    return deadline.aborted
      ? failure(504, "api_timeout", "The local API did not respond in time. You can try again.")
      : failure(503, "api_unavailable", "The local API is unavailable. Try again in a moment.");
  }
}

function isSameOrigin(request: Request) {
  const site = request.headers.get("sec-fetch-site");
  if (site && site !== "same-origin" && site !== "none") return false;
  const origin = request.headers.get("origin");
  const requestUrl = new URL(request.url);
  const host = request.headers.get("host") ?? requestUrl.host;
  return origin === null || origin === `${requestUrl.protocol}//${host}`;
}

export async function forwardPost(
  request: Request,
  path: string,
  options: { contentType: string; maxBytes: number; timeoutMs: number; idempotent?: boolean },
) {
  if (!isSameOrigin(request)) {
    return failure(403, "cross_origin", "Open RayRide directly to send this request.");
  }
  const contentType = request.headers.get("content-type") ?? "";
  if (contentType.length > 256 || contentType.split(";", 1)[0].trim().toLowerCase() !== options.contentType) {
    return failure(415, "invalid_content_type", "This request uses an unsupported format.");
  }
  const length = request.headers.get("content-length");
  if (length !== null && (!/^\d{1,16}$/.test(length) || Number(length) > options.maxBytes)) {
    return failure(413, "request_too_large", "This request exceeds the upload limit.");
  }
  const deadline = AbortSignal.timeout(12_000);
  let bytes: Uint8Array<ArrayBuffer>;
  try {
    bytes = await boundedBody(request.body, options.maxBytes, AbortSignal.any([request.signal, deadline]));
  } catch (error) {
    if (error instanceof BodyLimitError) return failure(413, "request_too_large", "This request exceeds the upload limit.");
    return failure(408, "incomplete_upload", "The request did not finish. You can try again.");
  }
  const headers = new Headers({ "content-type": contentType });
  const key = request.headers.get("idempotency-key");
  if (options.idempotent && key) headers.set("idempotency-key", key);
  return callLocalApi(path, options.timeoutMs, { method: "POST", headers, body: bytes, signal: request.signal });
}
