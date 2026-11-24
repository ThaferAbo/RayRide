# Meeting 5 demo checklist

**27 November 2026 · CSE491 Group 4**

## Before presenting

- Use the two terminals in the [README](../README.md#run-the-cse491-prototype). Verify **Operational** on [System status](http://127.0.0.1:3000/status) and confirm that the local Tesseract executable lists `eng`.
- Confirm the checkout contains `samples/scanned-ticket.pdf` and `samples/unreadable-ticket.png`. Use only the fictional sample data in the demo.
- Open the [booking page](http://127.0.0.1:3000). Tell the audience the transfer is simulated and SQLite stores the reviewed details locally.

## Integrated demo

1. Upload `scanned-ticket.pdf`. Confirm that the suggested details are `ZZ731`, `AYT`, `2026-12-03`, and `14:10` local time.
2. Enter `Antalya city center`, leave the review checkbox unchecked, and attempt to save. Show the review validation message. Check the box and create the simulated reservation.
3. Point out **Simulation only**, the reference, and the saved details. Reload the confirmation page, then use **Find a reservation** with the same reference.
4. Start again with `unreadable-ticket.png`. Show the missing fields, enter `ZZ969`, `FCO`, `2026-12-19`, `21:20`, and `Fictional Riverside Lodge`. Review and save. If time permits, use `ambiguous-ticket.pdf` to show uncertainty and how editing clears a prior review.

## Report at the meeting

- Lead with the integrated flow and the loss-of-response retry behavior. Use the [implementation log](implementation-log.md) for test evidence and the limits of the synthetic OCR measurement.
- State which checks ran on the demonstration machine and whether hosted CI has run by the meeting. Pilot usability and second-machine setup are Phase 4 evidence.
- For the final report, retain the API and browser results, add the Phase 4 acceptance evidence, record actual contributions and attribution, and turn the two demo paths into the final presentation walkthrough.
