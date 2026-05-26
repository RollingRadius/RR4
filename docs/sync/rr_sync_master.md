# RR Sync — Master Reference

## What Is This

RR4 (FastAPI + PostgreSQL + Flutter) syncs trip data **one-way** into RR (Flask + Eve + MongoDB).
RR4 is the mobile version of RR — separate servers, separate DBs, same business domain.
All sync is server-side only (FastAPI BackgroundTask). The mobile app never knows RR exists.

---

## Architecture

```
LP/Transporter (Flutter)
       |
       | HTTP
       v
RR4 Backend (FastAPI, port 8000, PostgreSQL)
       |
       | BackgroundTask — after Stage 2 loading slip
       | Bearer token (auto-refreshed every 10 min)
       v
RR Backend (Flask+Eve, port 8042, MongoDB)
```

**Sync is one-way only:** RR4 → RR. RR never writes back to RR4.

---

## RR API Endpoints Used

| Endpoint | When Called | Purpose |
|----------|------------|---------|
| `POST /persons/refresh` | Every 10 min (background) | Get fresh access token |
| `POST /create_trip` | S2 trigger | Create trip + parcel + book vehicle in RR |
| `POST /post_loading_slip` | S2 trigger | Attach loading slip to RR trip |
| `POST /files` | Each doc upload | Upload file bytes → returns RR file `_id` |
| `GET /trips/{id}` | After create_trip | Get rr_trip_number |
| `GET /parcels/{id}` | Before each PATCH | Get fresh ETag |
| `PATCH /parcels/{id}` | S3, S5 | Push bilty (S3) + POD (S5) |
| `GET /cities` | City proxy | Resolve city name → RR ObjectId |

**NOT called by RR4:** `POST /verify_trip_stage` — RR web users manage their own stage verification.

---

## Sync Trigger Points

| RR4 Event | Condition | Action |
|-----------|-----------|--------|
| LP submits Stage 2 | loading slip present + RR_SYNC_ENABLED | BackgroundTask: sync_trip_to_rr() |
| Transporter uploads loading slip | RR_SYNC_ENABLED | BackgroundTask: sync_trip_to_rr() |
| LP submits Stage 3 | Phase 6 | PATCH parcel: bilty + eway bill |
| LP submits Stage 5 | Phase 6 | PATCH parcel: POD |

---

## sync_trip_to_rr() Flow

```
1. Pre-flight: check all 8 required RR IDs
   - load_owner_org.rr_company_id
   - lp_org.rr_company_id
   - vehicle.rr_vehicle_id
   - driver.rr_user_id
   - trip.origin_rr_city_id
   - trip.destination_rr_city_id
   - trip.material_rr_id
   - trip.weight_value + trip.weight_unit
   Any missing → status=failed, log error, stop.

2. POST /create_trip (force_create: true)
   → get rr_trip_id + rr_parcel_id

3. GET /trips/{rr_trip_id} → get rr_trip_number
4. GET /parcels/{rr_parcel_id} → get rr_parcel_etag

5. Store: rr_trip_id, rr_trip_number, rr_parcel_id, rr_parcel_etag
   status = trip_created

6. If s2_loading_slip_url:
   POST /files (multipart) → rr_file_id
   POST /post_loading_slip {trip_id, loading_slip: rr_file_id}
   status = loading_slip_synced
```

---

## rr_sync_status Values

| Status | Meaning |
|--------|---------|
| `not_synced` | Never attempted |
| `trip_created` | Trip + parcel created in RR, loading slip not yet synced |
| `loading_slip_synced` | Full Stage 2 sync complete |
| `bilty_synced` | Stage 3 synced (Phase 6) |
| `pod_synced` | Stage 5 synced (Phase 6) |
| `failed` | Check `rr_sync_error` column |

---

## Stage Mapping: RR4 vs RR

```
RR4 Stage     Document              RR Stage           RR Storage
──────────────────────────────────────────────────────────────────
S1            DL, RC, insurance...  (no equivalent)    Not synced
S2            Loading slip          Loading (stage 4)  trip.trip_documents[]
S3            Bilty + eway bill     DocumentColl (5)   parcel.documents.bilty
                                                       parcel.documents.eway_bill
S4            Diesel receipt        (no equivalent)    Not synced
S5            POD                   Unloading (stage 7) parcel.documents.pod
```

---

## create_trip Payload (what to send)

```python
{
    "consignor_company_id": trip.load_owner_org.rr_company_id,   # REQUIRED
    "vehicle_id":           vehicle.rr_vehicle_id,               # REQUIRED
    "driver_id":            driver.rr_user_id,                   # REQUIRED
    "vehicle_provider_id":  lp_org.rr_company_id,                # REQUIRED
    "pickup_city":          trip.origin_rr_city_id,              # REQUIRED
    "unload_city":          trip.destination_rr_city_id,         # REQUIRED
    "material":             trip.material_rr_id,                 # REQUIRED
    "weight":               float(trip.weight_value),            # REQUIRED
    "weight_unit":          trip.weight_unit,                    # REQUIRED
    "invoice_value":        float(trip.invoice_value or trip.trip_amount or 0),
    "freight_amount":       float(trip.trip_amount or 0),
    "booking_amount":       0.0,
    "back_entry_date":      trip.created_at.date().isoformat(),
    "force_create":         True,                                # ALWAYS
    "human_trip_number":    trip.trip_number,                   # e.g. "RR-90422"
    # Optional:
    "invoice_number":       trip.invoice_number,
    "bilty_number":         int(trip.bilty_number),             # must be int
}
# DO NOT send: transporter_company_id, handled_by
```

---

## ETag Concurrency (important)

All `PATCH /parcels/{id}` requires `If-Match: <etag>` header.
ETag changes after every PATCH. Always re-fetch before patching:
```
GET /parcels/{rr_parcel_id} → fresh _etag
PATCH /parcels/{rr_parcel_id} with If-Match: <etag>
Store new etag from response
```

---

## Token Management

- RR JWT: 15-min access token, 30-day refresh token
- RR4 stores `RR_REFRESH_TOKEN` in `.env` (set once via OTP login on RR)
- Background task refreshes every **10 min** (5-min safety buffer)
- If refresh fails → retry after 60s
- All RR calls use `rr_token_service.get_access_token()`
- Test auth: `Authorization: Basic OTE3NTk3NTE3MTI1OjEyMzQ=` (never expires)

---

## Phase Completion Status

| Phase | Description | Status | Issues |
|-------|-------------|--------|--------|
| 1 | DB migrations (054-058, alembic head=058) | DONE | None |
| 2 | Token service + /api/rr/* proxy endpoints | DONE | .env.docker not updated |
| 3 | Stage 2 multipart + loading slip merge | DONE | None |
| 4 | rr_sync_service.py + BackgroundTask triggers | DONE | 3 bugs (see below) |
| 5 | Vehicle/driver RR ID auto-resolution | PENDING | — |
| 6 | S3 bilty sync + S5 POD sync | PENDING | — |
| 7 | Flutter: city picker, material picker, weight field, invoice_value | PENDING | — |

---

## Known Bugs (to fix before Phase 5)

### Bug 1 — Transporter loading slip never reaches RR
**File:** `backend/app/services/rr_sync_service.py` ~line 130
**Problem:** `trip_created` is wrongly included in the skip list. When transporter uploads a loading slip after S2 (which had no slip), sync fires but immediately returns because status is `trip_created`.

```python
# CURRENT (wrong):
if trip.rr_sync_status in ("trip_created", "loading_slip_synced", "bilty_synced", "pod_synced"):
    return

# FIX:
if trip.rr_sync_status in ("loading_slip_synced", "bilty_synced", "pod_synced"):
    return
```

**Scenario that breaks:**
1. LP submits S2 without loading slip → create_trip → status = `trip_created`
2. Transporter uploads slip → sync fires → sees `trip_created` → skips → slip never sent to RR

---

### Bug 2 — human_trip_number not sent
**File:** `backend/app/services/rr_sync_service.py` payload dict (~line 200)
**Problem:** `human_trip_number` missing from create_trip payload. RR web portal can't trace a trip back to RR4.

```python
# ADD this line to payload:
"human_trip_number": trip.trip_number,   # e.g. "RR-90422"
```

---

### Bug 3 — Token refresh interval too tight + no retry
**File:** `backend/app/services/rr_token_service.py` ~line 25

```python
# CURRENT (wrong):
_REFRESH_INTERVAL_SECONDS = 14 * 60   # 1-min buffer for 15-min token

# FIX:
_REFRESH_INTERVAL_SECONDS = 10 * 60   # 5-min buffer
```

Also add retry logic in `_refresh_loop`:
- If `_do_refresh()` fails → sleep 60s → retry once before waiting full interval
- Without retry: token expires and all RR API calls fail until next scheduled refresh

---

## Phase 5 Plan (next)

1. **Vehicle lookup:** On vehicle creation/trip sync, call `GET /vehicles?where={"rc_number": "<plate>"}` in RR → cache `rr_vehicle_id`
2. **Driver lookup:** Call `GET /users?where={"phone.number": "<10-digit>"}` in RR → cache `rr_user_id`
3. **Org mapping:** Add `rr_company_id` input field in Organization settings UI (LP sets once for their org, LO sets once for theirs)

---

## Phase 6 Plan

**S3 sync (bilty):**
```
POST /files (bilty image) → rr_bilty_file_id
PATCH /parcels/{rr_parcel_id}
  If-Match: <fresh etag>
  Body: {"documents": {"bilty": bilty_number, "bilty_image": rr_bilty_file_id,
                       "eway_bill": {"number": eway_bill_number}}}
```
Consider: also call bilty generation endpoint → creates proper bilty record in RR bilty collection
(satisfies verify_document_collection_stage check)

**S5 sync (POD):**
```
GET /parcels/{rr_parcel_id} → fresh etag
POST /files (POD image) → rr_pod_file_id
PATCH /parcels/{rr_parcel_id}
  If-Match: <fresh etag>
  Body: {"documents": {"pod": rr_pod_file_id}}
```

---

## One-Time Setup Required

Before sync works for any org:

| Step | Who | Action |
|------|-----|--------|
| 1 | Admin/LP | Set `rr_company_id` on LP org in RR4 settings (copy from RR portal) |
| 2 | Admin/LO | Set `rr_company_id` on Load Owner org in RR4 settings |
| 3 | Phase 5 | `rr_vehicle_id` + `rr_user_id` auto-resolved — no manual action |
| 4 | Server | Set `RR_REFRESH_TOKEN` + `RR_SYNC_ENABLED=true` in .env, restart backend |

---

## Bilty Note (important for Phase 6)

RR has two separate bilty concepts:
1. `parcel.documents.bilty` — just the number string (set via PATCH, visible in parcel)
2. `bilty` collection — full record with generated PDF, uses company token credits

`verify_document_collection_stage` checks the **bilty collection**, not `parcel.documents.bilty`.
If RR web user needs to verify DocumentCollection stage, a proper bilty record must exist.
Option: after PATCHing bilty number, also call RR's bilty generation endpoint (zero RR changes needed).

---

## Cross-Reference: Finding the Same Trip in Both Systems

| Field | RR4 column | RR field |
|-------|-----------|---------|
| RR4 trip number | `trips.trip_number` (e.g. "RR-90422") | `trips.human_trip_number` |
| RR trip number | `trips.rr_trip_number` (e.g. "rr1235") | `trips.trip_number` |
| RR trip MongoDB ID | `trips.rr_trip_id` | `trips._id` |
| RR parcel MongoDB ID | `trips.rr_parcel_id` | `parcels._id` |
