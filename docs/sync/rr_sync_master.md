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
| `GET /api/rr/consignees?q=` | Search `load_receiver` organisations (orgs only) |
| `GET /api/rr/ops-workers?q=` | List LP's active `lp_rr_operations` workers |
| `GET /api/rr/preferred-partners?rr_token=` | LP's preferred partners from RR (phone + postal_addresses + gstin) |
| `GET /api/rr/partner-companies?user_id=&rr_token=` | Companies for a user-type partner (name + rr_company_id + gstin) |
| `GET /api/rr/operation-locations?company_id=&rr_token=` | Pickup/unload addresses for a company (city embedded) |
| `GET /api/rr/enums?name=` | Public proxy to RR `/get_enum` — no auth (QuantityUnit, VehicleBodyTypes) |
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
| `POST /trips` | First sync (no rr_parcel_id) | Create trip record in RR (form data) |
| `POST /parcels` | Immediately after POST /trips | Create parcel linked to trip (JSON) |
| `DELETE /trips/{id}` | Parcel creation fails | Rollback: delete the orphaned trip |
| `POST /post_loading_slip` | Loading slip sync | Attach loading slip to RR trip |
| `POST /files` | Each doc upload | Upload file bytes → returns RR file `_id` |
| `GET /trips/{id}` | After trip+parcel created | Get rr_trip_number + etag |
| `GET /parcels/{id}` | Before each PATCH | Get fresh ETag |
| `PATCH /parcels/{id}` | S3 and S5 | Push bilty/weight/material (S3) + POD (S5) |
| `PATCH /trips/{id}` | S3 bilty photo | Append to trip_documents array |
| `GET /cities` | City proxy | Public endpoint — no auth required |
| `GET /material_types` | Material type proxy | Public endpoint — no auth required |

**NOT called by RR4 currently:** `POST /create_trip` — bypassed (see note below), `POST /verify_trip_stage` — RR web users manage their own stage verification.

> **Why `POST /create_trip` is currently bypassed:** Requires `vehicle_id`, `driver_id`, `vehicle_provider_id`, `booking_amount` — fields not available at trip creation time in RR4 (vehicle/driver assigned in S1/S2). Also hardcodes `created_by_company` to "RollingRadius Logistics Pvt. Ltd." which is wrong for LP-owned trips.
> **Note:** `create_trip` JWT bug (commit `a25eb588`) was **fixed in commit `e6536685` (June 3 2026)**. Redis cache bug between Steps 4 and 5 was **fixed in commit `37cf494c` (June 3 2026)**. `create_trip` is now fully functional on `test/release-3.18.3.7`. The current bypass is a design decision, not a bug fix. See `CREATE_TRIP_ARCHITECTURE.md` for full details and advancement plan.

---

## sync_all_to_rr() Flow

```
1. Fetch trip from DB. If not found → return.

2. If no rr_parcel_id (trip not yet in RR):
   a. _try_resolve_rr_ids (best-effort, non-blocking):
      - GET /vehicles?where={"rc_number": plate} → cache vehicle.rr_vehicle_id
      - GET /users?where={"phone.number": 10digit} → cache driver.rr_user_id
   b. Pre-flight: check 6 required fields (reduced from 8):
      load_owner_org.rr_company_id,
      origin_rr_city_id, destination_rr_city_id, material_rr_id,
      weight_value, weight_unit
      → Any missing: status=failed, rr_sync_error=<list>, return
      (vehicle/driver RR IDs are optional — sent if resolved, never block sync)
   c. _create_rr_trip(trip, client, token, consignor_rr_id, rr_weight_unit, transporter_rr_company_id?):
      - Decode JWT to extract RR user ObjectId (sub claim)
      - POST /trips  (form data):
          source="Other", created_by=rr_user_id, handled_by=rr_user_id,
          created_by_company=transporter_rr_company_id (if available),
          back_entry_date=trip.created_at.date()
      - POST /parcels  (JSON):
          trip_id, pickup/unload city, quantity+unit, material_type, cost,
          sender.sender_company=consignor_rr_id, source="Other"
      - On parcel failure: DELETE /trips/{rr_trip_id} (rollback), return error
      - Returns (rr_trip_id, rr_parcel_id, None)
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

## Direct Eve Call Payloads (replaces create_trip)

### POST /trips  (JSON — `json=`, NOT `data=`)
```python
{
    "source":             "Other",
    "created_by":         rr_user_id,           # JWT sub claim (LP's RR ObjectId)
    "handled_by":         rr_user_id,           # same
    "created_by_company": lp_rr_company_id,     # LP's OWN org rr_company_id (NOT transporter's)
    "back_entry_date":    trip.created_at.date().isoformat(),
    # If vehicle body type available:
    "specific_vehicle_requirements": {
        "vehicle_body_type": trip.body_type,
        "axle_type":         trip.axle_type,
        "number_of_wheels":  [trip.number_of_wheels],
        "expected_price":    float(trip.expected_freight),
    }
}
```
**IMPORTANT:** Must use `json=` not `data=` — nested dicts fail with form data.

### POST /parcels  (JSON — `json=`)
```python
{
    "trip_id":               rr_trip_id,
    "pickup_postal_address": {
        "city":           trip.origin_rr_city_id,
        "address_line_1": trip.pickup_address_line1,
        "address_line_2": trip.pickup_address_line2,
        "pin":            trip.pickup_pin,
        "no_entry_zone":  trip.pickup_no_entry_zone,
    },
    "unload_postal_address": {
        "city":           trip.destination_rr_city_id,
        "address_line_1": trip.unload_address_line1,
        "address_line_2": trip.unload_address_line2,
        "pin":            trip.unload_pin,
        "no_entry_zone":  trip.unload_no_entry_zone,
    },
    "quantity":      float(trip.weight_value),
    "quantity_unit": rr_weight_unit,            # already in RR format (TONNES/KILOGRAMS/etc.)
    "material_type": trip.material_rr_id,
    "cost":          float(trip.invoice_value or 0),
    "sender": {
        "sender_company": consignor_rr_id,      # load_owner_org.rr_company_id
        "name":           trip.consignor_name,
        "gstin":          trip.consignor_gstin,
    },
    "receiver": {
        "name":  trip.consignee_name,
        "gstin": trip.consignee_gstin,
    },
    "description":        trip.parcel_description,
    "part_load":          trip.part_load,
    "depot_code":         trip.depot_code,
    "created_by_company": lp_rr_company_id,
    "source":             "Other",
    "back_entry_date":    trip.created_at.date().isoformat(),
    "documents": {
        "bilty": bilty_number,                  # if available at S3
    },
}
```
**IMPORTANT:** `documents` must be a nested dict — NOT `"documents.bilty"` as a literal string key.

**On parcel failure:** `DELETE /trips/{rr_trip_id}` (If-Match: etag) — rollback orphaned trip.

**JWT decode:** `base64(token.split(".")[1]).sub` → LP's RR user ObjectId for `created_by`/`handled_by`.

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
| Roles | `lp_rr_operations` + `load_receiver` roles; consignee + RR ops fields on trips; migrations 060-061 | DONE |
| RR Form | CreateTripScreen full rewrite: 7-section RR web form, 18 new parcel fields, auto-fill (partner/company/address), operation_locations proxy, GSTIN from identities; migration 065 | DONE |
| 9 | Company picker UI — `GET /api/rr/companies` proxy + org settings screen to set rr_company_id | PLANNED |
| Advancement | Call vehicle booking sub-APIs after S1: save_potential_vehicle → submit_offline_bid → award_bidding → award_vehicle; advances trip to VehicleBooking stage in RR | PLANNED |

---

## DB Columns Added (Phases 1-6, + Roles Phase)

### trips (migration 054-059)
- `origin_rr_city_id`, `destination_rr_city_id`, `material_rr_id`
- `weight_value NUMERIC(10,3)`, `weight_unit VARCHAR(10)`
- `invoice_value NUMERIC(12,2)`
- `rr_trip_id`, `rr_trip_number`, `rr_parcel_id`, `rr_parcel_etag`
- `rr_sync_status VARCHAR(30)`, `rr_sync_error TEXT`, `rr_synced_at TIMESTAMP`
- `s3_loaded_weight_slip_url VARCHAR(500)` (migration 059)

### trips (migration 061)
- `consignee_org_id UUID` — load_receiver org assigned at trip creation (nullable)
- `consignee_user_id UUID` — load_receiver individual user (nullable, org or user — one of the two)
- `rr_ops_user_id UUID` — lp_rr_operations worker responsible for syncing this trip (nullable)

### trips (migration 065 — 18 RR parcel fields)
- `consignor_name`, `consignor_gstin` — auto-filled from preferred partner / company identities
- `consignee_name`, `consignee_gstin`
- `pickup_address_line1`, `pickup_address_line2`, `pickup_pin`, `pickup_no_entry_zone BOOLEAN`
- `unload_address_line1`, `unload_address_line2`, `unload_pin`, `unload_no_entry_zone BOOLEAN`
- `depot_code`, `parcel_description`, `part_load BOOLEAN`
- `axle_type`, `number_of_wheels INTEGER`, `expected_freight NUMERIC(12,2)`

### organizations
- `rr_company_id VARCHAR(24)` — admin sets once (LP org + Load Owner org)

### users (migration 060)
- `rr_company_id VARCHAR(24)` — for `lp_rr_operations` workers only; set via pgAdmin

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
| 1 | Pull `staging` branch on RR4 container |
| 2 | `alembic upgrade head` (runs migrations 054-065, adds all RR parcel fields) |
| 3 | Set `RR_SYNC_ENABLED=true` in `.env`, restart backend container |
| 4 | Set `rr_company_id` on LP org + Load Owner org — Mongo Express → pgAdmin SQL |
| 5 | Set `users.rr_company_id` for each `lp_rr_operations` worker — pgAdmin SQL |
| 6 | Pull `test/release-3.18.3.7` on RR container (already has rr4-sync changes) |

**No longer needed**: seed_material_types step removed — materials proxied live from RR.

---

## One-Time Setup Required

| Step | Who | Action |
|------|-----|--------|
| 1 | Admin/LP | Set `rr_company_id` on LP org (copy ObjectId from RR companies collection) |
| 2 | Admin/LO | Set `rr_company_id` on Load Owner org |
| 3 | Admin | Set `rr_company_id` on each `lp_rr_operations` user row in `users` table via pgAdmin |
| 4 | Auto | `rr_vehicle_id` + `rr_user_id` auto-resolved at sync time — no manual action |
| 5 | Server | Set `RR_REFRESH_TOKEN` + `RR_SYNC_ENABLED=true` in .env, restart backend |

---

## GSTIN Lookup — Important Detail

GSTIN is **not** a top-level field on RR company/user objects. It lives in the `identities` array:

```python
# Correct extraction (used in rr_sync.py _extract_gstin helper):
for identity in obj.get("identities", []):
    if identity.get("id_name") == "GST":
        return identity.get("number", "")
```

The `get_preferred_partners` and `get_partner_companies` proxy endpoints both use `_extract_gstin()`.
Flutter auto-fills GSTIN immediately on partner selection (from `p['gstin']`) and updates on company selection.

---

## Advancement Plan — Vehicle Booking Sub-APIs

After the current sync creates trip + parcel in RR (at `ParcelInfo` stage), the next advancement
will call 4 additional RR APIs to advance the trip to `VehicleBooking` stage.

**Trigger:** After S1 is submitted (vehicle RC + driver phone resolved to RR IDs).

**Required extra fields:**
- `rr_vehicle_id` — from `vehicles.rr_vehicle_id` (auto-resolved by RC number)
- `rr_user_id` (driver) — from `drivers.rr_user_id` (auto-resolved by phone)
- `lp_rr_company_id` — LP org's `rr_company_id` (vehicle provider = LP)
- `booking_amount` — use `trips.expected_freight` or 0

**Sub-APIs to call (in order):**
```
POST /v2/save_potential_vehicle_to_be_hired
     {vehicle_id, trip_id, participant_company_id: lp_rr_company_id}

POST /submit_offline_bid_by_trip_owner
     {potential_vehicle_id, amount: expected_freight or 0}

POST /award_bidding
     {potential_vehicle_id}

POST /award_vehicle
     {trip_id, potential_vehicle_id}
```

**Result:** Trip at `VehicleBooking` stage in RR — vehicle assigned, purchase order created, financial journal recorded.

**Always pass `data_entry: true`** to suppress SMS/notifications for back-entered RR4 trips.

**Full architecture:** See `D:/RR4/md/CREATE_TRIP_ARCHITECTURE.md`

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
