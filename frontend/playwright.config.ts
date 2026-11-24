import { defineConfig, devices } from "@playwright/test";
import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";

const backend = "http://127.0.0.1:8131";
const frontend = "http://127.0.0.1:3131";
const database = fileURLToPath(new URL(`./test-results/reservations-${randomUUID()}.sqlite3`, import.meta.url));

export default defineConfig({
  testDir: "./tests/e2e",
  outputDir: "./test-results/browser",
  timeout: 35_000,
  expect: { timeout: 10_000 },
  forbidOnly: Boolean(process.env.CI),
  reporter: "list",
  use: { ...devices["Desktop Chrome"], baseURL: frontend, trace: "retain-on-failure" },
  webServer: [
    {
      cwd: fileURLToPath(new URL("../api/", import.meta.url)),
      command: "uv run --locked uvicorn app.main:app --host 127.0.0.1 --port 8131",
      env: { RAYRIDE_DATABASE_PATH: database },
      url: `${backend}/health`, reuseExistingServer: false, timeout: 60_000,
    },
    {
      command: "npm start -- --port 3131",
      env: { RAYRIDE_API_URL: backend, NEXT_TELEMETRY_DISABLED: "1" },
      url: `${frontend}/status`, reuseExistingServer: false, timeout: 60_000,
    },
  ],
});
