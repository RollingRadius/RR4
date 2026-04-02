# LP Worker Access & System Behaviour

## Who is an LP Worker?

A **Logistic Partner Worker** (`logistic_partner_worker`) is a staff member who belongs to a Logistic Partner company. They are added through a join-request flow and must be approved by the company owner before gaining access.

---

## How a Worker Joins a Company

1. During sign-up the user proceeds through the standard signup form.
2. On the **Company Selection** screen they choose **"Join Existing Company"**.
3. The company search is **filtered** — only Logistic Partner companies appear (Load Owner companies are hidden).
4. They select their company and submit. Their status is set to **Pending** (`pending_user`).
5. The LP Owner reviews the request in the **Worker Requests** section (`/worker-requests`) and either approves or rejects it.
6. Once approved the worker can log in and is routed to `/lp-worker/home`.

> **Note:** Role selection (`logistic_partner_worker`) happens during the company search/join step, not as a separate signup screen.

---

## Auth Routing After Login

| Role key | Route |
|---|---|
| `logistic_partner` | `/dashboard` |
| `logistic_partner_worker` | `/lp-worker/home` |
| `load_owner` | `/load-owner/dashboard` |
| `load_owner_worker` | `/lo-worker/home` |
| `pending_user` | Blocked — shows Pending Approval dialog |

---

## Worker Dashboard

**Screen:** `LogisticPartnerWorkerDashboard`
**Route:** `/lp-worker/home`

### Bottom Navigation (2 tabs)

| Tab | Icon | Content |
|---|---|---|
| DASHBOARD | `dashboard_rounded` | Active trips + notifications |
| PROFILE | `person_outline` | User info + logout |

### Dashboard Tab

- Welcome message: *"Welcome back, [firstName]"* with **Logistic Partner Worker** role badge
- **Active Trips** section with live indicator — shows `ongoing` and `pending` trips
- Auto-refreshes every **30 seconds** in the background (silent refresh, no loading spinner)
- Empty state: *"No active trips — You will be notified when a new trip is assigned"*
- Error state with retry button

### Profile Tab

- User avatar (initials), full name, email, role badge
- Help & Support link
- Logout button with confirmation dialog

---

## Worker Dashboard vs Owner Dashboard

| Feature | LP Owner | LP Worker |
|---|---|---|
| View active trips | Yes | Yes |
| Create new trips | Yes | No |
| Fulfill load requirements | Yes | No |
| Worker Requests section | Yes | No |
| LP Workers leaderboard | Yes | No |
| Notification types | `worker_request` | `new_work`, `trip_complete` |
| Stage claim override | Can bypass all claims | Subject to claim rules |
| Bottom nav tabs | 5 (Dashboard, Loads, My Trips, Docs, Profile) | 2 (Dashboard, Profile) |

---

## Notifications

- Workers receive **`new_work`** notifications when a new trip is created for their company.
- Workers receive **`trip_complete`** notifications when a trip is completed.
- Workers do **not** see `worker_request` notifications — those are owner-only.
- Notification badge counts unread `new_work` and `trip_complete` notifications only. Shows `99+` if count exceeds 99.
- Notifications are delivered via **WebSocket** (`NotificationWsService`) with REST API fallback (`GET /api/notifications`).
- Mark as read: `PATCH /api/notifications/{id}/read`
- Mark all read: `PATCH /api/notifications/read-all`

---

## Trip Stage Access & Locking

Trips progress through 4 stages. Workers process these stages.

### Claim System (First-Come, First-Served)

When a worker taps a stage to start working on it:

1. The app calls **`POST /api/trips/{id}/claim-stage/{1-4}`**.
2. If the stage is **unclaimed** → claim is granted and the worker enters the form.
3. If the stage is **claimed by another worker** (claim still fresh) → blocked with *"Stage N is currently being worked on by another worker."*
4. If the stage has already been **submitted by another worker** → permanently blocked with *"Stage N has already been completed by another worker."*

### What Happens When a Worker Leaves

| Scenario | Claim | Draft |
|---|---|---|
| Worker presses Back | Released immediately | Preserved |
| Worker closes app / crashes / logs out | Auto-expires after 30 minutes | Preserved |
| Worker submits the stage | Cleared automatically | Cleared |

After a claim is released or expires, any other worker can open the stage and will see the **previously saved draft** to continue from where the last worker left off.

### Owner Override

LP Owners (`logistic_partner`) bypass all claim checks. They can open, edit, and re-submit any stage at any time regardless of who claimed or submitted it.

### Stage Flow Rules

- Stage 2 requires Stage 1 to be complete first.
- Stage 3 requires Stage 2 to be complete first.
- Stage 4 requires Stage 3 to be complete first.
- Workers can work on **different stages of different trips** simultaneously — locking is per-trip per-stage.

---

## Draft System

All stage forms **auto-save a draft** to the server as the worker types (debounced — saves ~1.5 seconds after the last keystroke). Draft is stored in the `draft_data` field on the trip record.

- Drafts survive navigating away, closing the app, or losing connection.
- When any worker opens a stage, the form pre-fills from the saved draft if one exists.
- Draft is cleared when the stage is successfully submitted.

---

## Stage Credit (Who Gets the Points)

The worker who **submits** a stage is recorded in `s1_submitted_by` / `s2_submitted_by` / `s3_submitted_by` / `s4_submitted_by`. This is the worker who receives the credit for that stage, regardless of who started the draft.

---

## Worker Requests Management (Owner Side)

**Route:** `/worker-requests`
**Accessible by:** LP Owner and Load Owner only

The Worker Requests screen has two tabs:

| Tab | Content |
|---|---|
| Pending | Join requests awaiting approval — Accept / Reject actions |
| Accepted | Active workers with role badges and approval dates |

**Endpoints:**
- `GET /api/organization/worker-requests` — pending requests
- `GET /api/organization/employees?status_filter=active` — accepted workers

---

## Load Owner Worker (`load_owner_worker`)

A parallel worker role exists for Load Owner companies (`load_owner_worker`). The signup and join flow mirrors the LP Worker flow but filters to Load Owner companies only.

> **Status:** The Load Owner Worker dashboard (`/lo-worker/home`) is currently a **Coming Soon** placeholder. No functionality is implemented yet.
