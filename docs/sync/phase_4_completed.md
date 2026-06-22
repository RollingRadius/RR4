# Phase 4 Completed — Sync Service Core

## Status: DONE
Completed 2026-05-23.

## Files Changed
- `backend/app/services/rr_sync_service.py` (new) — full sync logic
- `backend/app/api/v1/trips.py` — BackgroundTasks trigger in submit_stage2 + transporter endpoint
- `backend/app/api/v1/rr_sync.py` — manual trigger endpoint wired up

## How sync works
1. Stage 2 submitted with loading slip (LP) OR transporter uploads loading slip
2. After DB commit → BackgroundTasks fires `sync_trip_to_rr(trip_id)`
3. Pre-flight checks all required RR ObjectIds — fails gracefully if any missing
4. POST /create_trip → stores rr_trip_id + rr_parcel_id
5. GET /trips + GET /parcels → stores rr_trip_number + rr_parcel_etag
6. Uploads loading slip to RR /files → POST /post_loading_slip
7. rr_sync_status progresses: not_synced → trip_created → loading_slip_synced

## rr_sync_status values
| Status | Meaning |
|--------|---------|
| not_synced | Never attempted |
| trip_created | Trip + parcel created in RR, loading slip not yet synced |
| loading_slip_synced | Full Stage 2 sync complete |
| bilty_synced | Stage 3 synced (Phase 6) |
| pod_synced | Stage 5 synced (Phase 6) |
| failed | Check rr_sync_error column for reason |

## What causes "failed"
- Any required RR ID missing (see preflight list in plan)
- RR token not available
- RR API returned non-2xx
- Network/timeout error

## Manual retry
`POST /api/rr/sync/trip/{trip_id}` — resets failed status and re-triggers sync

## To enable (requires token)
1. Set RR_REFRESH_TOKEN in .env on server
2. Set RR_SYNC_ENABLED=true
3. Restart backend

## Next: Phase 5
Vehicle + driver RR ID resolution (lookup by plate/phone in RR).
Org rr_company_id admin UI field.
