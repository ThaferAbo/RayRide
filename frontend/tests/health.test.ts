import assert from "node:assert/strict";
import { test } from "node:test";
import { readApiHealth } from "../lib/api-health.ts";

const healthUrl = "http://127.0.0.1:8123";

test("reads a healthy response over an uncached loopback request", async (context) => {
  const fetch = context.mock.method(globalThis, "fetch", async (url: URL, options: RequestInit) => {
    assert.equal(url.href, `${healthUrl}/health`);
    assert.equal(options.cache, "no-store");
    assert.equal(options.redirect, "error");
    return Response.json({ status: "ok", database: "ready" });
  });

  assert.deepEqual(await readApiHealth(healthUrl), { status: "ok", database: "ready" });
  assert.equal(fetch.mock.callCount(), 1);
});

test("reports an unavailable, malformed, or incompatible response", async (context) => {
  const fetch = context.mock.method(globalThis, "fetch");
  fetch.mock.mockImplementation(async () => new Response(null, { status: 503 }));
  assert.equal(await readApiHealth(healthUrl), null);

  fetch.mock.mockImplementation(async () => Response.json({ status: "ok", database: "unknown" }));
  assert.equal(await readApiHealth(healthUrl), null);

  fetch.mock.mockImplementation(async () => new Response("invalid json"));
  assert.equal(await readApiHealth(healthUrl), null);

  fetch.mock.mockImplementation(async () => { throw new TypeError("Connection refused"); });
  assert.equal(await readApiHealth(healthUrl), null);
});

test("does not send requests to a malformed or remote API URL", async (context) => {
  const fetch = context.mock.method(globalThis, "fetch");
  assert.equal(await readApiHealth("https://example.invalid"), null);
  assert.equal(await readApiHealth(`${healthUrl}/other`), null);
  assert.equal(await readApiHealth("not a url"), null);
  assert.equal(fetch.mock.callCount(), 0);
});
