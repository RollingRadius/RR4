# RR Sync — Feature Changelog
**Branch:** `feature/rr-sync`
**Base:** `main`

---

## Completed

### Phase 1 — Database Migrations (`f4b76a7`)
- Migrations 054–059 (head = 059)
- `organizations.rr_company_id VARCHAR(24)` — LP and Load Owner org mapping to RR
- `vehicles.rr_vehicle_id VARCHAR(24)` — auto-resolved at sync time
- `drivers.rr_user_id VARCHAR(24)` — auto-resolved at sync time
- `trips` — 14 new RR columns: city ObjectIds, material ObjectId, weight, invoice, RR trip/parcel references, sync status/error/timestamp
- `material_types` table (migration 058) — exists but no longer queried (see Updates)
- `trips.s3_loaded_weight_slip_url` (migration 059)

### Phase 2 — Backend Proxy Endpoints + Token Service (`2c37a57`)
- `rr_token_service.py` — background refresh loop (10 min, 60s retry on failure)
- `RR_API_BASE`, `RR_SYNC_ENABLED`, `RR_SSL_VERIFY`, `RR_REFRESH_TOKEN` config entries
- `GET /api/rr/cities` — public proxy to RR `/cities`
- `GET /api/rr/materials` — live proxy to RR `/material_types` (public)
- `POST /api/rr/auth/login` — proxies RR Basic Auth, returns short-lived token
- `GET /api/rr/sync/status/{id}` — returns current sync state for a trip
- `GET /api/rr/sync/ready` — lists ready + incomplete trips for LP
- `POST /api/rr/sync/trip/{id}` — triggers BackgroundTask sync with LP's RR token
- `POST /api/rr/sync/bulk` — bulk sync using global `RR_REFRESH_TOKEN`

### Phase 3 — Stage 2 Multipart Refactor (`6b2349f`, `981d823`)
- Loading slip merged into S2 submit (single multipart endpoint)
- Thumbnail preview for loading slip in S2 form
- `s2_loading_slip_url` stored and visible in trip stages

### Phase 4 — Sync Service Core (`6be18a2`, `1ac4969`)
- `rr_sync_service.sync_all_to_rr(trip_id, rr_token)` — single entry point
- Step 1: Phase 5 auto-resolve IDs → pre-flight check → `POST /create_trip`
- Step 2: Upload loading slip → `POST /post_loading_slip`
- Step 3: S3 bilty number + bilty photo + loaded weight slip + material docs → `PATCH /parcels`
- Step 4: S5 POD → `PATCH /parcels`
- ETag concurrency handled — re-fetched before every PATCH
- `rr_sync_status` flow: `not_synced → trip_created → loading_slip_synced → bilty_synced → pod_synced | failed`
- **No auto-triggers** — `trips.py` stage submit functions have zero sync calls

### Phase 5 — Vehicle / Driver RR ID Auto-Resolution (within Phase 4)
- `_try_resolve_rr_ids` — queries RR at sync time
  - Vehicle: `GET /vehicles?where={"rc_number": plate}` → caches `rr_vehicle_id`
  - Driver: `GET /users?where={"phone.number": 10digit}` → caches `rr_user_id`
- Silent failures — pre-flight check catches still-missing IDs

### Phase 6 — S3 + S5 Document Sync (within Phase 4)
- `_sync_stage3`: PATCH parcel with bilty number, loaded weight slip photo, material docs (first 2)
- `_attach_bilty_photo_to_trip`: appends bilty photo to `trip.trip_documents` array
- `_sync_stage5`: PATCH parcel with POD photo
- `s3_loaded_weight_slip_url` column (migration 059) + upload UI in S3 form

### Phase 7 — Flutter Trip Creation RR Fields
- `CreateTripScreen`: city typeahead (`/api/rr/cities`), material search (`/api/rr/materials`), weight + unit field, invoice_value field
- `_FulfillSheet` (load requirement fulfillment): same RR fields, pre-populated from load requirement
- Cities stored as ObjectIds in `origin_rr_city_id` / `destination_rr_city_id`
- Material stored as ObjectId in `material_rr_id`
- `TripModel` updated with all RR fields (`originRrCityId`, `materialRrId`, `weightValue`, `weightUnit`, `invoiceValue`)

### Phase 8 — Flutter RR Sync Manager (`68566c8`, `b73aa34`)
- LP dashboard top-right sync button → `showRrSyncSheet(context)` → `DraggableScrollableSheet`
- **"Ready to Sync"** section — trips with all required IDs
- **"Uploads Incomplete"** section — trips missing RR IDs, shows which fields are missing
- Tap a ready trip → `_RrLoginDialog` → `POST /api/rr/auth/login` → token → `POST /api/rr/sync/trip/{id}`
- Spinner on tile while syncing (`syncingTripId` state)
- Pull-to-refresh, success/error snackbars
- `TripStagesScreen` AppBar sync button (secondary path — same login flow, syncs current trip directly)
- `rr_sync_screen.dart`, `rr_sync_provider.dart`, `rr_sync_api.dart`

---

## Updated

### Material Types — Local DB → Live RR Proxy
- `GET /api/rr/materials` previously queried local `material_types` PostgreSQL table
- Now proxies live to RR `GET /material_types` (public endpoint, no auth required)
- `material_types` table still exists (migration 058) but is no longer queried
- Seed scripts (`seed_material_types.py`, `seed_material_types.sql`) deleted — no longer needed

### Sync Sheet UX — Bulk → Per-Trip Login
- Previous design: checkboxes + "Sync selected" bulk button
- New design: tap a single trip → login dialog → sync that trip
- `rr_sync_provider`: removed `selectedIds`, `selectAll`, `syncSelected` — replaced with `syncTrip(tripId, token)`
- `rr_sync_api`: removed `triggerBulkSync` — replaced with `loginToRr` + `triggerTripSync`

### Route Prefix — All Flutter Files
- All Flutter files previously called `/api/v1/rr/` — corrected to `/api/rr/` throughout
- Affected: `trip_stages_screen.dart`, `logistic_partner_dashboard.dart`, `create_trip_screen.dart`

### Readiness Check — Skip for Trips Already in RR
- `_check_trip_readiness` previously ran all 8 ID checks regardless of sync state
- Trips with `rr_parcel_id` already set (in RR) now always return `ready=True`
- Prevents false "Uploads Incomplete" for partially-synced trips

---

## Fixed

| # | What | Where |
|---|------|--------|
| 1 | `human_trip_number` missing from `create_trip` payload | `rr_sync_service.py` |
| 2 | Token refresh interval was 14 min (access token expires at 15 min) → now 10 min with 60s retry | `rr_token_service.py` |
| 3 | Route prefix `/api/v1/rr/` → `/api/rr/` across all Flutter files | `trip_stages_screen.dart`, `logistic_partner_dashboard.dart`, `create_trip_screen.dart` |
| 4 | Cities proxy called `_rr_headers()` which required global token — cities is public on RR | `rr_sync.py` |
| 5 | Dead code: `_rr_headers()` function and `rr_token_service` import in `rr_sync.py` | `rr_sync.py` |
| 6 | `_StatusChip` in sync sheet had no case for `bilty_synced` — showed raw string | `rr_sync_screen.dart` |
| 7 | `get_sync_ready` docstring incorrectly stated `loading_slip_synced`/`bilty_synced` were excluded | `rr_sync.py` |
| 8 | `trigger_sync` had no org ownership check — any user could trigger sync on any trip | `rr_sync.py` |
| 9 | `get_sync_status` had no org ownership check — any user could read sync state of any trip | `rr_sync.py` |

---

## Pending (Phase 9)

- **Company picker UI** — `GET /api/rr/companies?q=` proxy + org settings screen to search and set `rr_company_id` on LP and Load Owner orgs. Currently requires manual SQL update.

---

## Deployment (fc11 test server — requires SSH)

1. Pull `feature/rr-sync` on RR4 container
2. `alembic upgrade head`
3. Set `RR_SYNC_ENABLED=true` in `.env`, restart backend
4. Set `rr_company_id` on both LP and Load Owner orgs via pgAdmin SQL (`http://35.244.19.78:5050`) — get ObjectIds from Mongo Express (`http://35.244.19.78:8041`)
5. Pull `test/release-3.18.3.7` on RR container (already has all `feature/rr4-sync` changes)
