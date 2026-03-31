# LP Worker Access & System Behaviour

## Who is an LP Worker?

A **Logistic Partner Worker** (`logistic_partner_worker`) is a staff member who belongs to a Logistic Partner company. They are added to the company through a join-request flow and must be approved by the company owner before gaining access.

---

## How a Worker Joins a Company

1. During sign-up the user selects **"Join as Worker"** and picks the role `logistic_partner_worker`.
2. They search for their company — the search is **filtered** so only Logistic Partner companies appear (Load Owner companies are hidden).
3. They send a join request. Their status is set to **Pending**.
4. The LP Owner reviews the request in the **Worker Requests** section and either approves or rejects it.
5. Once approved the worker can log in and access the dashboard.

---

## Worker Dashboard vs Owner Dashboard

| Feature | LP Owner | LP Worker |
|---|---|---|
| View active trips | Yes | Yes |
| Create new trips | Yes | No |
| See load requirements / fulfill loads | Yes | No |
| Worker Requests section | Yes (sidebar + notifications) | No |
| Notifications | `worker_request` type | `new_work` type only |
| Stage locking controls | Can always re-edit any stage | Subject to claim rules |



---

## Notifications

- When an LP Owner **confirms fulfillment** and creates a trip, all LP Workers in the same company receive a `new_work` notification: *"Trip RR-XXXXX has been created: Origin → Destination. Please check and begin stage processing."*
- Workers do **not** see `worker_request` notifications. Those are owner-only.
- Notification badge on the worker's top bar counts unread `new_work` notifications only.

---

## Trip Stage Access & Locking

Trips progress through 4 stages. Workers process these stages.

### Claim System (First-Come, First-Served)

When a worker taps a stage to start working on it:

1. The app calls **`POST /api/trips/{id}/claim-stage/{1-4}`**.
2. If the stage is **unclaimed** → the claim is granted and the worker enters the form.
3. If the stage is **claimed by another worker** (and the claim is still fresh) → the worker is blocked with the message *"Stage N is currently being worked on by another worker."*
4. If the stage has already been **submitted by another worker** → permanently blocked with *"Stage N has already been completed by another worker."*

### What Happens When a Worker Leaves

| Scenario | Claim | Draft |
|---|---|---|
| Worker presses Back | Released immediately | Preserved |
| Worker closes the app / crashes / logs out | **Auto-expires after 30 minutes** | Preserved |
| Worker submits the stage | Cleared automatically | Cleared |

After the claim is released or expires, any other worker can open the stage and will see the **previously saved draft** so they can continue from where the last worker left off.

### Owner Override

LP Owners (`logistic_partner`) bypass all claim checks. They can open, edit, and re-submit any stage at any time regardless of who claimed or submitted it.

### Stage Flow Rules

- Stage 2 requires Stage 1 to be complete first.
- Stage 3 requires Stage 2 to be complete first.
- Stage 4 requires Stage 3 to be complete first.
- Workers can work on **different stages of different trips** simultaneously — locking is per-trip per-stage.

---

## Draft System

All stage forms **auto-save a draft** to the server as the worker types (debounced — saves ~1.5 seconds after the last keystroke). The draft is stored in the `draft_data` field on the trip record.

- Drafts survive the worker navigating away, closing the app, or losing connection.
- When any worker opens a stage, the form pre-fills from the saved draft if one exists.
- The draft is cleared when the stage is successfully submitted.

---

## Stage Credit (Who Gets the Points)

The worker who **submits** a stage is recorded in `s1_submitted_by` / `s2_submitted_by` / `s3_submitted_by` / `s4_submitted_by`. This is the worker who receives the points credit for that stage, regardless of who started the draft.
