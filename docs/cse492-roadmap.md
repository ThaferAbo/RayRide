# Proposed CSE492 work

Use `005aef6` as the CSE491 behavior baseline. The roadmap is a proposal for the next semester. The order gives the team a small, testable release even if integrations take longer than expected.

| Order | Proposed work | Evidence to collect before moving on |
| --- | --- | --- |
| 1. Reproduce and observe | Run the open pilot sessions and a clean setup on a second development machine. Record usability problems, then prioritize fixes by their impact on completing the booking flow. | Complete NFR-2 and NFR-5 with actual notes, exact revisions, setup commands and repeatable fixes for any blockers. [Protocols](phase4-manual-protocols.md) |
| 2. Improve extraction | Extend separately labeled fixtures with permitted layouts, languages, connections and capture conditions. Focus on column association, clocks with qualifiers, and multiple candidate flights. Keep manual review mandatory. | Report correct, wrong, uncertain, missing and confidently filled unlabeled fields on both preserved corpora and a new held-out set. Check latency and fallback behavior on the target machines. |
| 3. Add authenticated reservations | Define traveler and operator permissions, reference visibility, retention, and safe deletion. Plan migrations separately from application startup. | Tests show that each role can access only its records and operations. Exercise a migration and restore on a copy of synthetic data. |
| 4. Evaluate legacy integration | Inventory the Flutter clients and actual .NET routes, including data and authentication assumptions. Select one sandbox workflow, such as showing a simulated reservation to an operator, and connect it through a documented boundary. | Contract and end-to-end tests cover both sides using fictional records. Keep the existing standalone demo runnable. |
| 5. Prepare a staging demo | Add CI coverage for the supported environments, test keyboard and screen-reader journeys, then stage with synthetic data, managed secrets and agreed logging. Decide whether trip status or a sandbox dispatch demonstration belongs in the next release. | Evidence includes a clean deployment, rollback, backup/restore check, and a repeatable acceptance run. |

Real providers, payment, live flight data and production deployment require separate decisions on scope, permissions and data handling. Start with a simulated or sandbox interface if the team pursues any of them.
