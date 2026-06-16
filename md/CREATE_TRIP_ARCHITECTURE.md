# POST /create_trip — Complete Deep Analysis

File: trips/app.py:13863
Auth: @requires_auth("resource") + @auth_resource("trips")

This is a custom orchestration endpoint. It is not a simple Eve insert. It chains 8 sequential internal sub-API calls, uses the caller's Bearer token for every one of them, and touches 10 MongoDB collections across the full execution.

---
## Request Body Fields

```json
{
  "consignor_company_id":      "ObjectId — mandatory",
  "consignee_company_id":      "ObjectId — optional",
  "vehicle_id":                "ObjectId — mandatory",
  "vehicle_provider_id":       "ObjectId — mandatory (company or user)",
  "driver_id":                 "ObjectId — mandatory",
  "handled_by":                "ObjectId — optional, defaults to login user",
  "material":                  "ObjectId — mandatory",
  "pickup_city":               "ObjectId — mandatory",
  "unload_city":               "ObjectId — mandatory",
  "weight":                    "float — mandatory",
  "weight_unit":               "enum string — mandatory",
  "freight_amount":            "float — mandatory",
  "invoice_value":             "float — mandatory",
  "booking_amount":            "float — mandatory",
  "loading_amount":            "float — optional, default 0",
  "unloading_amount":          "float — optional, default 0",
  "diesel_charges":            "float — optional, default 0",
  "advance_amount":            "float — optional, default 0",
  "consignor_address_1":       "string — optional",
  "consignor_address_pin_code":"int — optional",
  "consignee_address_1":       "string — optional",
  "consignee_address_pin_code":"int — optional",
  "bilty_number":              "string — optional",
  "eway_bill_number":          "string — optional",
  "invoice_number":            "string — optional",
  "actual_kanta_weight":       "float — optional",
  "depot_code":                "string — optional",
  "vehicle_entry_time":        "datetime string — optional",
  "vehicle_exit_time":         "datetime string — optional",
  "back_entry_date":           "datetime string — optional, backdates trip",
  "data_entry":                "bool — optional, bypasses SMS/notifications",
  "force_create":              "bool — optional, bypasses duplicate check"
}
```

---
## Phase 1 — Input Validation (All Direct MongoDB Queries)

All of these run before any write. Collections are opened at function start: companies, material_types, vehicles, trips, parcels, potential_vehicles, purchase_orders, users, cities, bilty.

---
### Step 1.1 — Consignee Company (Optional)

```
companies_dbh.find_one({"_id": ObjectId(consignee_company_id)})
```
- Extracts receiver_name = record["name"]
- Loops through record["identities"] to find entry where id_name == "GST" → sets receiver_gst
- If ID provided but record not found → 400
- If not provided → receiver_name = None, receiver_gst = None (allowed)

---
### Step 1.2 — Consignor Company (Mandatory)

```
companies_dbh.find_one({"_id": ObjectId(consignor_company_id)})
```
- Extracts sender_name and loops identities for GSTIN same way
- If not provided or not found → 400

---
### Step 1.3 — Transporter (Hardcoded lookup, not from request)

```
companies_dbh.find_one({"name": "RollingRadius Logistics Pvt. Ltd."})
```
- Transporter is always RR — the vehicle_provider_id in the request is the vehicle owner, not the transporter
- Sets transporter_company_id — used as created_by_company on the trip and parcel
- If RR company not found in DB → 400

---
### Step 1.4 — Vehicle

```
vehicles_dbh.find_one({"_id": ObjectId(vehicle_id)})
```
- Fetches full vehicle record — needed later for crew, identities (RC number), and created_by_company (to determine vehicle_relation)
- If not found → 400

---
### Step 1.5 — Vehicle Provider (Two-step lookup)

```python
# Try company first
companies_dbh.find_one({"_id": ObjectId(vehicle_provider_id)})
# If no company, try user
users_dbh.find_one({"_id": ObjectId(vehicle_provider_id)})
```
- Sets either vehicle_provider_company_id or vehicle_provider_user_id
- This is compared later against vehicle_record["created_by_company"] to determine if vehicle is Own or Market
- If neither found → 400

---
### Step 1.6 — Cities (Both Mandatory)

```
cities_dbh.find_one({"_id": ObjectId(pickup_city)})
cities_dbh.find_one({"_id": ObjectId(unload_city)})
```
- Extracts pickup_city_id and unload_city_id (ObjectIds)
- Either missing or invalid → 400

---
### Step 1.7 — Driver

```
users_dbh.find_one({"_id": ObjectId(driver_id), "_deleted": False})
```
- Must exist and not be soft-deleted
- Mandatory → 400 if missing

---
### Step 1.8 — Trip Handler

```
users_dbh.find_one({"_id": ObjectId(handled_by), "_deleted": False})
```
- Optional — if not provided, handled_by = login_user_record["_id"] (the calling user)

---
### Step 1.9 — Driver Assignment (First DB Write — before any sub-API)

```python
vehicle_crew = vehicle_record.get("crew", [])
# Remove existing Driver entry if present
for crew in vehicle_crew:
    if crew["position"] == "Driver":
        vehicle_crew.remove(crew); break
# Append new driver
vehicle_crew.append({"worker": driver_id, "position": "Driver"})
vehicles_dbh.update_one({"_id": vehicle_id}, {"$set": {"crew": vehicle_crew}})
```
- Directly replaces the Driver slot on the vehicle's crew array
- Happens before trip is created — so if trip creation fails, vehicle still has the driver assigned

---
### Step 1.10 — Material

```
material_types_dbh.find_one({"_id": ObjectId(material)})
```
- Mandatory → 400 if missing

---
### Step 1.11 — Numeric Fields Parsing

```python
weight = float(body_params.get("weight"))
weight_unit  # validated against QuantityUnit enum values
freight_amount = float(body_params.get("freight_amount"))
invoice_value  = float(body_params.get("invoice_value"))
booking_amount = float(body_params.get("booking_amount"))
loading_amount   = float(...) or 0.0
unloading_amount = float(...) or 0.0
advance_amount   = float(...) or 0.0
diesel_charges   = float(...) or 0.0
```
- weight_unit must be a valid QuantityUnit enum value → 400 if not
- bilty_number is uppercased if provided
- invoice_number is uppercased if provided
- depot_code is stripped and uppercased if provided

---
### Step 1.12 — Bilty Uniqueness Check

```
parcels_dbh.find_one({"documents.bilty": bilty_number})
```
- Queries documents.bilty field on parcels collection
- If already used in any parcel anywhere → 400 with "bilty_number already exists"
- Only runs if bilty_number is provided

---
### Step 1.13 — Duplicate Trip Check (_check_duplicate_trip_in_db)

File: trips/app.py:13818
Skipped entirely if force_create: true is in body.

```python
# Convert date to IST day boundaries, then UTC for MongoDB
date_local = ist_timezone.localize(datetime.strptime(date_str[:10], "%Y-%m-%d"))
day_start  = date_local.replace(hour=0,  ...).astimezone(pytz.utc)
day_end    = date_local.replace(hour=23, ...).astimezone(pytz.utc)

# If no back_entry_date, uses today in IST

parcels_dbh.count_documents({
    "_deleted": False,
    "unload_postal_address.city": ObjectId(unload_city_id),
    "_created": {"$gte": day_start, "$lte": day_end},
    "created_by_company": ObjectId(transporter_company_id),
    "$or": [
        {"sender.sender_company": ObjectId(consignor_company_id)}
    ]
})
```
- Checks if a parcel already exists on the same day, for the same consignor, to the same unload city, under the same transporter company
- If count > 0 → returns 409:

```json
{
  "statusText": "duplicate_trip",
  "message": "A trip with the same date, consignor, and unload city already exists (N found). Pass force_create: true to create anyway.",
  "exists": true,
  "count": N
}
```

---
## Phase 2 — Sub-API Orchestration

All calls use: `headers = {"Authorization": f"Bearer {token}"}` and `URL = os.getenv("API_URL")`

---
### Sub-API 1: POST /trips

```python
trip_post_response = requests.post(URL + "trips", data=trip_payload, headers=headers, verify=False)
```

Payload sent:
```json
{
  "handled_by":        "<handled_by_user_id>",
  "created_by":        "<login_user_id>",
  "created_by_company":"<rr_transporter_company_id>",
  "source":            "<login_source>",
  "back_entry_date":   "...",
  "data_entry":        true
}
```

On failure → returns 400. Nothing to roll back yet (driver crew write already happened).

On success → extracts trip_id = ObjectId(response["_id"])

**Hook: before_insert_trips (hooks.py:112)**

Fires inside the Eve resource before the MongoDB insert.

a) Injects all 12 trip stages:
```python
document["trip_stages"] = [
  {"trip_stage": "ParcelInfo",            "start_datetime": datetime.now(UTC)},
  {"trip_stage": "Bidding",               "start_datetime": None},
  {"trip_stage": "VehicleBooking",        "start_datetime": None},
  {"trip_stage": "Loading",               "start_datetime": None},
  {"trip_stage": "DocumentCollection",    "start_datetime": None},
  {"trip_stage": "Enroute",               "start_datetime": None},
  {"trip_stage": "Unloading",             "start_datetime": None},
  {"trip_stage": "ClearBalance",          "start_datetime": None},
  {"trip_stage": "OriginalPODSubmission", "start_datetime": None},
  {"trip_stage": "PODInvoiceClearance",   "start_datetime": None},
  {"trip_stage": "TripCompleted",         "start_datetime": None},
  {"trip_stage": "TripCanceled",          "start_datetime": None},
]
```
Only ParcelInfo gets datetime.now(UTC). All others are None until that stage is reached.

b) Generates trip_number:

If created_by_company is set (normal case with RR as transporter):
```python
company_record = companies_dbh.find_one({"_id": ObjectId(created_by_company)})
current_counter = company_record["book_counter"]["trip"]  # e.g. "RR-1234"
new_counter = increment_trip_numeric_part(current_counter)  # → "RR-1235"
document["trip_number"] = new_counter
# Atomically updates counter on company
companies_dbh.update_one({"_id": company_id}, {"$set": {"book_counter.trip": new_counter}})
```

If no company (personal trip):
```python
counters_dbh.find_one_and_update(
    {"category": "RandomSequence"},
    {"$inc": {"next_sequence": 1}}
)
document["trip_number"] = f"trip{sequence}"
```

**Hook: actions_after_insert_trip (hooks.py:135)**

Fires after Eve inserts the document.

```python
if document.get("back_entry_date"):
    trips_dbh.update_one(
        {"_id": document["_id"]},
        {"$set": {"_created": document["back_entry_date"]}}
    )
```
Overwrites Eve's auto-set _created timestamp with the back-entry date. This is how historical trip creation works.

---
### Sub-API 2: POST /parcels

```python
parcel_post_response = requests.post(URL + "parcels", json=parcel_payload, headers=headers, verify=False)
```

Payload sent:
```json
{
  "trip_id":                "<trip_id>",
  "created_by_company":     "<rr_transporter_company_id>",
  "pickup_postal_address":  {"city": "<city_id>", "address_line_1": "...", "pin": 123456},
  "unload_postal_address":  {"city": "<city_id>", "address_line_1": "...", "pin": 123456},
  "quantity":               22.5,
  "quantity_unit":          "TONNES",
  "material_type":          "<material_id>",
  "cost":                   150000,
  "sender": {
    "sender_company": "<consignor_company_id>",
    "name":           "Berger Paints India Limited",
    "gstin":          "27AAACB2894C1ZY"
  },
  "receiver": {
    "receiver_company": "<consignee_company_id>",
    "name":             "...",
    "gstin":            "..."
  },
  "documents.bilty":                    "BIL-1234",
  "documents.eway_bill.number":         "EWB123",
  "documents.consignor_invoice.number": "INV-001",
  "loading": {
    "truck_reach_datetime": "...",
    "end_datetime":         "..."
  },
  "actual_kanta_weight":   {"weight": 22.1, "weight_unit": "TONNES"},
  "depot_code":             "DEP001",
  "source":                "<login_source>",
  "back_entry_date":        "..."
}
```

On failure → rolls back:
```python
trips_dbh.delete_many({"_id": trip_id})
```
Returns 400 with _issues (Eve validation errors) and trip_id.

On success → parcel_id = ObjectId(response["_id"])

**Hook: before_insert_parcel (parcels/hooks.py:44)**

```python
# Since trip_id IS provided (by create_trip):
trips.find_one({"_id": ObjectId(document["trip_id"])}, {"_id": 1})
# If trip not found → abort(400, "Invalid trip")

# Then:
verify_back_date_of_parcel(document, trip_id)
```

verify_back_date_of_parcel (parcels/hooks.py:73):
```python
trip_record = get_document_from_db_by_id("trips", trip_id)
if parcel["back_entry_date"] < trip_record["_created"]:
    abort(400, "parcel back_entry_date cannot be less than trip creation date")
if parcel["back_entry_date"] > datetime.now(UTC):
    abort(400, "parcel back_entry_date cannot be greater than current datetime")
```

> Note: If trip_id is NOT in the parcel payload (direct POST /parcels from the frontend form), the hook calls create_trip_new() which auto-creates a blank trip first. But in create_trip, the trip_id is always provided, so this path is skipped.

**Hook: after_inserted_parcel (parcels/hooks.py:97)**

```python
# Backdate parcel _created if back_entry_date provided
if document.get("back_entry_date"):
    parcels_dbh.update_one({"_id": parcel_id}, {"$set": {"_created": document["back_entry_date"]}})

# Rebuild trip search index
trip_index_dbh.delete_one({"trip_id": document["trip_id"]})
add_parcel_to_trip_index(document["trip_id"])
```
add_parcel_to_trip_index builds a denormalized trip_indexes document for fast search/filtering across trips.

Directly after parcel creation, create_trip also writes freight charges to the parcel:
```python
parcels_dbh.update_one(
    {"_id": parcel_id},
    {"$set": {"charges.freight_charges": freight_amount}}
)
```

---
### Sub-API 3: POST /v2/save_potential_vehicle_to_be_hired

File: bidding.py:877

```python
potential_vehicle_response = requests.post(
    URL + "v2/save_potential_vehicle_to_be_hired",
    json={"vehicle_id": str(vehicle_id), "trip_id": str(trip_id),
          "participant_company_id": str(vehicle_provider_company_id)
          # OR "participant_user_id": str(vehicle_provider_user_id)
    },
    headers=headers, verify=False
)
```

Queries inside this function:
```
get_document_from_db_by_id("vehicles", vehicle_id)      # re-validates vehicle
companies_dbh.find_one({"_id": ObjectId(participant_company_id)})  # re-validates provider
get_document_from_db_by_id("trips", trip_id)             # fetches trip for stage check + auth
```

Stage guard:
```python
if trip_stage not in ["ParcelInfo", "Bidding", "VehicleBooking", "TripCanceled"]:
    return 400  # "Trip has moved to further stages, can't add potential vehicles now"
```

Bidding live guard:
```python
if trip_record.get("bidding") and is_bidding_live(trip_record):
    return 400  # "Cannot add participants once bidding has started"
```

Existing potential vehicle check:
```python
potential_vehicles_dbh.find_one({
    "trip_id": trip_record["_id"],
    "_deleted": False,
    "vehicle_owner_company_id": vehicle_record["created_by_company"]
    # OR "vehicle_owner_user_id": ...
})
```
- If found with status Removed → 400 (can't re-add)
- If found with status Interested/ToBeHired/BiddingRequested → updates existing record instead of inserting new one
- If not found → inserts new potential_vehicle

Insert (new potential vehicle):
```python
post_internal("potential_vehicles", {
    "trip_id":                     trip_record["_id"],
    "vehicle":                     vehicle_record["_id"],
    "vehicle_status":              "ToBeHired",
    "flags.to_be_hired":           datetime.now(UTC),
    "all_shortlisted_vehicle":     [{"vehicle": vehicle_id, "datetime": now}],
    "vehicle_owner_company_id":    provider_company_id
    # OR "vehicle_owner_user_id":  provider_user_id
})
```

**Hook: before_insert_potential_vehicle (potential_vehicles/hooks.py)**

Fires on insert — generates the `booking_id` integer counter:
```python
updated_counter = get_next_counter(enum.CountersCategory.VehicleBooking.value)  # "vehicle booking"
if updated_counter:
    booking_id = updated_counter
document.update({"booking_id": booking_id})
```
This is the integer returned as `booking_id` in the final create_trip response. Stored as `rr_booking_id` in RR4.

Then calls update_vehicle_relation(potential_vehicle_id, vehicle_record):
```python
# From potential_vehicle record: get participant (provider)
participant = pv_record["vehicle_owner_company_id"] or pv_record["vehicle_owner_user_id"]
# From vehicle record: get owner
vehicle_owner = vehicle_record["created_by_company"] or vehicle_record["created_by"]

if vehicle_owner == participant:
    vehicle_relation = "Owner"   # provider IS the vehicle owner
else:
    vehicle_relation = "Market"  # provider is a 3rd party broker/agent

potential_vehicles_dbh.update_one({"_id": pv_id}, {"$set": {"vehicle_relation": vehicle_relation}})
```
This vehicle_relation field is critical — it determines whether a market_vehicles record needs to be created in Sub-API 5.

On failure → create_trip deletes trip + parcel:
```python
trips_dbh.delete_many({"_id": trip_id})
parcels_dbh.delete_many({"trip_id": trip_id})
```

Returns: potential_vehicle_id

---
### Sub-API 4: POST /submit_offline_bid_by_trip_owner

File: bidding.py:3341

```python
offline_bid_response = requests.post(
    URL + "submit_offline_bid_by_trip_owner",
    json={"potential_vehicle_id": str(potential_vehicle_id), "amount": booking_amount},
    headers=headers, verify=False
)
```

Queries inside:
```
get_document_from_db_by_id("potential_vehicles", potential_vehicle_id)
get_document_from_db_by_id("trips", pv_record["trip_id"])
```

Auth check:
```
check_trips_authorization(login_user_record, trip_record)
# Verifies caller is authorized for this trip (company worker / trip handler / CSR)
```

Guard:
```
is_bidding_scheduled(trip_record)
# If bidding is live/scheduled → 400 "Bidding has not ended yet"
# (Not applicable for fresh create_trip — no bidding scheduled)
```

```python
if pv_record["last_bid"] == amount:
    return 400  # "Amount can't be same as last bid"
```

Write — appends bid to negotiations history and sets last_bid:
```python
potential_vehicles_dbh.find_one_and_update(
    {"_id": pv_record["_id"]},
    {
        "$push": {"bid_negotiations": {"price": booking_amount, "datetime": now, "offline": True}},
        "$set":  {"last_bid": booking_amount}
    },
    return_document=ReturnDocument.AFTER
)
```
bid_negotiations is a full audit trail of every bid round. last_bid is the current agreed price used in purchase order creation.

Then calls update_ranking_of_potential_vehicles(trip_id) (potential_vehicles/common_functions.py:56):

Runs a MongoDB aggregation pipeline on potential_vehicles:
```python
[
  {"$match":   {"trip_id": trip_id, "last_bid": {"$exists": True, "$gt": 0}}},
  {"$sort":    {"last_bid": 1}},           # ascending — cheapest = rank 1
  {"$group":   {"_id": "$trip_id",
                "all_last_bids": {"$push": {"_id": "$_id", "last_bid": "$last_bid"}}}},
  {"$project": {"vehicles": {"$map": {     # compute rank = index + 1
                  "input": "$all_last_bids",
                  "in":    {"_id": "$$vehicle._id", "rank": {"$add": [
                              {"$indexOfArray": ["$all_last_bids.last_bid", "$$vehicle.last_bid"]}, 1
                            ]}}}}}},
  {"$unwind":  "$vehicles"},
  {"$replaceWith": "$vehicles"},
  {"$merge":   {"into": "potential_vehicles", "whenMatched": "merge"}}  # writes rank back
]
```
This writes a rank field back into each potential_vehicles document for this trip.

Back in create_trip — direct write for advance amount (not a sub-API):
```python
if advance_amount:
    potential_vehicles_dbh.update_one(
        {"_id": potential_vehicle_id},
        {"$set": {"advance_amount": advance_amount}}
    )
```

---
### Sub-API 5: POST /award_bidding

File: bidding.py:3405

```python
award_bid_response = requests.post(
    URL + "award_bidding",
    json={"potential_vehicle_id": str(potential_vehicle_id)},
    headers=headers, verify=False
)
```

Queries inside:
```
get_document_from_db_by_id("potential_vehicles", potential_vehicle_id)
get_document_from_db_by_id("trips", pv_record["trip_id"])
```

Guard checks:
```python
if pv_record["vehicle_status"] == "BidAwarded":
    return 400  # "Already awarded"

potential_vehicles_dbh.find_one({
    "trip_id": trip_id, "vehicle_status": "Booked", "_deleted": False
})  # → 400 "There is already a vehicle booked"

potential_vehicles_dbh.find_one({
    "trip_id": trip_id, "vehicle_status": "BidAwarded", "_deleted": False
})  # → 400 "There is already a bid awarded"

if not pv_record.get("last_bid"):
    return 400  # "No charge provided — add offline price first"
```

Writes:
```python
# 1. Mark this potential vehicle as bid-awarded
potential_vehicles_dbh.update_one(
    {"_id": pv_record["_id"]},
    {"$set": {"vehicle_status": "BidAwarded"}}
)

# 2. Advance trip stage to Bidding
if trip_record["trip_stage"] != "TripCanceled":
    trips_dbh.update_one(
        {"_id": trip_id},
        {"$set": {"trip_stage": "Bidding"}}
    )
```

Notifications (only if data_entry is NOT set):
```python
# Resolve vehicle owner's phone number
if pv_record["vehicle_owner_company_id"]:
    phone, type = get_primary_owner_phone_number_or_username(company_id)
    user_record = get_user_by_phone_or_username_from_db(phone_or_username)
    preferred_language = user_record["preferred_language"]
else:
    user_record = get_document_from_db_by_id("users", pv_record["vehicle_owner_user_id"], {"phone":1, "preferred_language":1})
    phone_numbers = [user_record["phone"]["number"]]
    preferred_language = user_record["preferred_language"]

send_bid_awarded_notification(
    phone_numbers, bid_payload, redirect_link,
    [ModeOfNotification.APP, ModeOfNotification.SMS],
    preferred_language
)
```

---
### Optional: POST /market_vehicles (only when vehicle_relation == "Market")

```python
if potential_vehicle_record["vehicle_relation"] == "Market":
    market_vehicle_response = requests.post(URL + "market_vehicles", data={
        "vehicle_id":            vehicle_id,
        "owner_user_id":         vehicle_record["created_by"],
        "owner_company_id":      vehicle_record["created_by_company"],
        "third_party_user_id":   vehicle_provider_user_id,
        "third_party_company_id":vehicle_provider_company_id,
        "requested_start_date":  now_utc,
        "requested_end_date":    now_utc + 7 days
    }, headers=headers, verify=False)
```
Creates a record in market_vehicles collection tracking the relationship between the actual vehicle owner and the third-party who arranged it.

---
### Sub-API 6: POST /award_vehicle

File: bidding.py:1619
Most complex sub-API. Creates the Purchase Order and the financial journal entry.

```python
award_vehicle_response = requests.post(
    URL + "award_vehicle",
    json={"trip_id": str(trip_id), "potential_vehicle_id": str(potential_vehicle_id)},
    headers=headers, verify=False
)
```

Queries inside:
```
get_document_from_db_by_id("trips", trip_id)
potential_vehicles_dbh.find_one({"_id": ObjectId(pv_id), "trip_id": trip_id, "_deleted": False})
get_document_from_db_by_id("vehicles", pv_record["vehicle"])

# If Market vehicle — check status
market_vehicles_dbh.find_one({"vehicle_id": vehicle_id})
# → 400 if status is "Rejected" or "Terminated"

# Check no other vehicle already booked on this trip
potential_vehicles_dbh.find_one({"trip_id": trip_id, "vehicle_status": "Booked", "_deleted": False})

# Validate driver in vehicle crew
# Loops vehicle_record["crew"] to find position == "Driver"
# Gets driver user record for phone number:
get_document_from_db_by_id("users", crew_driver["worker"])
# → 400 if driver has no phone number
```

**Step A — post_purchase_order_record() (trips/common_functions.py:155):**

```python
# Generate unique PO number from counters collection
purchase_order_number = get_next_counter(CountersCategory.PurchaseOrder.value)
# → counters_dbh.find_one_and_update({"category": "PurchaseOrder"}, {"$inc": {"next_sequence": 1}})

post_internal("purchase_orders", {
    "purchase_order_number": purchase_order_number,
    "service_provider": {          # vehicle owner pays service
        "company": pv_record["vehicle_owner_company_id"],
        "user":    pv_record["vehicle_owner_user_id"]
    },
    "service_receiver": {          # RR transporter receives service
        "company": trip_record["created_by_company"],
        "user":    trip_record["created_by"]
    },
    "service_description":  "VehicleBookingServicePurchase",
    "order_date":           booking_date,
    "total_cost":           pv_record["last_bid"],   # = booking_amount
    "currency":             "INR",
    "status":               "Pending",
    "vehicle_number":       vehicle_number,          # from vehicle RC identity
    "trip_id":              pv_record["trip_id"],
    "potential_vehicle":    pv_record["_id"],
    "parcels_involved":     []
})
```

**Step B — Journal Entry (JournalEntry.record_journal_entries()):**

```python
entry = JournalEntry(
    date=booking_date,
    book_owner={
        "user":    trip_record["created_by"],      # RR (buys service)
        "company": trip_record["created_by_company"]
    },
    party={
        "user":    pv_record["vehicle_owner_user_id"],    # vehicle owner (sells service)
        "company": pv_record["vehicle_owner_company_id"]
    },
    note="Vehicle Booking Entry",
    amount=pv_record["last_bid"],
    transaction_type=FinancialTransactionTypes.VehicleBooking,
    payment_status=None,
    payment_medium=None,
    purchase_order_number=purchase_order_number
)
entry.record_journal_entries()
# Creates records in `financial_transactions` collection
# Double-entry: Debit RR (payable to vehicle owner), Credit vehicle owner (receivable from RR)
```

If journal entry fails → purchase order is soft-deleted:
```python
purchase_orders_dbh.update_one({"_id": po_id}, {"$set": {"_deleted": True}})
return 400
```

**Step C — On Success, Three DB writes:**

```python
# 1. Update trip: stage + booked_vehicle + crew
trips_dbh.update_one({"_id": trip_id}, {"$set": {
    "trip_stage":    "VehicleBooking",
    "booked_vehicle": {
        "vehicle":          vehicle_id,
        "vehicle_booked_on": booking_date,
        "booking_id":       pv_record.get("booking_id")
    },
    "crew": [{"worker": driver_id, "position": "Driver"}, ...],
    "updated_by": login_user_id,
    "_updated":   now
}})

# 2. Update potential vehicle: Booked + timestamp
potential_vehicles_dbh.update_one({"_id": pv_id}, {"$set": {
    "vehicle_status": "Booked",
    "flags.booked":   booking_date
}})

# 3. Push trip into vehicle's current_trips array
vehicles_dbh.update_one({"_id": vehicle_id}, {"$push": {
    "current_trips": {
        "trip_id":       trip_id,
        "booking_id":    booking_id,
        "current_stage": "VehicleBooking"
    }
}})
```

Notifications (only if data_entry NOT set):
```python
# "Booking Confirmed" → vehicle owner (SMS + App)
send_booking_confirmed_notification(phone_numbers, bid_payload, redirect_link, ...)

# "POD Submission Warning" → vehicle owner + driver (SMS + App)
phone_numbers.append(driver_phone_number)
send_pod_submission_warning_notification(phone_numbers, ...)

# "RR Brokerage Warning" → only if consignor is Berger Paints
if sender_company == berger_company_id:
    send_rr_brokerage_warning_notification(...)
```
Also: trip_index_dbh.delete_one({"trip_id": trip_id}) — clears stale trip index before rebuild.

---
### Sub-API 7: POST /record_trip_expense (only if loading_amount > 0)

File: trips/app.py:9652

```python
loading_expense_response = requests.post(URL + "record_trip_expense", json={
    "expense_type":    "Loading",
    "order_date":      datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
    "service_provider": None,      # ← no provider yet, so no journal entry
    "amount":          loading_amount,
    "remark":          "Loading expense",
    "photo":           "",
    "trip_id":         str(trip_id),
    "service_receiver": {
        "company": str(transporter_company_id),
        "user":    str(login_user_id)
    }
}, headers=headers, verify=False)
```

create_trip_expense_and_initial_transaction() (trips/app.py:9823):
```python
# Insert into third_party_expenses via Eve
post_internal("third_party_expenses", trip_expense_payload)
# Since order_creation = False (no service_provider):
third_party_expenses_dbh.update_one({"_id": expense_id}, {"$set": {
    "balances": {
        "total_payable_amount":      loading_amount,
        "to_be_paid_amount":         loading_amount,
        "actual_to_be_paid_amount":  loading_amount,
        "already_paid_amount":       0,
        "tds_deduction":             0,
        "payment_allocated_from_bulk_payment": 0,
        "pending_payment_sheet_balance":       0
    },
    "status": "Pending"
}})
# No JournalEntry created yet — happens later when service_provider is assigned
```

---
### Sub-API 8: POST /post_extra_vehicle_charges (only if unloading_amount > 0 or diesel_charges > 0)

File: trips/app.py:2413

```python
unloading_vehicle_charges_response = requests.post(URL + "post_extra_vehicle_charges", json={
    "trip_id":             str(trip_id),
    "extra_weight_charges": 0,
    "extra_distance_charges": 0,
    "halting_charges":     0,
    "hamali_charges":      unloading_amount,   # unloading → hamali
    "other_charges":       0,
    "vehicle_brokerage_charges": 0,
    "insurance_amount":    0,
    "no_diesel_taken_penalty": 0,
    "diesel_charges":      diesel_charges,
    "remark":              [""]
}, headers=headers, verify=False)
```

Idempotent charge difference calculation:
```python
current_extra_charges = (
    extra_weight_charges + extra_distance_charges + halting_charges
    + hamali_charges + other_charges
    - vehicle_brokerage_charges - insurance_amount
    - no_diesel_taken_penalty - diesel_charges
)
charge_difference = current_extra_charges - earlier_extra_charges
# If charge_difference == 0 → returns 200 immediately, no writes
```

Three writes on non-zero difference: trips.booked_vehicle breakdown, purchase_orders.extra_charges, financial_transactions journal entry.

---
## Final Response

```json
{
  "statusText":          "Trip created successfully.",
  "trip_id":             "ObjectId  → trips collection _id",
  "potential_vehicle_id":"ObjectId  → potential_vehicles collection _id",
  "parcel_id":           "ObjectId  → parcels collection _id",
  "booking_id":          "integer   → potential_vehicles.booking_id counter (NOT purchase_orders)"
}
```

> `booking_id` is an auto-incremented integer from `counters` collection (category: "vehicle booking"),
> set by the `before_insert_potential_vehicle` hook. It lives on the `potential_vehicles` document.
>
> Compass queries:
> - Find by booking_id:  `{ "booking_id": 10004396 }`  on `potential_vehicles`
> - Find PO for trip:    `{ "trip_id": { "$oid": "<rr_trip_id>" } }`  on `purchase_orders`

---
## Complete DB Write Map

| Step | Function | Collections Written | What is written |
|------|----------|---------------------|-----------------|
| 1.9 | Driver assignment | vehicles | crew array — new Driver entry |
| Sub-API 1 | before_insert_trips | companies or counters | book_counter.trip incremented |
| Sub-API 1 | Eve insert | trips | Full trip document + 12 stages |
| Sub-API 1 | actions_after_insert_trip | trips | _created backdated |
| Sub-API 2 | Eve insert | parcels | Full parcel document |
| Sub-API 2 | after_inserted_parcel | parcels, trip_indexes | _created backdated; trip index rebuilt |
| Sub-API 2 | Freight write | parcels | charges.freight_charges |
| Sub-API 3 | save_potential_vehicle | potential_vehicles | New PV record with ToBeHired status + vehicle_relation |
| Sub-API 4 | submit_offline_bid | potential_vehicles | bid_negotiations appended, last_bid set |
| Sub-API 4 | update_ranking | potential_vehicles | rank field on all PVs for trip |
| Sub-API 4 | Advance write | potential_vehicles | advance_amount |
| Sub-API 5 | award_bidding | potential_vehicles, trips | vehicle_status = BidAwarded; trip_stage = Bidding |
| Optional | market_vehicles | market_vehicles | Market vehicle agreement record |
| Sub-API 6 | post_purchase_order_record | counters, purchase_orders | PO counter incremented; PO document inserted |
| Sub-API 6 | JournalEntry | financial_transactions | Vehicle booking debit/credit entries |
| Sub-API 6 | Award writes | trips, potential_vehicles, vehicles | trip_stage=VehicleBooking, booked_vehicle; status=Booked; current_trips pushed |
| Sub-API 7 | record_trip_expense | counters, third_party_expenses | Expense counter incremented; expense doc with Pending status + balances |
| Sub-API 8 | post_extra_vehicle_charges | trips, purchase_orders, financial_transactions | Charge breakdown written; PO extra_charges updated; journal entry for difference |

Up to 10 collections written in a single POST /create_trip call.

---
## Prerequisites

The only prerequisite is that the user must be authenticated (needs a valid JWT access_token), so RR4 needs to call the login flow first:

1. GET /persons/authenticate (Basic Auth with phone+password) — gets tokens
2. POST /create_trip — creates the trip
