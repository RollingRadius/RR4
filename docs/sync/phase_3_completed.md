# Phase 3 Completed — Stage 2 Refactor (Loading Slip Merge)

## Status: DONE
Completed 2026-05-23.

## Files Changed

### Backend
- `backend/app/api/v1/trips.py`
  - Removed `Stage2Payload` Pydantic class
  - Converted `submit_stage2` from `def` (JSON) → `async def` (multipart Form + File)
  - Added loading slip save logic inside Stage 2 (same pattern as Stage 1)
  - Removed separate `/trips/{id}/loading-slip` endpoint

### Frontend
- `frontend/lib/providers/trip_stages_provider.dart`
  - `submitStage2(Map data)` → `submitStage2(FormData formData)`
- `frontend/lib/presentation/screens/fleet_owner/trip_stages_screen.dart`
  - Added `XFile? _loadingSlipFile` state to `_Stage2FormState`
  - Added `_pickLoadingSlip()` + `_showSlipPicker()` methods
  - Added loading slip picker UI card between entry permission and submit button
  - Changed `_submit()` to build `FormData` (booleans as strings + optional file)

## Behavior After This Phase
- Stage 2 endpoint accepts `multipart/form-data` (consistent with S1 and S3)
- Loading slip is OPTIONAL at Stage 2 submission
- If loading slip uploaded in Stage 2 → `s2_loading_slip_url` set, `_LoadingSlipMini` skipped
- If not uploaded → `_LoadingSlipMini` still appears (backward compat for old trips)
- Transporter `/transporter-loading-slip` endpoint untouched

## Verification
- `python -c "from app.api.v1 import trips; print('OK')"` passes
- Stage 2 form now shows loading slip card before submit button
- Submitting Stage 2 without slip works (slip is optional)
- Submitting Stage 2 with slip sets `s2_loading_slip_url` on the trip

## Next: Phase 4
Build `rr_sync_service.py` with `sync_trip_to_rr()` and trigger it on Stage 2 submission.
