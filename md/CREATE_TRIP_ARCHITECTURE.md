# RR `create_trip` — Deep Architecture

## Overview

`POST /create_trip` is an **orchestrator endpoint** in the RR backend (`rrbc-api/app/trips/app.py`).
It does not do one large DB write — it calls **6 to 9 internal RR APIs in sequence**, each independently usable from the frontend.

All internal calls use the same JWT token from the incoming `Authorization` header:

```python
token = request.headers.get("Authorization", "").split(" ")[-1]
headers = {"Authorization": f"Bearer {token}"}
URL = os.getenv("API_URL")   # e.g. https://35.244.19.78:8042/
```

**RR branch:** `test/release-3.18.3.7`

### Fix History

| Commit | Date | Fix |
|--------|------|-----|
| `a25eb588` | May 2026 | JWT auth added to RR — but `create_trip` internal calls still used legacy MD5 token → broke |
| `e6536685` | June 3 2026 | Fixed: internal calls now use incoming JWT token |
| `37cf494c` | June 3 2026 | Fixed: Redis cache invalidated after Step 4 write → Step 5 now reads fresh `last_bid` |

`create_trip` is **fully functional** on `test/release-3.18.3.7` as of June 3 2026.

---

## 3.6 vs 3.7 — Complete Diff

### Only 3 lines changed that affect `create_trip` directly

**`trips/app.py` — Bug 1 (JWT token):**
```python
# 3.6:  token = login_user_record.get("token")          ← legacy DB field, expired/wrong
# 3.7:  token = request.headers.get("Authorization", "").split(" ")[-1]   ← incoming JWT ✓
```

**`trips/bidding.py` — Bug 2 (Redis cache invalidation):**
```python
# 3.6: no invalidation after find_one_and_update
# 3.7: added these 3 lines in submit_offline_bid_by_trip_owner:
from cache.cache_manager import invalidate_document          # (import at top)
invalidate_document("potential_vehicles", potential_vehicle_record.get("_id"))
                                                             # (after find_one_and_update)
```

### Entire Redis Cache Layer is new in 3.7

`cache/` module (6 new files) — two-layer caching:
- **Layer 1 (HTTP response cache):** `before_request`/`after_request` hooks in `app.py`. Only for static collections with `http_cache: True`.
- **Layer 2 (document cache):** `apply_cache_proxy(app)` wraps Eve's DB layer — `find_one({"_id": X})` auto-served from Redis for cached collections.

**Cache config (TTL / strategy):**

| Collection | Strategy | TTL | HTTP cache? |
|-----------|----------|-----|------------|
| `cities` | bulk | 3h | ✓ |
| `districts` | bulk | 6h | ✓ |
| `states`, `countries` | bulk | 24h | ✓ |
| `vehicle_body_types`, `vehicle_body_models`, `material_types` | bulk | 6h | ✓ |
| `roles` | bulk | 24h | ✓ |
| `users` | individual | 5m | ✗ |
| `companies` | individual | 10m | ✗ |
| `vehicles` | individual | 10m | ✗ |
| `potential_vehicles` | individual | 5m | ✗ |

HTTP cache is OFF for transactional collections — caching HTTP responses would bypass Eve auth (before_request returns early, `g.authh` never set → "No Company Found" errors).

### What is IDENTICAL in 3.6 and 3.7

The **two direct MongoDB writes** in the `create_trip` orchestrator are byte-for-byte identical:

```python
# After Step 4 — advance_amount direct write (same in both):
if advance_amount:
    potential_vehicle_dbh.update_one({"_id": potential_vehicle_id},
                                     {"$set": {"advance_amount": advance_amount}})

# After Step 7 — freight_charges direct write (same in both):
parcels_dbh.update_one({"_id": parcel_id},
                       {"$set": {"charges.freight_charges": freight_amount}})
```

**3.6:** No Redis → direct writes are safe.
**3.7:** `potential_vehicles` is cached (5-min individual TTL). The `advance_amount` write has NO `invalidate_document` call after it — minor latent bug, but doesn't cause crashes since `advance_amount` is read in payment processing (well after 5-min TTL expires). `parcels` is NOT in the cache config so `freight_charges` write has no issue.

All 9 sub-API steps, all rollback logic, all payloads, and all field names are **identical** between 3.6 and 3.7.

---

## RR4 Usage — New Flow (June 2026)

**"Create Trip" tap** → saves to RR4 PostgreSQL only. Zero RR API calls.

**"Complete Trip" button** (on `OngoingTripCard`, LP dashboard) → authenticates with RR → calls `POST /create_trip` → trip lands in RR at `VehicleBooking` stage.

The "Complete Trip" button (`_CompleteBtn` in `ongoing_trip_card.dart`) is currently enabled when `currentStage >= 5`. The new flow hooks into the existing `onComplete` callback passed from LP dashboard. LP authenticates once at form open (for partner/worker data) and the same RR session (with silent refresh) is reused at Complete Trip time.

**Required for Complete Trip to succeed:**
- S1 must be submitted so `rr_vehicle_id` + `rr_user_id` are resolved
- `consignor_rr_company_id`, `origin_rr_city_id`, `destination_rr_city_id`, `material_rr_id`, `weight_value/unit` must all be set
- The authenticating user must have CSR or Developer role in RR (phone `8905393266` qualifies; `7414082984` needs verification — see Step 4 auth note)

---

## Required Input Fields

| Field | Type | Required? | Notes |
|-------|------|-----------|-------|
| `consignor_company_id` | ObjectId | YES | 400 if missing |
| `vehicle_id` | ObjectId | YES | 400 if missing |
| `driver_id` | ObjectId | YES | 400 if missing |
| `vehicle_provider_id` | ObjectId | YES | Tries companies first, then users |
| `pickup_city` | ObjectId | YES | RR city `_id` |
| `unload_city` | ObjectId | YES | RR city `_id` |
| `material` | ObjectId | YES | RR material_type `_id` |
| `weight` | float | YES | |
| `weight_unit` | QuantityUnit enum | YES | Must match RR enum exactly |
| `freight_amount` | float | YES | |
| `invoice_value` | float | YES | |
| `booking_amount` | float | YES | Bid price for vehicle provider |
| `consignee_company_id` | ObjectId | no | |
| `handled_by` | ObjectId | no | Defaults to logged-in user |
| `back_entry_date` | date string | no | Use trip's `created_at` for back-entry |
| `force_create` | bool | no | Bypasses duplicate trip check — set `true` for RR4 |
| `data_entry` | bool | no | **Always `true` for RR4** — suppresses all SMS/notifications |
| `consignor_address_1` | string | no | |
| `consignor_address_pin_code` | int | no | |
| `consignee_address_1` | string | no | |
| `consignee_address_pin_code` | int | no | |
| `bilty_number` | string | no | Uniqueness-checked across all parcels |
| `invoice_number` | string | no | |
| `eway_bill_number` | string | no | |
| `depot_code` | string | no | |
| `vehicle_entry_time` | datetime | no | |
| `vehicle_exit_time` | datetime | no | |
| `loading_amount` | float | no | Triggers Step 8 if > 0 |
| `unloading_amount` | float | no | Triggers Step 9 if > 0 |
| `diesel_charges` | float | no | Triggers Step 9 if > 0 |
| `advance_amount` | float | no | |

### RR4 Field Mapping

| `create_trip` field | RR4 source | Available when |
|---------------------|-----------|----------------|
| `consignor_company_id` | `trips.consignor_rr_company_id` | Form submit |
| `pickup_city` | `trips.origin_rr_city_id` | Form submit |
| `unload_city` | `trips.destination_rr_city_id` | Form submit |
| `material` | `trips.material_rr_id` | Form submit |
| `weight` + `weight_unit` | `trips.weight_value/unit` | Form submit |
| `invoice_value` | `trips.invoice_value` | Form submit |
| `consignee_company_id` | `trips.consignee_rr_company_id` | Form submit |
| `handled_by` | `rr_ops_user.rr_company_id` | Form submit |
| `freight_amount` + `booking_amount` | `trips.expected_freight` or 0 | Form submit |
| `bilty_number` | `trips.bilty_number` | After S3 |
| **`vehicle_id`** | `vehicles.rr_vehicle_id` | **After S1** (RC lookup) |
| **`driver_id`** | `drivers.rr_user_id` | **After S1** (phone lookup) |
| `vehicle_provider_id` | LP org `rr_company_id` (= Rolling Radius ObjectId) | Always |
| `back_entry_date` | `trips.created_at` | Always |

---

## Phase 0: Input Validation (no HTTP calls — direct MongoDB reads)

All validations run before any sub-API is called. Any failure returns 400 immediately.

| Validation | MongoDB collection | Error message |
|-----------|-------------------|---------------|
| `consignor_company_id` | `companies` | "Invalid consignor company id provided." |
| `consignee_company_id` | `companies` | "Invalid consignee company id provided." |
| Transporter | `companies.find({"name": "RollingRadius Logistics Pvt. Ltd."})` | "Invalid transporter company id provided." |
| `vehicle_id` | `vehicles` | "Invalid vehicle id provided." |
| `vehicle_provider_id` | `companies` then `users` | "Invalid vehicle provider id provided." |
| `pickup_city` + `unload_city` | `cities` | "Please provide valid pickup or unload city." |
| `driver_id` | `users` (`_deleted: False`) | "Please provide valid driver number." |
| `material` | `material_types` | "Invalid material id provided." |
| `weight_unit` | QuantityUnit enum | "Invalid quantity unit" |

**Side effects during validation (DB writes, not HTTP):**
- Updates `vehicle.crew[]` in MongoDB — replaces existing Driver slot with the new `driver_id`
- Extracts `sender_name` + `sender_gst` from `consignor_company.identities` (id_name == 'GST')
- Extracts `receiver_name` + `receiver_gst` from `consignee_company.identities`
- Duplicate check: queries `parcels` by `(back_entry_date, consignor, unload_city, transporter)` — returns 409 `"statusText": "duplicate_trip"` unless `force_create: true`

**Key hardcoding:** `created_by_company` is always set to the "RollingRadius Logistics Pvt. Ltd." ObjectId — cannot be overridden. For RR4 this is correct: LP org's `rr_company_id` is set to Rolling Radius's MongoDB ObjectId.

**Extra Phase 0 writes confirmed from source:**
- `vehicle.crew[]` updated in MongoDB: old Driver slot removed, new `{worker: driver_id, position: "Driver"}` appended — this happens BEFORE Step 1
- `invoice_number` → `str(invoice_number).upper()`
- `depot_code` → `str(depot_code).strip().upper()`
- `bilty_number` uniqueness: queries `parcels.documents.bilty` directly — if exists, deletes trip + returns 400

---

## Step 1: POST /trips

Eve resource endpoint. Creates the bare trip shell.

```python
trip_payload = {
    "handled_by":         handled_by,
    "created_by":         login_user._id,
    "created_by_company": transporter_company_id,   # always RollingRadius
    "source":             login_user.source,
    "back_entry_date":    "...",    # optional
    "data_entry":         True,     # always True for RR4
}
requests.post(URL + "trips", data=trip_payload, headers=headers, verify=False)
# NOTE: trip payload is sent as form data (data=), NOT JSON (json=)
```

**Eve hook `before_insert_trips`:**
- Injects default `trip_stages[]` — 12 stages, all `start_datetime: null` except ParcelInfo (set to `datetime.now(UTC)`)
- Assigns `trip_number`: reads `company.book_counter.trip`, increments (e.g. "RR-001" → "RR-002"), writes back

**Eve hook `actions_after_insert_trip`:**
- If `back_entry_date` provided: overwrites `_created` timestamp to match

Returns `{_id}` → `trip_id`. On failure: returns 400, orchestrator exits immediately (no data written yet except the Phase 0 vehicle.crew[] update).

---

## Step 2: POST /parcels

```python
parcel_payload = {
    "trip_id":               str(trip_id),
    "created_by_company":    str(transporter_company_id),
    "pickup_postal_address": {
        "city":          str(pickup_city_id),
        "address_line_1": pickup_address_1,
        "pin":           pickup_address_pin_code,
    },
    "unload_postal_address": {
        "city":          str(unload_city_id),
        "address_line_1": drop_address_1,
        "pin":           drop_address_pin_code,
    },
    "quantity":      weight,
    "quantity_unit": weight_unit,
    "material_type": str(material),
    "cost":          invoice_value,
    "sender": {
        "sender_company": str(consignor_company_id),
        "name":           sender_name,    # from consignor.identities GST
        "gstin":          sender_gst,
    },
    "receiver": {
        "receiver_company": str(consignee_company_id),
        "name":             receiver_name,
        "gstin":            receiver_gst,
    },
    "documents.bilty":                        bilty_number,       # string key bug — see note
    "documents.eway_bill.number":             eway_bill_number,
    "documents.consignor_invoice.number":     invoice_number,
    "loading": {
        "truck_reach_datetime": vehicle_entry_time,
        "end_datetime":         vehicle_exit_time,
    },
    "actual_kanta_weight": {"weight": actual_kanta_weight, "weight_unit": weight_unit},
    "depot_code":      depot_code,
    "back_entry_date": "...",
}
requests.post(URL + "parcels", json=parcel_payload, headers=headers)
```

> ⚠️ **Known bug in `create_trip`:** Uses `"documents.bilty"` as a literal string key (not nested dict). RR4's direct `POST /parcels` call uses correct `{"documents": {"bilty": x}}`. When calling `create_trip`, bilty is passed via top-level key — it may not populate correctly if RR's Eve schema rejects dotted keys.

**Bilty uniqueness check:** Before the call, `create_trip` queries `parcels.documents.bilty` — if already exists, deletes trip and returns 400. Pass `force_create: true` to bypass.

On failure: `trips_dbh.delete_many({"_id": trip_id})` + returns 400.
Returns `{_id}` → `parcel_id`.

---

## Step 3: POST /v2/save_potential_vehicle_to_be_hired

File: `rrbc-api/app/trips/bidding.py:878`

```python
{
    "vehicle_id":             str(vehicle_id),
    "trip_id":                str(trip_id),
    "participant_company_id": str(vehicle_provider_company_id),  # OR
    "participant_user_id":    str(vehicle_provider_user_id),
}
```

**What it does:**
1. Validates trip stage is still in `[ParcelInfo, Bidding, VehicleBooking, TripCanceled]`
2. Checks bidding is not live
3. Checks if this vehicle/participant combo already exists in `potential_vehicles` — handles existing records (Interested, ToBeHired → updates; Booked → blocked)
4. If new: inserts into `potential_vehicles` with `vehicle_status: "ToBeHired"`, `flags.to_be_hired: now`
5. Sets `vehicle_relation`:
   - **`"Owner"`** — vehicle provider's `created_by_company`/`created_by` matches the vehicle's own fields
   - **`"Market"`** — third party → triggers Step 6 (rental agreement)

On failure: deletes trip + parcel, returns 400.
Returns `{potential_vehicle_id}`.

---

## Step 4: POST /submit_offline_bid_by_trip_owner

File: `rrbc-api/app/trips/bidding.py:3342`

```python
{
    "potential_vehicle_id": str(potential_vehicle_id),
    "amount":               booking_amount,
}
```

**What it does:**
1. Fetches `potential_vehicle` and its linked trip
2. **`check_trips_authorization`** — verifies the logged-in user is a worker of the trip owner's company with **CSR or Developer role**. Regular `User` role is NOT sufficient.
3. Checks bidding is NOT currently scheduled/live (offline price only allowed before or after formal bidding)
4. Checks `amount != last_bid` (cannot submit same price twice)
5. `find_one_and_update`: `$push bid_negotiations [{price, datetime, offline: true}]`, `$set last_bid = amount`
6. **`invalidate_document("potential_vehicles", id)`** — evicts Redis cache entry. **Critical:** without this, Step 5 reads stale `last_bid = None` and fails. Fixed in commit `37cf494c`.
7. `update_ranking_of_potential_vehicles(trip_id)` — re-ranks all candidates by last_bid

> ⚠️ **Auth note for RR4 — confirmed from source (`app/auth/common_functions.py:19`):**
> `check_trips_authorization` has two paths:
> 1. User has any of `{CSR Supervisor, CSR, Admin, Developer}` role → **passes immediately**
> 2. No privileged role → must be `is_user_company_worker(user_id, trip.created_by_company)`
>
> Since `created_by_company` = Rolling Radius ObjectId (hardcoded), path 2 requires being a worker of Rolling Radius.
> - ✅ Phone `8905393266` has Admin/CSR role → path 1, always passes
> - ❌ Phone `7414082984` has regular User role → path 2, fails unless added as RR company worker
> - **Always use `8905393266`** for RR4 `create_trip` calls.

**Between Step 4 and Step 5 (orchestrator direct MongoDB write):**
- If `advance_amount > 0`: `potential_vehicles.update_one({$set: {advance_amount: advance_amount}})`
- This is NOT a sub-API call — direct MongoDB write in the orchestrator.

Returns: 200 `{"statusText": "Offline price saved successfully"}`.

---

## Step 5: POST /award_bidding

File: `rrbc-api/app/trips/bidding.py:3408`

```python
{"potential_vehicle_id": str(potential_vehicle_id)}
```

**What it does:**
1. Reads `potential_vehicle` via `get_document_from_db_by_id` (goes through Redis cache — must be fresh after Step 4's cache invalidation)
2. Authorization check (same CSR/Developer requirement)
3. Guard checks:
   - Already BidAwarded? → "Already awarded"
   - Another vehicle already Booked? → blocked
   - `last_bid is None`? → "No charge provided..." ← this is where the Redis bug hit before fix
4. Sets `potential_vehicles.vehicle_status = "BidAwarded"`
5. Sets `trips.trip_stage = "Bidding"`
6. Sends SMS + push notification to vehicle provider — **skipped if `data_entry: true`**

Returns: 200 `{"statusText": "Awarded successfully"}`.

---

## Step 6 (conditional): POST /market_vehicles

Only runs if `vehicle_relation == "Market"` (third-party vehicle provider).

Creates a rental agreement record in `market_vehicles` collection:
```python
{
    "vehicle_id":               str(vehicle_id),
    "owner_user_id":            vehicle.created_by,
    "owner_company_id":         vehicle.created_by_company,
    "third_party_user_id":      vehicle_provider_user_id,
    "third_party_company_id":   vehicle_provider_company_id,
    "requested_start_date":     now,
    "requested_end_date":       now + 7 days,
}
```

On failure: returns 400 with `trip_id`.

---

## Step 7: POST /award_vehicle

File: `rrbc-api/app/trips/bidding.py:1620`

```python
{
    "trip_id":              str(trip_id),
    "potential_vehicle_id": str(potential_vehicle_id),
}
```

**The final booking lock — the most complex step:**
1. Verifies trip is not cancelled
2. `check_trips_authorization` (same 2-path check — Admin/CSR role OR RR worker)
3. Checks vehicle has a driver in `vehicle.crew[]` — Phase 0 already sets this
4. Checks driver has a phone number — required
5. Checks no other vehicle booked on this trip (idempotent: if same PV already booked → returns 200)
6. If Market: checks `market_vehicles` record status is not Rejected/Terminated
7. Creates/updates `purchase_orders`:
   - Existing PO with `total_payable == last_bid` and `already_paid == 0` → reuse, no journal
   - Existing PO with different amounts → delete old `financial_transactions`, create new JournalEntry
   - None (first call) → `post_purchase_order_record()` → new PO in `purchase_orders` collection
8. Creates `JournalEntry` (type: `VehicleBooking`):
   - `book_owner = {trip.created_by, trip.created_by_company}` (Rolling Radius)
   - `party = {vehicle_owner_user_id, vehicle_owner_company_id}`
   - `amount = last_bid`
9. Updates `vehicles.current_trips[]` → push `{trip_id, booking_id, current_stage: "VehicleBooking"}`
10. Updates `trips`: `trip_stage = VehicleBooking`, `booked_vehicle = {vehicle, vehicle_booked_on, booking_id}`, `crew`
11. Updates `potential_vehicles`: `vehicle_status = Booked`, `flags.booked = booking_date`
12. Deletes trip from `trip_indexes` (no longer in bidding pool)
13. Sends notifications — **skipped if `data_entry: true`**:
    - "Booking Confirmed" → vehicle provider
    - "POD Submission Warning" → provider + driver
    - "RollingRadius Brokerage Warning" → only if sender is Berger Paints

**After Step 7 (orchestrator direct MongoDB write — NOT a sub-API):**
```python
parcels_dbh.update_one({"_id": parcel_id}, {"$set": {"charges.freight_charges": freight_amount}})
```
This is how `freight_amount` lands on the parcel record — not via any sub-API.

> ⚠️ **Rollback:** Steps 4–9 have rollback commented out. If any fail, trip+parcel+potential_vehicle left as orphans in RR.

Returns: 200 `{"statusText": "This vehicle has been booked"}`.

---

## Step 8 (conditional): POST /record_trip_expense

Only runs if `loading_amount > 0`. File: `app.py:9652`

```python
{
    "expense_type": "Loading",
    "order_date":   "2026-06-03T00:00:00",
    "service_provider": null,        # no provider at booking time
    "amount":       500.0,
    "remark":       "Loading expense",
    "photo":        "",
    "trip_id":      str(trip_id),
    "service_receiver": {
        "company": str(transporter_company_id),
        "user":    str(login_user._id),
    }
}
```

**What it does:**
1. `prepare_trip_expense_payload()` — validates fields, gets next `order_id` counter, looks up bilty if exists
2. `create_trip_expense_and_initial_transaction()` — inserts into `third_party_expenses`
3. `service_provider = null` → status = **"Pending"** — no journal entry created yet. Journal entry fires via `hooks.py:after_updated_third_party_expenses` when a provider is assigned later.

---

## Step 9 (conditional): POST /post_extra_vehicle_charges

Only runs if `unloading_amount > 0` OR `diesel_charges > 0`. File: `app.py:2413`

```python
{
    "trip_id":                   str(trip_id),
    "extra_weight_charges":      0,
    "extra_distance_charges":    0,
    "halting_charges":           0,
    "hamali_charges":            unloading_amount,   # unloading labour
    "other_charges":             0,
    "vehicle_brokerage_charges": 0,
    "insurance_amount":          0,
    "no_diesel_taken_penalty":   0,
    "diesel_charges":            diesel_charges,
    "remark":                    [""],
}
```

**What it does:**
1. Finds the `purchase_order` for this trip (type: `VehicleBookingServicePurchase`)
2. Looks up existing extra charge journal entries → calculates `charge_difference`
3. If `charge_difference == 0` → returns 200 "No charge difference" (no-op)
4. Updates `trips.booked_vehicle.hamali_amount`, `.diesel_charges`, etc.
5. Updates `purchase_order.extra_charges.*`
6. Creates `JournalEntry` (type: `VehicleBookingExtraCharge`):
   - `book_owner = transporter`, `party = vehicle_provider`
   - `amount = |charge_difference|`, `amount_nature = Increase or Decrease`

---

## Final Response

```json
{
    "statusText": "Trip created succesfully.",
    "trip_id": "684...",
    "potential_vehicle_id": "684...",
    "parcel_id": "684...",
    "booking_id": null
}
```

> ⚠️ **`booking_id` is always `null` for fresh trips.** The orchestrator reads `potential_vehicle_record` BEFORE calling `award_vehicle`, so `booking_id` hasn't been set yet on the potential_vehicle document when the response is built. **RR4 should store only `trip_id` and `parcel_id` from this response.**

---

## Collections Written (after full success)

| Collection | What |
|-----------|------|
| `trips` | 1 new trip, `trip_stage = VehicleBooking` |
| `parcels` | 1 new parcel with cargo + freight_charges set |
| `potential_vehicles` | 1 new record, `status = Booked`, `last_bid` set |
| `purchase_orders` | 1 new PO for vehicle booking |
| `financial_transactions` | 2 journal entries (VehicleBooking + optional ExtraCharge) |
| `vehicles` | `crew[]` updated, `current_trips[]` updated |
| `companies` | `book_counter.trip` incremented |
| `market_vehicles` | 1 new record (only if Market vehicle) |
| `third_party_expenses` | 1 new record (only if loading_amount > 0) |

---

## Full Call Graph

```
POST /create_trip (orchestrator)
│
├── [Phase 0] MongoDB validation: companies, vehicles, users, cities, material_types
│   ├── Side write: vehicle.crew[] updated (new driver assigned)
│   └── Duplicate check on parcels collection
│
├── Step 1: POST /trips
│   ├── hook before_insert: trip_stages[] injected, trip_number assigned
│   └── writes: trips collection
│
├── Step 2: POST /parcels
│   └── writes: parcels collection
│   └── on failure: DELETE /trips/{trip_id}
│
├── Step 3: POST /v2/save_potential_vehicle_to_be_hired
│   ├── writes: potential_vehicles (status=ToBeHired)
│   └── sets vehicle_relation: Owner or Market
│
├── Step 4: POST /submit_offline_bid_by_trip_owner
│   ├── auth: check_trips_authorization (CSR/Developer role required)
│   ├── writes: potential_vehicles.bid_negotiations[], last_bid
│   └── invalidates Redis cache for potential_vehicles doc  ← critical for Step 5
│
├── Step 5: POST /award_bidding
│   ├── reads potential_vehicles (from Redis — must be fresh)
│   ├── writes: potential_vehicles.vehicle_status = BidAwarded
│   ├── writes: trips.trip_stage = Bidding
│   └── sends: SMS + push to vehicle provider (skipped if data_entry)
│
├── Step 6: [if Market] POST /market_vehicles
│   └── writes: market_vehicles collection (rental agreement)
│
├── Step 7: POST /award_vehicle
│   ├── auth: CSR/Developer required
│   ├── writes: trips.trip_stage = VehicleBooking, booked_vehicle, crew
│   ├── writes: purchase_orders (new PO → booking_id)
│   ├── writes: financial_transactions (JournalEntry: VehicleBooking)
│   ├── writes: vehicles.current_trips[]
│   ├── deletes: trip from trip_indexes
│   └── sends: booking confirmed + POD warning (skipped if data_entry)
│
├── [direct write] parcels.charges.freight_charges = freight_amount
│
├── Step 8: [if loading_amount > 0] POST /record_trip_expense
│   └── writes: third_party_expenses (status=Pending, no journal yet)
│
└── Step 9: [if unloading/diesel > 0] POST /post_extra_vehicle_charges
    ├── writes: trips.booked_vehicle.hamali_amount etc.
    ├── writes: purchase_orders.extra_charges.*
    └── writes: financial_transactions (JournalEntry: VehicleBookingExtraCharge)
```

---

## RR Stage Reference

```
1.  ParcelInfo          ← where old direct-sync landed
2.  Bidding
3.  VehicleBooking      ← where create_trip lands
4.  Loading
5.  DocumentCollection
6.  Enroute
7.  Unloading
8.  ClearBalance
9.  OriginalPODSubmission
10. PODInvoiceClearance
11. TripCompleted
12. TripCanceled
```
