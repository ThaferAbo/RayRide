import { expect, test, type Page } from "@playwright/test";
import { fileURLToPath } from "node:url";

const samples = fileURLToPath(new URL("../../../samples/", import.meta.url));
const submitName = "Create simulated reservation";
const reservationPath = "/api/v1/reservations";
const referencePattern = /RR-[A-Z0-9]{12}/;

async function upload(page: Page, name: string) {
  await page.locator("#ticket-file").setInputFiles(`${samples}${name}`);
  await page.getByRole("button", { name: "Extract flight details" }).click();
  await expect(page.getByRole("heading", { name: "Review your flight details" })).toBeVisible();
}

async function fillFlight(page: Page, flight: string, airport: string, date: string, time: string) {
  await page.getByLabel("Flight number", { exact: true }).fill(flight);
  await page.getByLabel("Arrival airport", { exact: true }).fill(airport);
  await page.getByLabel("Arrival date", { exact: true }).fill(date);
  await page.getByLabel("Arrival time", { exact: true }).fill(time);
}

async function reviewAndSave(page: Page) {
  await page.getByRole("checkbox", { name: "I’ve reviewed", exact: false }).check();
  await page.getByRole("button", { name: submitName }).click();
  await expect(page.getByRole("heading", { name: "Reservation saved" })).toBeVisible();
  await expect(page.getByText("Simulation only", { exact: true })).toBeVisible();
}

for (const ticket of ["text-ticket.pdf", "scanned-ticket.pdf"]) {
  test(`extracts ${ticket} and saves a confirmation that can be retrieved`, async ({ page, browser, baseURL }) => {
    const externalRequests: string[] = [];
    page.on("request", (request) => {
      if (new URL(request.url()).origin !== baseURL) externalRequests.push(request.url());
    });
    await page.goto("/");
    await upload(page, ticket);
    await expect(page.getByText("Extracted", { exact: true })).toHaveCount(4);
    await expect(page.getByLabel("Flight number", { exact: true })).toHaveValue("ZZ731");
    await expect(page.getByLabel("Arrival time", { exact: true })).toHaveValue("14:10:00");
    await page.getByLabel("Destination", { exact: true }).fill("Antalya city center");
    await page.getByRole("button", { name: submitName }).click();
    await expect(page.getByText("Confirm that you reviewed these trip details.")).toBeVisible();
    await reviewAndSave(page);

    const reference = page.url().match(referencePattern)?.[0];
    expect(reference).toBeTruthy();
    const saved = await page.request.get(`${reservationPath}/${reference}`);
    expect(saved.ok()).toBeTruthy();
    expect(await saved.json()).toMatchObject({
      reference, flight_number: "ZZ731", arrival_airport: "AYT", arrival_date: "2026-12-03",
      arrival_local_time: "14:10:00", destination: "Antalya city center", status: "simulated",
    });
    await page.reload();
    await expect(page.getByText("Antalya city center", { exact: true })).toBeVisible();
    expect(externalRequests).toEqual([]);

    const fresh = await browser.newContext({ baseURL });
    try {
      const lookup = await fresh.newPage();
      await lookup.goto("/reservations");
      await lookup.getByLabel("Reservation reference").fill(reference ?? "");
      await lookup.getByRole("button", { name: "Look up reservation" }).click();
      await expect(lookup.getByRole("heading", { name: "Reservation saved" })).toBeVisible();
      await expect(lookup.getByText("14:10:00", { exact: true })).toBeVisible();
    } finally {
      await fresh.close();
    }
  });
}

test("extracts a JPEG and saves an image-based reservation", async ({ page }) => {
  await page.goto("/");
  await upload(page, "image-ticket.jpeg");
  await expect(page.getByLabel("Arrival airport", { exact: true })).toHaveValue("AMS");
  await page.getByLabel("Destination", { exact: true }).fill("Fictional Canal Hotel");
  await reviewAndSave(page);
  await expect(page.getByText("6E318", { exact: true })).toBeVisible();
});

test("flags ambiguous fields and requires review again after a correction", async ({ page }) => {
  await page.goto("/");
  await upload(page, "ambiguous-ticket.pdf");
  await expect(page.getByText("Uncertain", { exact: true })).toHaveCount(4);
  await fillFlight(page, "ZZ305", "FRA", "2026-12-10", "14:50");
  await page.getByLabel("Destination", { exact: true }).fill("Fictional Station Hotel");
  const review = page.getByRole("checkbox", { name: "I’ve reviewed", exact: false });
  await review.check();
  await page.getByLabel("Arrival time", { exact: true }).fill("14:51:05.123456");
  await expect(review).not.toBeChecked();
  await reviewAndSave(page);
  await expect(page.getByText("14:51:05.123456", { exact: true })).toBeVisible();
});

test("recovers from unreadable OCR with manual entry on a narrow screen", async ({ page }, info) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await page.screenshot({ path: info.outputPath("mobile-ticket.png"), fullPage: true });
  await upload(page, "unreadable-ticket.png");
  await expect(page.getByRole("status")).toContainText("We couldn’t read this ticket");
  await expect(page.getByText("Missing", { exact: true })).toHaveCount(4);
  await fillFlight(page, "ZZ969", "FCO", "2026-12-19", "21:20");
  await page.getByLabel("Destination", { exact: true }).fill("Fictional Riverside Lodge");
  await page.screenshot({ path: info.outputPath("mobile-review.png"), fullPage: true });
  await reviewAndSave(page);
  await expect(page.getByText("Fictional Riverside Lodge", { exact: true })).toBeVisible();
});

test("manual recovery after a replacement ticket does not reuse the previous booking draft", async ({ page }) => {
  await page.goto("/");
  await upload(page, "scanned-ticket.pdf");
  await page.getByLabel("Destination", { exact: true }).fill("Fictional First Hotel");
  const back = page.getByRole("button", { name: "Back to ticket" });
  const manual = page.getByRole("button", { name: "Enter details manually" });

  await back.click();
  await manual.click();
  await expect(page.getByLabel("Flight number", { exact: true })).toHaveValue("ZZ731");
  await expect(page.getByLabel("Destination", { exact: true })).toHaveValue("Fictional First Hotel");

  await back.click();
  await page.locator("#ticket-file").setInputFiles({
    name: "incomplete.pdf", mimeType: "application/pdf", buffer: Buffer.from("%PDF-1.7\n"),
  });
  await page.getByRole("button", { name: "Extract flight details" }).click();
  await expect(page.getByRole("region", { name: "Upload your flight ticket" }).getByRole("alert"))
    .toContainText("PDF is incomplete or damaged");
  await manual.click();

  for (const name of ["Flight number", "Arrival airport", "Arrival date", "Arrival time", "Destination"]) {
    await expect(page.getByLabel(name, { exact: true })).toHaveValue("");
  }
  await expect(page.getByRole("checkbox", { name: "I’ve reviewed", exact: false })).not.toBeChecked();
});

test("rejects invalid inputs, handles a failed extraction request, and accepts a clean retry", async ({ page }) => {
  await page.goto("/");
  const input = page.locator("#ticket-file");
  const uploadAlert = page.getByRole("region", { name: "Upload your flight ticket" }).getByRole("alert");
  await input.setInputFiles({ name: "fake.txt", mimeType: "text/plain", buffer: Buffer.from("fixture") });
  await expect(uploadAlert).toContainText("Choose a PDF, PNG or JPEG");
  await input.setInputFiles({ name: "broken.pdf", mimeType: "application/pdf", buffer: Buffer.from("%PDF-1.7\ntruncated") });
  await page.getByRole("button", { name: "Extract flight details" }).click();
  await expect(uploadAlert).toContainText("PDF is incomplete or damaged");

  await input.setInputFiles(`${samples}text-ticket.pdf`);
  await page.route("**/api/v1/tickets/extract", (route) => route.fulfill({ status: 503, json: {
    detail: { message: "The local API is unavailable. Try again in a moment." },
  } }), { times: 1 });
  await page.getByRole("button", { name: "Extract flight details" }).click();
  await expect(uploadAlert).toContainText("local API is unavailable");
  await page.route("**/api/v1/tickets/extract", (route) => route.fulfill({ json: { method: "ocr" } }), { times: 1 });
  await page.getByRole("button", { name: "Try extraction again" }).click();
  await expect(uploadAlert).toContainText("We couldn't read the ticket");
  await page.getByRole("button", { name: "Try extraction again" }).click();
  await expect(page.getByRole("heading", { name: "Review your flight details" })).toBeVisible();
  await page.getByLabel("Arrival airport", { exact: true }).fill("AYT1");
  await page.getByRole("button", { name: submitName }).click();
  await expect(page.getByText("Enter a three-letter airport code.")).toBeVisible();
  await expect(page.getByRole("heading", { name: "Reservation saved" })).toHaveCount(0);
  expect((await page.request.post(reservationPath, { data: { reviewed: false } })).status()).toBe(422);
  expect((await page.request.post(reservationPath, { headers: { origin: "https://example.invalid" }, data: {} })).status()).toBe(403);
});

test("recovers the same reservation when its first committed reply is lost", async ({ page }, info) => {
  await page.goto("/");
  await page.screenshot({ path: info.outputPath("desktop-ticket.png"), fullPage: true });
  await page.getByRole("button", { name: "Enter details manually" }).click();
  await fillFlight(page, "ZZ448", "AYT", "2026-12-15", "09:45");
  await page.getByLabel("Destination", { exact: true }).fill("Fictional Terminal Hotel");
  await page.getByRole("checkbox", { name: "I’ve reviewed", exact: false }).check();
  let releaseReply = () => {};
  const holdReply = new Promise<void>((resolve) => { releaseReply = resolve; });
  const outcomes: { key: string | undefined; status: number; reference: string }[] = [];
  await page.route(`**${reservationPath}`, async (route) => {
    const response = await route.fetch();
    const saved = await response.json();
    outcomes.push({ key: route.request().headers()["idempotency-key"], status: response.status(), reference: saved.reference });
    if (outcomes.length === 1) {
      await holdReply;
      await route.fulfill({ status: 504, json: { detail: { message: "The local API did not respond in time. You can try again." } } });
    } else {
      await route.fulfill({ response });
    }
  });
  try {
    await page.getByRole("button", { name: submitName }).click();
    await expect(page.getByRole("button", { name: "Saving reservation…" })).toBeDisabled();
  } finally {
    releaseReply();
  }
  await expect(page.getByRole("region", { name: "Review your flight details" }).getByRole("alert"))
    .toContainText("did not respond in time");
  await page.getByRole("button", { name: submitName }).click();
  await expect(page.getByRole("heading", { name: "Reservation saved" })).toBeVisible();
  expect(outcomes.map(({ status }) => status)).toEqual([201, 200]);
  expect(outcomes[0].key).toBeTruthy();
  expect(outcomes[0].key).toBe(outcomes[1].key);
  expect(outcomes[0].reference).toBe(outcomes[1].reference);
  await page.screenshot({ path: info.outputPath("desktop-confirmation.png"), fullPage: true });
});

test("keeps the health check available from the booking site", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("link", { name: "System status" }).click();
  await expect(page.getByRole("status")).toHaveText("Operational");
  await expect(page.getByText("The API responded and the database is ready.")).toBeVisible();
});
