# Phase 1 Plan — Database Migrations

## Goal
Add all columns and tables needed for RR↔RR4 sync, with zero breaking changes.
All new columns are NULLABLE. Existing data is never touched.

## Migrations to create (RR4 PostgreSQL only)

| # | File | Table | Change |
|---|------|-------|--------|
| 054 | `054_rr_sync_org.py` | `organizations` | Add `rr_company_id VARCHAR(24)` |
| 055 | `055_rr_sync_vehicle.py` | `vehicles` | Add `rr_vehicle_id VARCHAR(24)` |
| 056 | `056_rr_sync_driver.py` | `drivers` | Add `rr_user_id VARCHAR(24)` |
| 057 | `057_rr_sync_trips.py` | `trips` | Add 13 RR sync columns (city ids, material id, weight, invoice_value, trip/parcel cross-refs, sync state) |
| 058 | `058_rr_material_types.py` | NEW `material_types` | New table with name + rr_material_id |

## Files that will be touched
- `D:/RR4/backend/alembic/versions/054_rr_sync_org.py` (new)
- `D:/RR4/backend/alembic/versions/055_rr_sync_vehicle.py` (new)
- `D:/RR4/backend/alembic/versions/056_rr_sync_driver.py` (new)
- `D:/RR4/backend/alembic/versions/057_rr_sync_trips.py` (new)
- `D:/RR4/backend/alembic/versions/058_rr_material_types.py` (new)
- `D:/RR4/backend/app/models/company.py` (add rr_company_id column)
- `D:/RR4/backend/app/models/vehicle.py` (add rr_vehicle_id column)
- `D:/RR4/backend/app/models/driver.py` (add rr_user_id column)
- `D:/RR4/backend/app/models/trip.py` (add 13 RR sync columns)
- `D:/RR4/backend/app/models/__init__.py` (import new MaterialType model)
- `D:/RR4/backend/app/models/material_type.py` (new model file)

## New columns detail

### organizations
- `rr_company_id VARCHAR(24)` — MongoDB ObjectId of this org in RR. Admin sets once per org.

### vehicles
- `rr_vehicle_id VARCHAR(24)` — MongoDB ObjectId in RR. Cached on first vehicle lookup/create in RR.

### drivers
- `rr_user_id VARCHAR(24)` — MongoDB user ObjectId in RR. Looked up by phone number.

### trips (13 columns)
- `origin_rr_city_id VARCHAR(24)` — RR city ObjectId for origin
- `destination_rr_city_id VARCHAR(24)` — RR city ObjectId for destination
- `material_rr_id VARCHAR(24)` — RR material_type ObjectId
- `weight_value NUMERIC(10,3)` — structured weight (replaces free-text `weight`)
- `weight_unit VARCHAR(10)` — 'KG' | 'TONS' | 'QUINTAL'
- `invoice_value NUMERIC(12,2)` — required by RR, missing in RR4
- `rr_trip_id VARCHAR(24)` — RR MongoDB trip _id
- `rr_trip_number VARCHAR(30)` — RR generated number e.g. "rr1235"
- `rr_parcel_id VARCHAR(24)` — RR parcel _id (auto-created with trip)
- `rr_parcel_etag VARCHAR(100)` — current ETag for PATCH concurrency control
- `rr_sync_status VARCHAR(30)` — not_synced | trip_created | loading_slip_synced | bilty_synced | pod_synced | failed
- `rr_sync_error TEXT` — last sync error message
- `rr_synced_at TIMESTAMP` — when last sync action completed

### material_types (new table)
- `id UUID PK`
- `name VARCHAR(100) UNIQUE NOT NULL`
- `rr_material_id VARCHAR(24)` — MongoDB ObjectId from RR's material_types collection
- `created_at TIMESTAMP`

## How to verify after completion
1. `alembic upgrade head` completes with no errors
2. pgAdmin at `35.244.19.78:5050` shows new columns on all 4 tables
3. `material_types` table exists (empty — to be seeded in Phase 5)
4. All existing trip/vehicle/driver/org rows unaffected (all new cols = NULL)
