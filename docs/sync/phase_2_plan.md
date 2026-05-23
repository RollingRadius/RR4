# Phase 2 Plan — Backend Proxy Endpoints + Config + Token Service

## Goal
Add RR config vars, a background token refresh service, and proxy/query endpoints
so RR4 backend can communicate with RR's API without any frontend knowing RR exists.

## Files that will be touched
- `backend/app/config.py` — add RR_API_BASE, RR_REFRESH_TOKEN, RR_SYNC_ENABLED
- `backend/app/services/rr_token_service.py` (new) — background RR token refresh
- `backend/app/api/v1/rr_sync.py` (new) — proxy + status endpoints
- `backend/app/main.py` — import new router, start token refresh on startup
- `backend/.env` — add placeholder RR vars
- `backend/.env.docker` — add placeholder RR vars

## New endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/rr/cities?q=<name>` | Proxy to RR /cities, returns _id + name matches |
| GET | `/api/rr/materials?q=<name>` | Query local material_types table |
| GET | `/api/rr/sync/status/{trip_id}` | Return trip's current rr_sync_status + ids |
| POST | `/api/rr/sync/trip/{trip_id}` | Manually trigger sync (stub — Phase 4 wires it up) |

## Token refresh logic
- On startup: read RR_REFRESH_TOKEN from env
- If RR_SYNC_ENABLED=false: skip entirely
- Background asyncio task: every 14 min call POST {RR_API_BASE}/persons/refresh
- Store current access_token in module-level variable (in-memory)
- All RR API calls go through `rr_token_service.get_access_token()`

## New config vars
| Var | Default | Notes |
|-----|---------|-------|
| RR_API_BASE | https://35.244.19.78:8042 | Switch to prod URL when going live |
| RR_REFRESH_TOKEN | "" | Obtained via one-time OTP login on RR |
| RR_SYNC_ENABLED | false | Set true once token is configured |
| RR_SSL_VERIFY | false | Test server uses self-signed cert |
