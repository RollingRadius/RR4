# Phase 1 Completed — Database Migrations

## Status: DONE
Applied on test server (35.244.19.78) on 2026-05-23. Migration head: `058`.

## Files Changed

### New migration files
- `backend/alembic/versions/054_rr_sync_org.py` — organizations.rr_company_id
- `backend/alembic/versions/055_rr_sync_vehicle.py` — vehicles.rr_vehicle_id
- `backend/alembic/versions/056_rr_sync_driver.py` — drivers.rr_user_id
- `backend/alembic/versions/057_rr_sync_trips.py` — 13 RR sync columns on trips
- `backend/alembic/versions/058_rr_material_types.py` — new material_types table

### Updated models
- `backend/app/models/company.py` — added `rr_company_id`
- `backend/app/models/vehicle.py` — added `rr_vehicle_id`
- `backend/app/models/driver.py` — added `rr_user_id`
- `backend/app/models/trip.py` — added 13 RR sync columns
- `backend/app/models/material_type.py` — new MaterialType model
- `backend/app/models/__init__.py` — imported MaterialType

## New Columns

### organizations
| Column | Type | Default |
|--------|------|---------|
| rr_company_id | VARCHAR(24) | NULL |

### vehicles
| Column | Type | Default |
|--------|------|---------|
| rr_vehicle_id | VARCHAR(24) | NULL |

### drivers
| Column | Type | Default |
|--------|------|---------|
| rr_user_id | VARCHAR(24) | NULL |

### trips
| Column | Type | Default |
|--------|------|---------|
| origin_rr_city_id | VARCHAR(24) | NULL |
| destination_rr_city_id | VARCHAR(24) | NULL |
| material_rr_id | VARCHAR(24) | NULL |
| weight_value | NUMERIC(10,3) | NULL |
| weight_unit | VARCHAR(10) | NULL |
| invoice_value | NUMERIC(12,2) | NULL |
| rr_trip_id | VARCHAR(24) | NULL |
| rr_trip_number | VARCHAR(30) | NULL |
| rr_parcel_id | VARCHAR(24) | NULL |
| rr_parcel_etag | VARCHAR(100) | NULL |
| rr_sync_status | VARCHAR(30) | 'not_synced' |
| rr_sync_error | TEXT | NULL |
| rr_synced_at | TIMESTAMP | NULL |

### material_types (new table)
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | gen_random_uuid() |
| name | VARCHAR(100) | UNIQUE NOT NULL |
| rr_material_id | VARCHAR(24) | NULL — MongoDB ObjectId from RR |
| created_at | TIMESTAMP | NOW() |

## Verification
- alembic head = `058` confirmed on server
- `material_types` table visible in DB table list
- API health check passed
- DB backup created: `db_backup_20260523_123945.sql`
- All existing data unaffected (all new columns nullable)

## Next: Phase 2
Backend proxy endpoints + RR config vars + token refresh service.
