import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Page, type TestInfo } from "@playwright/test";
import { fileURLToPath } from "node:url";

const samples = fileURLToPath(new URL("../../../samples/", import.meta.url));
const submit = "Create simulated reservation";

async function auditAccessibility(page: Page) {
  const { violations } = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"]).analyze();
  expect(violations.map(({ id, nodes }) => ({ id, targets: nodes.map(({ target }) => target) }))).toEqual([]);
}

async function auditReflow(page: Page) {
  for (const width of [320, 390, 768, 1280]) {
    await page.setViewportSize({ width, height: 900 });
    await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth), {
      message: `Page has horizontal overflow at ${width}px`,
    }).toBeLessThanOrEqual(width);
  }
}

async function capture(page: Page, info: TestInfo, name: string, width: number, section?: string) {
  if (process.env.RAYRIDE_CAPTURE_EVIDENCE !== "1") return;
  await page.setViewportSize({ width, height: 960 });
  await page.evaluate(async () => { await document.fonts.ready; });
  const path = info.outputPath(name);
  if (section) await page.getByRole("region", { name: section }).screenshot({ path, animations: "disabled" });
  else await page.screenshot({ path, fullPage: true, animations: "disabled" });
}

async function upload(page: Page, file: string) {
  await page.locator("#ticket-file").setInputFiles(`${samples}${file}`);
  await page.getByRole("button", { name: "Extract flight details" }).click();
  await expect(page.getByRole("heading", { name: "Review your flight details" })).toBeVisible();
}

test("keyboard navigation retains a meaningful focus through review and back", async ({ page }) => {
  await page.goto("/");
  const manual = page.getByRole("button", { name: "Enter details manually" });
  await page.locator("#ticket-file").focus();
  await page.keyboard.press("Tab");
  await expect(manual).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(page.getByRole("heading", { name: "Review your flight details" })).toBeFocused();
  await page.keyboard.press("Tab");
  await expect(page.getByLabel("Flight number", { exact: true })).toBeFocused();

  await page.getByRole("button", { name: submit }).focus();
  await page.keyboard.press("Enter");
  await expect(page.getByLabel("Flight number", { exact: true })).toBeFocused();
  await expect(page.getByLabel("Flight number", { exact: true })).toHaveAccessibleDescription("Enter a flight number such as ZZ731.");

  await page.getByRole("button", { name: "Back to ticket" }).focus();
  await page.keyboard.press("Enter");
  await expect(page.getByRole("heading", { name: "Upload your flight ticket" })).toBeFocused();
  await page.keyboard.press("Tab");
  await expect(page.locator("#ticket-file")).toBeFocused();
});

test("rejects multiple dropped files and oversize uploads before making a request", async ({ page }) => {
  await page.goto("/");
  const uploads: string[] = [];
  page.on("request", (request) => {
    if (request.method() === "POST") uploads.push(request.url());
  });
  const files = await page.evaluateHandle(() => {
    const transfer = new DataTransfer();
    transfer.items.add(new File(["synthetic one"], "one.pdf", { type: "application/pdf" }));
    transfer.items.add(new File(["synthetic two"], "two.pdf", { type: "application/pdf" }));
    return transfer;
  });
  await page.locator(".dropzone").dispatchEvent("drop", { dataTransfer: files });
  const panel = page.getByRole("region", { name: "Upload your flight ticket" });
  await expect(panel.getByRole("alert")).toContainText("one ticket at a time");
  await page.locator("#ticket-file").setInputFiles({
    name: "oversize.pdf", mimeType: "application/pdf", buffer: Buffer.alloc(10 * 1024 * 1024 + 1),
  });
  await expect(panel.getByRole("alert")).toContainText("no larger than 10 MiB");
  await expect(panel.getByRole("button", { name: "Extract flight details" })).toHaveCount(0);
  expect(uploads).toEqual([]);
});

test("report evidence and accessibility on upload, review and persisted confirmation", async ({ page }, info) => {
  await page.goto("/");
  await auditReflow(page);
  await auditAccessibility(page);
  await capture(page, info, "report-01-upload.png", 1280);

  await upload(page, "ambiguous-ticket.pdf");
  await expect(page.getByText("Uncertain", { exact: true })).toHaveCount(4);
  await auditReflow(page);
  await page.setViewportSize({ width: 390, height: 900 });
  await auditAccessibility(page);
  await capture(page, info, "report-02-review.png", 390, "Review your flight details");

  await page.getByLabel("Flight number", { exact: true }).fill("ZZ305");
  await page.getByLabel("Arrival airport", { exact: true }).fill("FRA");
  await page.getByLabel("Arrival date", { exact: true }).fill("2026-12-10");
  await page.getByLabel("Arrival time", { exact: true }).fill("14:50");
  await page.getByLabel("Destination", { exact: true }).fill("Fictional Conference Hotel");
  await page.getByRole("checkbox", { name: "I’ve reviewed", exact: false }).check();
  await page.getByRole("button", { name: submit }).click();
  await expect(page.getByRole("heading", { name: "Reservation saved" })).toBeVisible();
  await auditReflow(page);
  await auditAccessibility(page);
  const response = await page.reload();
  expect(response?.headers()["cache-control"]).toContain("no-store");
  expect(response?.headers()["referrer-policy"]).toBe("no-referrer");
  await expect(page.getByText("Fictional Conference Hotel", { exact: true })).toBeVisible();
  await capture(page, info, "report-03-confirmation.png", 1280);
});

test("report evidence and accessibility on unreadable ticket fallback", async ({ page }, info) => {
  await page.setViewportSize({ width: 390, height: 900 });
  await page.goto("/");
  await upload(page, "unreadable-ticket.png");
  await expect(page.getByRole("status")).toContainText("We couldn’t read this ticket");
  await expect(page.getByText("Missing", { exact: true })).toHaveCount(4);
  await auditAccessibility(page);
  await capture(page, info, "report-04-manual-fallback.png", 390, "Review your flight details");
});
