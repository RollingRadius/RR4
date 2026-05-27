# RR Sync — Master Reference

## What Is This

RR4 (FastAPI + PostgreSQL + Flutter) syncs trip data **one-way** into RR (Flask + Eve + MongoDB).
RR4 is the mobile version of RR — separate servers, separate DBs, same business domain.
All sync is server-side only (FastAPI BackgroundTask). The mobile app triggers it via a sync button.

---

## Architecture

```
LP (Flutter) taps sync button (top-right on LP Dashboard)
       |
       v
RrSyncSheet (bottom sheet) — GET /api/rr/sync/ready
       | Shows "Ready to Sync" list + "Uploads Incomplete" warning list
       |
       | LP taps a trip
       v
_RrLoginDialog — LP enters RR username + password
       | POST /api/rr/auth/login → proxies to RR GET /persons/authenticate
       | Returns {token}
       |
       | POST /api/rr/sync/trip/{trip_id}  body: {rr_token}
       v
RR4 Backend (FastAPI, port 8000, PostgreSQL)
       |
       | BackgroundTask: sync_all_to_rr(trip_id, rr_token)
       | Uses LP's own RR token for this sync
       v
RR Backend (Flask+Eve, port 8042, MongoDB)
```

**Sync is one-way only:** RR4 → RR. RR never writes back to RR4.
**No auto-triggers:** `trips.py` stage submit functions have zero sync calls.
**Per-trip login:** LP enters RR credentials once per trip sync. Token is never stored.
**Bulk sync** (`POST /api/rr/sync/bulk`): uses global `RR_REFRESH_TOKEN` (service account). LP dashboard only.
**TripStagesScreen AppBar** also has a sync button (secondary path, same login flow, syncs current trip directly).

---

## Route Prefix — CRITICAL

All RR proxy endpoints are registered at `/api/rr/` (NOT `/api/v1/rr/`).
Backend: `app.include_router(rr_sync.router, prefix="/api/rr")`

| Endpoint | Description |
|----------|-------------|
| `POST /api/rr/auth/login` | Proxy to RR Basic Auth → returns `{token}` |
| `GET /api/rr/cities?q=` | Public proxy — no auth to RR (city name → ObjectId) |
| `GET /api/rr/materials?q=` | Live proxy to RR `/material_types` — public, no auth to RR |
| `POST /api/rr/sync/trip/{id}` | body `{rr_token}` — BackgroundTask single-trip sync |
| `GET /api/rr/sync/ready` | Lists ready + incomplete trips for LP |
| `GET /api/rr/sync/status/{id}` | Current sync status for one trip |
| `POST /api/rr/sync/bulk` | Bulk sync using global `RR_REFRESH_TOKEN` |

---

## RR API Endpoints Used

| Endpoint | When Called | Purpose |
|----------|------------|---------|
| `POST /persons/refresh` | Every 10 min (background) | Get fresh access token |
| `GET /vehicles?where={rc_number}` | Phase 5 resolve | Look up rr_vehicle_id by plate |
| `GET /users?where={phone.number}` | Phase 5 resolve | Look up rr_user_id by phone |
| `POST /create_trip` | First sync (no rr_parcel_id) | Create trip + parcel + book vehicle in RR |
| `POST /post_loading_slip` | Loading slip sync | Attach loading slip to RR trip |
| `POST /files` | Each doc upload | Upload file bytes → returns RR file `_id` |
| `GET /trips/{id}` | After create_trip | Get rr_trip_number + etag |
| `GET /parcels/{id}` | Before each PATCH | Get fresh ETag |
| `PATCH /parcels/{id}` | S3 and S5 | Push bilty/weight/material (S3) + POD (S5) |
| `PATCH /trips/{id}` | S3 bilty photo | Append to trip_documents array |
| `GET /cities` | City proxy | Public endpoint — no auth required |
| `GET /material_types` | Material type proxy | Public endpoint — no auth required |

**NOT called by RR4:** `POST /verify_trip_stage` — RR web users manage their own stage verification.

---

## sync_all_to_rr() Flow

```
1. Fetch trip from DB. If not found → return.

2. If no rr_parcel_id (trip not yet in RR):
   a. _try_resolve_rr_ids:
      - GET /vehicles?where={"rc_number": plate} → cache vehicle.rr_vehicle_id
      - GET /users?where={"phone.number": 10digit} → cache driver.rr_user_id
   b. Pre-flight: check 8 required IDs:
      load_owner_org.rr_company_id, lp_org.rr_company_id,
      vehicle.rr_vehicle_id, driver.rr_user_id,
      origin_rr_city_id, destination_rr_city_id, material_rr_id,
      weight_value + weight_unit
      → Any missing: status=failed, rr_sync_error=<list>, return
   c. POST /create_trip → rr_trip_id + rr_parcel_id
   d. GET /trips/{rr_trip_id} → rr_trip_number
   e. GET /parcels/{rr_parcel_id} → rr_parcel_etag
   f. status = trip_created

3. If s2_loading_slip_url exists and status == trip_created:
   - _upload_file(s2_loading_slip_url) → rr_file_id
   - POST /post_loading_slip {trip_id: rr_trip_id, loading_slip: rr_file_id}
   - status = loading_slip_synced

4. If S3 data exists and status not in (bilty_synced, pod_synced):
   - _sync_stage3:
     - Re-fetch etag: GET /parcels/{rr_parcel_id}
     - PATCH /parcels/{rr_parcel_id} with If-Match: <etag>
       Body: documents.bilty (s3_bilty_number),
             documents.weight_receipt.photos (s3_loaded_weight_slip_url uploaded),
             documents.consignor_invoice.photos (first 2 of s3_material_doc_urls)
     - Store new etag
     - status = bilty_synced
   - If s3_bilty_url: _attach_bilty_photo_to_trip:
     - GET /trips/{rr_trip_id} → current etag + trip_documents array
     - Upload bilty photo → rr_bilty_file_id
     - PATCH /trips/{rr_trip_id} with appended {document: "Bilty", photos: [{photo: rr_bilty_file_id}]}

5. If s5_pod_url exists and status != pod_synced:
   - _sync_stage5:
     - Re-fetch etag: GET /parcels/{rr_parcel_id}
     - Upload POD → rr_pod_file_id
     - PATCH /parcels/{rr_parcel_id} Body: documents.pod.photos [{photo: rr_pod_file_id}]
     - status = pod_synced
```

---

## rr_sync_status Values

| Status | Meaning |
|--------|---------|
| `not_synced` | Never attempted |
| `trip_created` | Trip + parcel created in RR, loading slip not yet synced |
| `loading_slip_synced` | S2 full sync complete |
| `bilty_synced` | S3 synced (bilty + weight receipt + material docs) |
| `pod_synced` | S5 synced (POD) — terminal success state |
| `failed` | Check `rr_sync_error` column |

---

## Stage Mapping: RR4 vs RR

```
RR4 Stage     Document                     RR Destination
──────────────────────────────────────────────────────────────────────────────
S1            DL, RC, insurance...         Not synced (RR4 only)
S2            Loading slip                 trip.trip_documents[] (post_loading_slip)
S3            Bilty number                 parcel.documents.bilty (string)
              Bilty photo                  trips/{id}.trip_documents[{document:"Bilty"}]
              Loaded weight slip           parcel.documents.weight_receipt.photos
              Material docs (first 2)      parcel.documents.consignor_invoice.photos
S4            Diesel receipt               Not synced (RR4 only)
S5            POD                          parcel.documents.pod.photos
```

---

## create_trip Payload

```python
{
    "consignor_company_id": load_owner_org.rr_company_id,   # REQUIRED
    "vehicle_id":           vehicle.rr_vehicle_id,           # REQUIRED
    "driver_id":            driver.rr_user_id,               # REQUIRED
    "vehicle_provider_id":  lp_org.rr_company_id,            # REQUIRED
    "pickup_city":          trip.origin_rr_city_id,          # REQUIRED
    "unload_city":          trip.destination_rr_city_id,     # REQUIRED
    "material":             trip.material_rr_id,             # REQUIRED
    "weight":               float(trip.weight_value),        # REQUIRED
    "weight_unit":          trip.weight_unit,                # REQUIRED
    "invoice_value":        float(trip.invoice_value or trip.trip_amount or 0),
    "freight_amount":       float(trip.trip_amount or 0),
    "booking_amount":       0.0,
    "back_entry_date":      trip.created_at.date().isoformat(),
    "force_create":         True,                            # ALWAYS
    "human_trip_number":    trip.trip_number,               # e.g. "RR-90422"
    # Optional:
    "invoice_number":       trip.invoice_number,
    "bilty_number":         int(trip.bilty_number),         # must be int
}
# DO NOT send: transporter_company_id, handled_by
```

---

## ETag Concurrency

All `PATCH /parcels/{id}` and `PATCH /trips/{id}` require `If-Match: <etag>` header.
ETag changes after every PATCH. Always re-fetch before patching:
```
GET /parcels/{rr_parcel_id} → fresh _etag
PATCH /parcels/{rr_parcel_id} with If-Match: <etag>
Store new etag in trip.rr_parcel_etag
```

---

## Token Management

- RR JWT: 15-min access token, 30-day refresh token
- RR4 stores `RR_REFRESH_TOKEN` in `.env` (set once via OTP login on RR) — used for bulk sync only
- Background task refreshes every **10 min** (5-min safety buffer)
- If refresh fails → retry after 60s
- Per-trip syncs: LP provides their own RR token via `_RrLoginDialog` — never stored
- Test auth: `Authorization: Basic OTE3NTk3NTE3MTI1OjEyMzQ=` (never expires, for staging tests)

---

## Flutter Sync Files

| File | Purpose |
|------|---------|
| `frontend/lib/presentation/screens/logistic_partner/rr_sync_screen.dart` | Bottom sheet, `showRrSyncSheet()` entry point. "Ready to Sync" + "Uploads Incomplete" sections. Per-trip tap → `_RrLoginDialog` → `syncTrip()` |
| `frontend/lib/providers/rr_sync_provider.dart` | State: `readyTrips`, `missingDataTrips`, `syncingTripId`. Methods: `loadReadyTrips()`, `syncTrip(tripId, token)` |
| `frontend/lib/data/services/rr_sync_api.dart` | API calls: `getReadyTrips()`, `loginToRr(u,p)`, `triggerTripSync(id, token)`, `getSyncStatus(id)` |

`TripStagesScreen` AppBar also has a sync button (secondary path — same `_RrLoginDialog`, calls same endpoint directly without going through the sheet).

---

## Phase Completion Status

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | DB migrations (054-059, head=059 adds s3_loaded_weight_slip_url) | DONE |
| 2 | Token service + `/api/rr/*` proxy endpoints | DONE |
| 3 | Stage 2 multipart + loading slip merge into S2 | DONE |
| 4 | rr_sync_service.py initial + rr_sync.py endpoints | DONE |
| 5 | Vehicle/driver RR ID auto-resolution (_try_resolve_rr_ids) | DONE |
| 6 | S3 bilty/weight/material + S5 POD in sync_all_to_rr | DONE |
| 7 | Flutter: city picker, material picker, weight/invoice fields in CreateTripScreen + FulfillSheet | DONE |
| 8 | Flutter: RR Sync Manager sheet (LP dashboard top-right) with per-trip login flow | DONE |
| 9 | Company picker UI — `GET /api/rr/companies` proxy + org settings screen to set rr_company_id | PLANNED |

---

## DB Columns Added (Phases 1-6)

### trips (migration 054-059)
- `origin_rr_city_id`, `destination_rr_city_id`, `material_rr_id`
- `weight_value NUMERIC(10,3)`, `weight_unit VARCHAR(10)`
- `invoice_value NUMERIC(12,2)`
- `rr_trip_id`, `rr_trip_number`, `rr_parcel_id`, `rr_parcel_etag`
- `rr_sync_status VARCHAR(30)`, `rr_sync_error TEXT`, `rr_synced_at TIMESTAMP`
- `s3_loaded_weight_slip_url VARCHAR(500)` (migration 059)

### organizations
- `rr_company_id VARCHAR(24)` — admin sets once

### vehicles
- `rr_vehicle_id VARCHAR(24)` — auto-resolved via Phase 5

### drivers
- `rr_user_id VARCHAR(24)` — auto-resolved via Phase 5 (10-digit phone lookup)

### material_types (migration 058 — table exists but NO LONGER QUERIED)
- `id UUID PK`, `name VARCHAR(100) UNIQUE`, `rr_material_id VARCHAR(24)`, `created_at`
- `/api/rr/materials` now proxies live to RR `/material_types` — local table unused

---

## Seed Files (OBSOLETE)

`backend/seed_material_types.py` and `backend/seed_material_types.sql` are no longer needed.
`GET /api/rr/materials` now proxies live to RR `/material_types` — no local seeding required.

---

## Infrastructure — Test Server (fc11: 35.244.19.78)

| Service | Address | Notes |
|---------|---------|-------|
| RR API | `https://35.244.19.78:8042` | `rrbcApiContainer`, SSL |
| MongoDB | `35.244.19.78:8040` | db: `rolling_radius` |
| Mongo Express | `http://35.244.19.78:8041` | Browse RR collections |
| RR4 backend | `http://35.244.19.78:8000` | `fleet_backend` container |
| PostgreSQL | `35.244.19.78:5436` | `fleet_user` / `fleet_password_2024`, db: `fleet_db` |
| pgAdmin | `http://35.244.19.78:5050` | Seed SQL, check org IDs |

RR 3.7 branch (`test/release-3.18.3.7`) already contains all `feature/rr4-sync` changes (Basic Auth, etc.).
No separate RR code deployment needed — just pull on fc11 when SSH is available.

---

## Deployment Checklist (fc11)

| Step | Action |
|------|--------|
| 1 | Pull `feature/rr-sync` on RR4 container |
| 2 | `alembic upgrade head` (run migrations 054-059) |
| 3 | Set `RR_SYNC_ENABLED=true` in `.env`, restart backend container |
| 4 | Set `rr_company_id` on both LP org and Load Owner org — get ObjectIds from Mongo Express companies collection, apply via pgAdmin SQL (company picker UI planned for Phase 9) |
| 5 | Pull `test/release-3.18.3.7` on RR container (already has rr4-sync changes) |

**No longer needed**: seed_material_types step removed — materials proxied live from RR.

---

## One-Time Setup Required

| Step | Who | Action |
|------|-----|--------|
| 1 | Admin/LP | Set `rr_company_id` on LP org (copy ObjectId from RR companies collection) |
| 2 | Admin/LO | Set `rr_company_id` on Load Owner org |
| 3 | Auto | `rr_vehicle_id` + `rr_user_id` auto-resolved at sync time — no manual action |
| 4 | Server | Set `RR_REFRESH_TOKEN` + `RR_SYNC_ENABLED=true` in .env, restart backend |

---

## Bilty Note

RR has two separate bilty concepts:
1. `parcel.documents.bilty` — just the number string (set via PATCH parcel)
2. `bilty` collection — full record with generated PDF, uses company token credits

`verify_document_collection_stage` checks the **bilty collection**, not `parcel.documents.bilty`.
If RR web users need to verify DocumentCollection stage, a bilty generation endpoint call would be needed (future option).

---

## Cross-Reference: Finding the Same Trip in Both Systems

| Field | RR4 column | RR field |
|-------|-----------|---------|
| RR4 trip number | `trips.trip_number` (e.g. "RR-90422") | `trips.human_trip_number` |
| RR trip number | `trips.rr_trip_number` (e.g. "rr1235") | `trips.trip_number` |
| RR trip MongoDB ID | `trips.rr_trip_id` | `trips._id` |
| RR parcel MongoDB ID | `trips.rr_parcel_id` | `parcels._id` |

---

## RR Stage Order (for reference)

```
1.  ParcelInfo          — city, material, weight, consignor
2.  Bidding             — vehicle bid awarded
3.  VehicleBooking      — vehicle booked (create_trip lands here)
4.  Loading             — driver DL in RR users
5.  DocumentCollection  — bilty record in bilty COLLECTION
6.  Enroute
7.  Unloading           — POD present
8.  ClearBalance
9.  OriginalPODSubmission
10. PODInvoiceClearance
11. TripCompleted
12. TripCanceled
```

RR4 does NOT call `verify_trip_stage`. RR web users manage their own verification.
RR4's job = push data only.
