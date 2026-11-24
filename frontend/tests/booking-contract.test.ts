import assert from "node:assert/strict";
import { test } from "node:test";
import { validateTrip } from "../lib/booking-contract.ts";

const trip = {
  flight_number: "ZZ731", arrival_airport: "AYT", arrival_date: "2028-02-29",
  arrival_local_time: "14:10:00.123456", destination: "Fictional hotel",
};

test("validates real calendar dates without converting arrival time", () => {
  for (const date of ["2026-02-30", "2027-04-31", "2100-02-29", "0000-01-01", "2028-13-01"]) {
    assert.equal(validateTrip({ ...trip, arrival_date: date }, true).arrival_date, "Enter a valid arrival date.");
  }
  assert.deepEqual(validateTrip(trip, true), {});
  assert.deepEqual(validateTrip({ ...trip, arrival_date: "2000-02-29" }, true), {});
  assert.ok(validateTrip({ ...trip, arrival_local_time: "14:10+03:00" }, true).arrival_local_time);
});
