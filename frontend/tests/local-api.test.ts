import assert from "node:assert/strict";
import { test } from "node:test";
import { callLocalApi, forwardPost } from "../lib/local-api.ts";

const url = "http://127.0.0.1:3131/api/v1/reservations";
const path = "/api/v1/reservations";
const options = { contentType: "application/json", maxBytes: 8192, timeoutMs: 300, idempotent: true };

test("blocks cross-origin, wrong-type and oversized requests before contacting the API", async (context) => {
  const fetch = context.mock.method(globalThis, "fetch");
  const origin = { origin: "https://example.invalid", "content-type": "application/json" };
  const crossOrigin = new Request(url, { method: "POST", headers: origin, body: "{}" });
  const wrongType = new Request(url, { method: "POST", body: "not JSON" });
  const oversized = new Request(url, { method: "POST", body: " ".repeat(8193), headers: { "content-type": "application/json" } });

  assert.equal((await forwardPost(crossOrigin, path, options)).status, 403);
  assert.equal((await forwardPost(wrongType, path, options)).status, 415);
  assert.equal((await forwardPost(oversized, path, options)).status, 413);
  assert.equal(fetch.mock.callCount(), 0);
});

test("forwards bounded bytes with only the allowed headers and disables caching", async (context) => {
  context.mock.method(globalThis, "fetch", async (upstream: URL, init: RequestInit) => {
    assert.equal(upstream.pathname, path);
    assert.equal(init.cache, "no-store");
    assert.equal(init.redirect, "error");
    assert.equal(init.method, "POST");
    assert.equal(new TextDecoder().decode(init.body as Uint8Array<ArrayBuffer>), '{"reviewed":true}');
    const headers = new Headers(init.headers);
    assert.equal(headers.get("idempotency-key"), "b8b12dd0-3475-4307-98b6-d21b5e72a4b6");
    assert.equal(headers.has("cookie"), false);
    return Response.json({ status: "simulated" }, { status: 201, headers: { "set-cookie": "private=ignored" } });
  });
  const request = new Request(url, {
    method: "POST", body: '{"reviewed":true}',
    headers: { "content-type": "application/json", "idempotency-key": "b8b12dd0-3475-4307-98b6-d21b5e72a4b6", cookie: "private=ignored" },
  });
  const response = await forwardPost(request, path, options);
  assert.equal(response.status, 201);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(response.headers.has("set-cookie"), false);
});

test("rejects out-of-bound and non-JSON upstream responses", async (context) => {
  const fetch = context.mock.method(globalThis, "fetch", async () => Response.json({ data: "x".repeat(65_536) }));
  assert.equal((await callLocalApi(path, 300)).status, 503);
  fetch.mock.mockImplementation(async () => new Response("invalid content"));
  assert.equal((await callLocalApi(path, 300)).status, 503);
});

test("returns a timeout when the loopback API does not respond", async (context) => {
  context.mock.method(globalThis, "fetch", (_url: URL, init: RequestInit) => new Promise<Response>((resolve, reject) => {
    const delayed = setTimeout(() => resolve(Response.json({ status: "simulated" })), 1_000);
    init.signal?.addEventListener("abort", () => {
      clearTimeout(delayed);
      reject(init.signal?.reason);
    }, { once: true });
  }));
  const response = await callLocalApi(path, 20);
  assert.equal(response.status, 504);
  assert.equal((await response.json()).detail.code, "api_timeout");
});
