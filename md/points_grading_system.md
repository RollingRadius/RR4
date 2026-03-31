# Points Grading System

## Overview

Points are awarded **per individual item** completed within a stage — not per stage completion. Every checkbox ticked, every text field filled, and every document uploaded earns **1 point** for the worker who submitted that stage.

Credit goes to the worker recorded in `sN_submitted_by` for that stage.

---

## Stage 1 — Truck Detail Registration (Max 13 pts)

| # | Item | Type | Points |
|---|---|---|---|
| 1 | Driver Name | Text field | 1 |
| 2 | Driver Phone | Text field | 1 |
| 3 | Driving License Number | Text field | 1 |
| 4 | Aadhaar Number | Text field | 1 |
| 5 | Driving License Document | Upload | 1 |
| 6 | Aadhaar Document | Upload | 1 |
| 7 | RC (Registration Certificate) | Upload | 1 |
| 8 | Insurance Document | Upload | 1 |
| 9 | Pollution Certificate | Upload | 1 |
| 10 | Fitness Certificate | Upload | 1 |
| 11 | PAN Document | Upload | 1 |
| 12 | Tax Declaration Document | Upload | 1 |
| 13 | Cancelled Cheque | Upload | 1 |

**Stage 1 Maximum: 13 points**

---

## Stage 2 — Pre-Arrival Compliance Check (Max 5 pts)

| # | Item | Type | Points |
|---|---|---|---|
| 1 | Specs Verified | Checkbox | 1 |
| 2 | Documents Verified | Checkbox | 1 |
| 3 | Driver Documents Valid | Checkbox | 1 |
| 4 | Entry Permission Issued | Checkbox | 1 |
| 5 | Loading Slip Uploaded | Upload | 1 |

**Stage 2 Maximum: 5 points**

---

## Stage 3 — Truck Arrival at Factory (Max 10 pts)

| # | Item | Type | Points |
|---|---|---|---|
| 1 | Driver Parked | Checkbox | 1 |
| 2 | Docs Submitted | Checkbox | 1 |
| 3 | Security Verified | Checkbox | 1 |
| 4 | Driver Exited Cabin | Checkbox | 1 |
| 5 | Wheel Stoppers Applied | Checkbox | 1 |
| 6 | Safety Gear Worn | Checkbox | 1 |
| 7 | Empty Truck Weight Entered | Weight field | 1 |
| 8 | Loaded Truck Weight Entered | Weight field | 1 |
| 9 | Bilty Uploaded | Upload | 1 |
| 10 | Material Documents Uploaded | Upload | 1 |

**Stage 3 Maximum: 10 points**

---

## Stage 4 — Truck Exit From Factory (Max 5 pts)

| # | Item | Type | Points |
|---|---|---|---|
| 1 | Truck Moved | Checkbox | 1 |
| 2 | Security Verified | Checkbox | 1 |
| 3 | Bilty Checked | Checkbox | 1 |
| 4 | Weight Checked | Checkbox | 1 |
| 5 | Material Checked | Checkbox | 1 |

**Stage 4 Maximum: 5 points**

---

## Total Points Per Trip

| Stage | Max Points |
|---|---|
| Stage 1 | 13 |
| Stage 2 | 5 |
| Stage 3 | 10 |
| Stage 4 | 5 |
| **Total per trip** | **33** |

---

## Leaderboard

The leaderboard is visible to the **LP Owner only** and can be filtered by **Daily** or **Monthly** period.

### Ranking

Workers are ranked by **total points** (descending). Ties are broken by trips completed (descending), then alphabetically by name.

### Display

Each worker card shows:
- **Total points** (large, right side)
- **Trips completed** (number of trips where the worker submitted Stage 4)
- **Per-stage breakdown** — `S1: X/13  S2: X/5  S3: X/10  S4: X/5`
  - Orange pill = worker has earned points in that stage
  - Grey pill = no points yet in that stage for the current period

### Podium

The top 3 workers are shown in a podium view (gold / silver / bronze) with their total points displayed beneath their name.

---

## Important Rules

- **Only the submitting worker earns points** — drafts started by one worker and submitted by another give all points to the submitter.
- **Partial fills count** — if a worker fills 7 out of 13 Stage 1 items, they earn 7 points for that trip's Stage 1.
- **Unchecked checkboxes = 0 points** — a checkbox that is left unchecked does not earn a point even if the stage is submitted.
- **Owner submissions count** — LP Owners also appear on the leaderboard and earn points for stages they personally submit.
- **Points reset per period** — daily view shows today's points only; monthly view shows the full month's total.
