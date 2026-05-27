# Phase 4 Plan — Sync Service Core

## Goal
Build rr_sync_service.py with sync_trip_to_rr() and trigger it as a FastAPI
background task after Stage 2 submission (LP or Transporter) when a loading slip is present.

## Files that will be touched
- `backend/app/services/rr_sync_service.py` (new) — core sync logic
- `backend/app/api/v1/trips.py` — add BackgroundTasks to submit_stage2 + transporter endpoint
- `backend/app/api/v1/rr_sync.py` — wire up the manual trigger stub

## Sync flow (sync_trip_to_rr)
1. Pre-flight: check all required RR IDs present. If any missing → status=failed, log what's missing.
2. POST /create_trip → get {trip_id, parcel_id}
3. GET /trips/{trip_id} → get rr_trip_number + trip _etag
4. GET /parcels/{parcel_id} → get parcel _etag
5. Store: rr_trip_id, rr_trip_number, rr_parcel_id, rr_parcel_etag, status=trip_created
6. If s2_loading_slip_url set:
   a. Read file from local UPLOAD_DIR
   b. POST /files (multipart) → get rr_file_id
   c. POST /post_loading_slip {trip_id, loading_slip: rr_file_id}
   d. status=loading_slip_synced

## Required RR IDs (all must be non-null to sync)
- trip.load_owner_org.rr_company_id — consignor
- trip.organization.rr_company_id — vehicle_provider
- trip.vehicle.rr_vehicle_id
- trip.driver.rr_user_id
- trip.origin_rr_city_id
- trip.destination_rr_city_id
- trip.material_rr_id
- trip.weight_value + trip.weight_unit

## Trigger points
- submit_stage2: after commit, if s2_loading_slip_url set AND RR_SYNC_ENABLED
- transporter_upload_loading_slip: after commit, if RR_SYNC_ENABLED

## Not in Phase 4 (deferred)
- human_trip_number PATCH on RR trip (needs separate PATCH with _etag — Phase 6)
- Stage 3 bilty sync
- Stage 5 POD sync
- Vehicle/driver RR ID auto-resolution (Phase 5)
