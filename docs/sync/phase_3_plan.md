# Phase 3 Plan — Stage 2 Refactor (Loading Slip Merge)

## Goal
Convert Stage 2 from JSON body to multipart form-data and include loading slip
upload directly in Stage 2 submission. This makes Stage 2 consistent with
Stage 1 and Stage 3, and creates a single clean sync trigger point for Phase 4.

## Files that will be touched
- `backend/app/api/v1/trips.py`
  - Remove `Stage2Payload` Pydantic class
  - Convert `submit_stage2` from JSON → multipart (Form fields + optional UploadFile)
  - Add loading slip save logic inside Stage 2
  - Remove separate `/loading-slip` endpoint
- `frontend/lib/providers/trip_stages_provider.dart`
  - Change `submitStage2(Map data)` → `submitStage2(FormData formData)`
- `frontend/lib/presentation/screens/fleet_owner/trip_stages_screen.dart`
  - `_Stage2FormState`: add `XFile? _loadingSlipFile` state + `_pickLoadingSlip()`
  - Add loading slip picker UI between entry permission and submit button
  - Change `_submit()` to build FormData instead of Map

## Backward compat
- Loading slip is OPTIONAL in Stage 2 (not required at submission)
- `_LoadingSlipMini` widget still shows if `s2_loading_slip_url == null` after Stage 2
  (handles existing trips and users who skip slip in Stage 2)
- Transporter's `/transporter-loading-slip` endpoint is NOT touched

## After this phase
- Stage 2 submission = multipart (same as S1 and S3)
- Loading slip can be uploaded in one shot with Stage 2
- Phase 4 will fire sync when Stage 2 is submitted AND loading slip is present
