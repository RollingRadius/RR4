# Phase 2 Completed — Backend Proxy Endpoints + Config + Token Service

## Status: DONE
Completed 2026-05-23.

## Files Changed
- `backend/app/config.py` — added RR_API_BASE, RR_REFRESH_TOKEN, RR_SYNC_ENABLED, RR_SSL_VERIFY
- `backend/app/services/rr_token_service.py` (new) — background token refresh every 14 min
- `backend/app/api/v1/rr_sync.py` (new) — proxy + status endpoints
- `backend/app/main.py` — registered rr_sync router at /api/rr, wired startup/shutdown
- `backend/.env` — added RR vars (RR_SYNC_ENABLED=false, RR_REFRESH_TOKEN empty)

## New Endpoints

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/rr/cities?q=<name>` | Proxies to RR /cities. Returns [] if sync disabled or city not found. Non-fatal. |
| GET | `/api/rr/materials?q=<name>` | Queries local material_types table. Always fast. |
| GET | `/api/rr/sync/status/{trip_id}` | Returns rr_sync_status, rr_trip_id, rr_parcel_id, etc. |
| POST | `/api/rr/sync/trip/{trip_id}` | Stub — wired in Phase 4 |

## Token Service Behaviour
- `RR_SYNC_ENABLED=false` → token service skips entirely, city proxy returns []
- `RR_SYNC_ENABLED=true` + `RR_REFRESH_TOKEN` set → refreshes token on startup then every 14 min
- All RR API calls use `rr_token_service.get_access_token()` for the Bearer token

## To Enable RR Sync (after getting a token)
1. Log in to RR once via OTP on any device
2. Copy `refresh_token` from the login response
3. Set on server: `RR_REFRESH_TOKEN=<token>` and `RR_SYNC_ENABLED=true` in .env
4. Restart backend: `docker restart fleet_backend`

## Verification
- `python -c "from app.api.v1 import rr_sync; print('OK')"` passes
- `GET /api/rr/materials` returns [] (table empty, seeded in Phase 5)
- `GET /api/rr/sync/status/<valid_trip_id>` returns sync fields (all null/not_synced)
- Swagger at `/docs` shows "RR Sync" tag with 4 endpoints

## Next: Phase 3
Convert Stage 2 from JSON body to multipart form-data and merge loading slip upload into it.
