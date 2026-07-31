/// RR web trip stages screen — the S1-S5 process, checkboxes, uploads, and
/// per-stage RR doc sync, used exclusively for trips synced to RollingRadius
/// web. Deliberately a full, independent copy of trip_stages_screen.dart (the
/// app's original/classic stages screen) rather than a themed variant of it —
/// the two are kept fully separate on purpose, so a fix or change to one
/// never risks the other, and it's obvious at a glance (blue/orange RR theme
/// here vs. classic orange there) which flow you're looking at or debugging.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/providers/trip_stages_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/presentation/screens/shared/truck_tracking_screen.dart';
import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';
import 'package:fleet_management/presentation/widgets/rr_search_field.dart';
import 'package:fleet_management/providers/notification_provider.dart';
import 'package:fleet_management/data/models/notification_model.dart';

// ─── Typography & Colours ─────────────────────────────────────────────────────
TextStyle _manrope({double size = 14, FontWeight weight = FontWeight.w600, Color color = const Color(0xFF191C1E)}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter({double size = 13, FontWeight weight = FontWeight.w400, Color color = const Color(0xFF546067)}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

/// Shared message for a failed image_picker call (camera/gallery permission
/// denied, or any other picker failure) — used wherever a doc-upload widget
/// doesn't already keep its own dedicated inline error-message state.
String _pickErrorMessage(Object e, ImageSource source) {
  final isCamera = source == ImageSource.camera;
  return e is PlatformException && e.code.contains('access_denied')
      ? 'Permission denied. Enable ${isCamera ? "Camera" : "Photos"} access for this app in Settings and try again.'
      : 'Could not ${isCamera ? "open camera" : "access gallery"}. Please try again.';
}

/// Shows [_pickErrorMessage] as a SnackBar — for pickers with no local
/// inline error-text widget to fall back on.
void _showPickError(BuildContext context, Object e, ImageSource source) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(_pickErrorMessage(e, source), style: _inter(size: 13, color: Colors.white)),
      backgroundColor: _error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

const _primary   = Color(0xFFFF6B00);
const _bg        = Color(0xFFF8F9FB);
const _surface   = Color(0xFFFFFFFF);
const _secondary = Color(0xFF546067);
const _onSurface = Color(0xFF191C1E);
const _success   = Color(0xFF006B5E);
const _error     = Color(0xFFBA1A1A);
const _border    = Color(0xFFECEEF0);

// ─── RR-web vs classic stage-screen theme ────────────────────────────────────
// RR-web trips (trip.rrTripId != null — same signal _RrPerStageSyncPanel uses)
// get a distinct blue/orange look, matching RrTripCard's dashboard theme, so
// they're visually distinguishable from the app's original stage UI. Success
// green is shared by both — it already reads as "done" everywhere.
class _StageTheme {
  final Color primary;
  final Color accent;
  const _StageTheme({
    required this.primary,
    required this.accent,
  });

  // Light blue primary (softer than RrTripCard's 0xFF1B6CA8), light orange accent
  // (echoes the classic screen's orange so the two still feel like the same app).
  static const rrWeb = _StageTheme(
    primary: Color(0xFF4A90C4),
    accent: Color(0xFFFFA556),
  );
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class RrTripStagesScreen extends ConsumerStatefulWidget {
  final TripModel trip;
  /// Visual stage index (0–4) to open directly for editing. Null = default flow.
  final int? initialStage;
  /// True when opened from Records by LP/RR-ops — every stage renders with its
  /// final data but nothing is tappable/editable (no submit, upload, or sync).
  final bool readOnly;
  const RrTripStagesScreen({super.key, required this.trip, this.initialStage, this.readOnly = false});

  @override
  ConsumerState<RrTripStagesScreen> createState() => _RrTripStagesScreenState();
}

class _RrTripStagesScreenState extends ConsumerState<RrTripStagesScreen> {
  late TripModel _trip;           // always the freshest copy
  late (String, int) _providerKey;
  int _tripFreshness = 0;         // increments when fresh data arrives → stage forms rebuild
  bool _fetchingFresh = false;
  bool _showStage4 = false;
  bool _stage4Done = false;
  bool _stage5Done = false;
  bool _syncing = false;
  /// Non-null when re-editing a completed stage (visual dot index 0-5).
  int? _editingStage;
  StreamSubscription<NotificationModel>? _driverReassignSub;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _providerKey = (_trip.id, _trip.currentStage);
    if (_trip.currentStage >= 5) {
      _showStage4 = true;
      _stage4Done = true;
      _stage5Done = true;
    } else if (_trip.currentStage >= 4 && _trip.s4DieselReceiptUrl != null) {
      _showStage4 = true;
      _stage4Done = true;
    } else if (_trip.currentStage >= 4) {
      _showStage4 = true; // checklist done, diesel still needed
    }
    // If opened at a specific stage from the sliding panel, jump there directly.
    if (widget.initialStage != null) {
      _editingStage = widget.initialStage;
      if (widget.initialStage == 4) _showStage4 = true;
    }
    // Fetch fresh data after first frame so ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchFreshTrip());

    // Real-time: if LP/RR-ops reassigns this trip's driver from elsewhere
    // while this screen is open, re-fetch — _tripFreshness's ValueKey scheme
    // then fully remounts the stage forms with the new driver's data.
    _driverReassignSub = ref.read(notificationWsServiceProvider).stream.listen((n) {
      if (n.type == 'driver_reassigned' && n.tripId == widget.trip.id) {
        _fetchFreshTrip();
      }
    });
  }

  @override
  void dispose() {
    _driverReassignSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchFreshTrip() async {
    if (!mounted) return;
    setState(() => _fetchingFresh = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/api/trips/${widget.trip.id}');
      if (!mounted) return;
      final fresh = TripModel.fromJson(resp.data as Map<String, dynamic>);
      setState(() {
        _trip = fresh;
        _tripFreshness++;
        _fetchingFresh = false;
        _providerKey = (fresh.id, fresh.currentStage);
        if (fresh.currentStage >= 5 && !_stage5Done) {
          _showStage4 = true;
          _stage4Done = true;
          _stage5Done = true;
        } else if (fresh.currentStage >= 4 && fresh.s4DieselReceiptUrl != null && !_stage4Done) {
          _showStage4 = true;
          _stage4Done = true;
        } else if (fresh.currentStage >= 4 && !_showStage4) {
          _showStage4 = true;
        }
      });
      // Keep the main trips list in sync
      ref.read(tripProvider.notifier).patchTrip(fresh);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _fetchingFresh = false);
      final msg = _dioErrorDetail(e, 'Failed to load trip details. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _fetchingFresh = false);
    }
  }

  void _exitEditMode() {
    final stage = _editingStage;
    setState(() => _editingStage = null);
    // Always try to release the claim on exit.
    // If stage was already submitted, the backend cleared the claim — release is a no-op.
    if (stage != null) _releaseStage(stage);
    _fetchFreshTrip();
  }

  /// Opens a stage form. LP workers are locked to the current stage only.
  Future<void> _enterStage(int visualStage) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (visualStage == 0 && _isFieldExecutive && !_trip.s1Required) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filling S1 is not necessary for this trip.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _editingStage = visualStage);
  }

  /// No-op: claim blocking is disabled — nothing to release.
  Future<void> _releaseStage(int visualStage) async {}

  /// Trigger a full RR sync for this trip (all available stages).
  /// Shows an RR login dialog first if no valid session exists.
  Future<void> _triggerRrSync() async {
    if (_syncing) return;

    // Step 1: ensure RR session (prompts login if needed)
    final session = await ensureRrSession(context, ref);
    if (session == null || !mounted) return;

    // Step 2: retry any stalled per-stage sync (loading slip synced separately
    // via post_loading_slip; S1/S3/S4/S5 — including the loading/unloading
    // datetime fields — retried here). /sync/trip's sync_all_to_rr is dead for
    // stages 2-5, so this AppBar button must hit /sync/retry, not /sync/trip.
    setState(() => _syncing = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/rr/sync/retry/${_trip.id}', data: {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync started — check back shortly',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${e.toString().split(':').last.trim()}',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// Only LP owners and RR-ops workers hold RR credentials — FE/LP-worker
  /// should never see RR-sync controls (the AppBar sync icon, etc.), only the
  /// stage forms themselves.
  bool get _canManageRr {
    final user = ref.read(authProvider).user;
    return user?.roleKey == 'logistic_partner' || user?.isLpRrOperations == true;
  }

  bool get _isFieldExecutive {
    final user = ref.read(authProvider).user;
    return user?.isLogisticPartnerWorker == true;
  }

  /// True when this FE should never see Stage 1 for this trip — LP/RR-ops
  /// decided the selected driver/vehicle's docs already exist on RR web, so
  /// FE lands straight on Stage 2 instead. LP/RR-ops are never affected.
  bool get _skipS1ForFe => _isFieldExecutive && !_trip.s1Required;

  /// Returns a tap handler for the step indicator. LP, RR-ops, and FE can all
  /// freely move between any stage while the trip is in progress — clicking
  /// any dot (e.g. "Compliance") jumps straight there. In `readOnly` mode
  /// (Records, LP/RR-ops only — FE can't even open it, see
  /// RrTripCard._openStages) navigation between stages stays enabled so
  /// history can be reviewed stage by stage; the AbsorbPointer around the
  /// form itself is what keeps everything non-editable.
  Function(int)? _buildStepTapHandler() {
    return (int i) => _enterStage(i);
  }

  /// Which step-indicator dot (0-4) is "where the user is right now" —
  /// mirrors, condition-for-condition, the exact logic in build() that picks
  /// which form is on screen, so the indicator can never show a different
  /// stage than what's actually rendered.
  int _activeDotIndex(int stage) {
    if (_editingStage != null) return _editingStage!;
    if (_stage5Done) return 4;      // _Stage4CompleteView — Unloading, all done
    if (_stage4Done) return 4;      // _Stage5Form — Unloading
    if (_showStage4) return 3;      // _Stage4Form — Exit
    if (stage == 3) return 2;       // _CompletionView — reviewing Stage 3 (Arrival)
    if (stage == 0 && _skipS1ForFe) return 1;  // _Stage2Form substituted for FE — Compliance
    if (stage == 0) return 0;       // _Stage1Form — Details
    if (stage == 1) return 1;       // _Stage2Form — Compliance
    return 2;                       // stage == 2 → _Stage3Form — Arrival
  }

  Widget _buildEditForm(int visualStage) {
    switch (visualStage) {
      case 0:
        return _Stage1Form(
          key: ValueKey('edit_s1_${_trip.id}_$_tripFreshness'),
          providerKey: _providerKey,
          trip: _trip,
          onEditDone: _exitEditMode,
          readOnly: widget.readOnly,
        );
      case 1:
        return _Stage2Form(
          key: ValueKey('edit_s2_${_trip.id}_$_tripFreshness'),
          providerKey: _providerKey,
          trip: _trip,
          onEditDone: _exitEditMode,
          readOnly: widget.readOnly,
        );
      case 2:
        return _Stage3Form(
          key: ValueKey('edit_s3_${_trip.id}_$_tripFreshness'),
          providerKey: _providerKey,
          trip: _trip,
          onEditDone: _exitEditMode,
          readOnly: widget.readOnly,
        );
      case 3:
        return _Stage4Form(
          key: ValueKey('edit_s4_${_trip.id}_$_tripFreshness'),
          trip: _trip,
          readOnly: widget.readOnly,
          onComplete: (updated) {
            setState(() {
              _trip = updated;
              _stage4Done = true;
              ref.read(tripProvider.notifier).patchTrip(updated);
            });
            _exitEditMode();
          },
        );
      case 4:
      default:
        return _Stage5Form(
          key: ValueKey('edit_s5_${_trip.id}_$_tripFreshness'),
          trip: _trip,
          readOnly: widget.readOnly,
          onComplete: (updated) {
            setState(() {
              _trip = updated;
              _stage5Done = true;
              ref.read(tripProvider.notifier).patchTrip(updated);
            });
            _exitEditMode();
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripStagesProvider(_providerKey));
    final stage = state.currentStage;
    final theme = _StageTheme.rrWeb;

    // Stage 1/2/3 submit through tripStagesProvider, which patches the
    // *global* tripProvider list but never touches this screen's local _trip
    // copy — so the step indicator (which reads _trip.currentStage) used to
    // stay stuck on the old stage until you left the screen and reopened it.
    // Stage 4/5 happened to work because their forms call onComplete directly.
    //
    // ONLY react to currentStage actually advancing — that's the one signal
    // that means a stage genuinely completed. Do NOT trigger on rrSyncStatus/
    // updatedAt: those tick constantly from unrelated background noise (the
    // dashboard's periodic refresh keeps running underneath this pushed route
    // and touches the same global list), and bumping _tripFreshness recreates
    // the active stage form from scratch — wiping whatever the user has typed
    // but not yet submitted. Also skip entirely while mid-edit on a past stage
    // (_editingStage != null) so reviewing/fixing an earlier stage is never
    // interrupted by a stage-progress signal meant for the main flow.
    ref.listen(tripProvider, (previous, next) {
      if (_editingStage != null) return;
      final updated = next.trips.where((t) => t.id == _trip.id).firstOrNull;
      if (updated == null) return;
      if (updated.currentStage <= _trip.currentStage) {
        // currentStage can never advance past 5, so this is the only path
        // left for a background auto-sync (fired server-side off submit_stage5)
        // to ever reach this screen while _Stage4CompleteView is showing. Scoped
        // tightly to that exact view (_stage5Done) so it can't clobber an
        // in-progress form the way the noise-guard above this exists to prevent.
        if (_stage5Done &&
            _trip.currentStage >= 5 &&
            updated.rrSyncStatus == 'pod_synced' &&
            _trip.rrSyncStatus != 'pod_synced') {
          setState(() {
            _trip = updated;
            _tripFreshness++;
          });
        }
        return;
      }
      setState(() {
        _trip = updated;
        _tripFreshness++;
        if (updated.currentStage >= 5) {
          _showStage4 = true; _stage4Done = true; _stage5Done = true;
        } else if (updated.currentStage >= 4 && updated.s4DieselReceiptUrl != null) {
          _showStage4 = true; _stage4Done = true;
        } else if (updated.currentStage >= 4) {
          _showStage4 = true;
        }
      });
    });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.trip.tripNumber,
                style: _manrope(size: 15, weight: FontWeight.w800)),
            Text('${widget.trip.origin} → ${widget.trip.destination}',
                style: _inter(size: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          _TripStateBadge(trip: _trip),
          const SizedBox(width: 4),
          if (_trip.currentStage >= 2 && !widget.readOnly && _canManageRr)
            _syncing
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.primary),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.sync_rounded, color: theme.primary, size: 22),
                    tooltip: 'Sync to RR',
                    onPressed: _triggerRrSync,
                  ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Thin sync indicator while fetching fresh data
          if (_fetchingFresh)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: theme.primary,
            ),
          _StepIndicator(
            activeIndex: _activeDotIndex(stage),
            onStepTap: _buildStepTapHandler(),
            activeColor: theme.primary,
          ),
          if (state.error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: _error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.error!, style: _inter(size: 12, color: _error))),
                ],
              ),
            ),
          if (widget.readOnly)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _secondary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, color: _secondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Read-only — Completed Trip',
                        style: _manrope(size: 12.5, weight: FontWeight.w700, color: _secondary)),
                  ),
                ],
              ),
            ),
          if (!widget.readOnly && _skipS1ForFe && stage == 0 && _editingStage == null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: theme.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Filling S1 is not necessary for this trip.',
                        style: _manrope(size: 12.5, weight: FontWeight.w700, color: theme.primary)),
                  ),
                ],
              ),
            ),
          _Stage0Card(
            key: ValueKey('s0_${_trip.id}_${_trip.rrTripId}_${_trip.rrSyncStatus}'),
            trip: _trip,
            onSyncDone: _fetchFreshTrip,
            readOnly: widget.readOnly,
          ),
          if (_trip.rrTripId != null)
            _RrPerStageSyncPanel(
              key: ValueKey(
                's_sync_${_trip.id}_${_trip.rrS1SyncStatus}_${_trip.rrSyncStatus}_'
                '${_trip.rrS3SyncStatus}_${_trip.rrS4SyncStatus}_${_trip.rrS5SyncStatus}',
              ),
              trip: _trip,
              onRetryDone: _fetchFreshTrip,
              readOnly: widget.readOnly,
            ),
          Expanded(
            child: _editingStage != null
                ? _buildEditForm(_editingStage!)
                : _stage5Done
                    ? _Stage4CompleteView(
                        trip: _trip,
                        onDone: () => Navigator.of(context).pop(),
                        readOnly: widget.readOnly,
                      )
                    : _stage4Done
                        ? _Stage5Form(
                            key: ValueKey('s5_${_trip.id}_$_tripFreshness'),
                            trip: _trip,
                            readOnly: widget.readOnly,
                            onComplete: (updated) {
                              setState(() {
                                _trip = updated;
                                _stage5Done = true;
                                ref.read(tripProvider.notifier).patchTrip(updated);
                              });
                            },
                          )
                        : _showStage4
                            ? _Stage4Form(
                                key: ValueKey('s4_${_trip.id}_$_tripFreshness'),
                                trip: _trip,
                                readOnly: widget.readOnly,
                                onComplete: (updated) {
                                  setState(() {
                                    _trip = updated;
                                    _stage4Done = true;
                                    ref.read(tripProvider.notifier).patchTrip(updated);
                                  });
                                },
                              )
                            : stage == 3
                                ? _CompletionView(
                                    trip: _trip,
                                    emptyWeightKg: state.emptyWeightKg,
                                    emptyWeightUnit: state.emptyWeightUnit ?? 'kg',
                                    loadedWeightKg: state.loadedWeightKg,
                                    loadedWeightUnit: state.loadedWeightUnit ?? 'kg',
                                    onDone: () => Navigator.of(context).pop(),
                                    onNextStage: () => setState(() => _showStage4 = true),
                                  )
                                : stage == 0 && _skipS1ForFe
                                    ? _Stage2Form(
                                        key: ValueKey('s2_skip1_${_trip.id}_$_tripFreshness'),
                                        providerKey: _providerKey,
                                        trip: _trip,
                                        readOnly: widget.readOnly,
                                      )
                                : stage == 0
                                    ? (_trip.rrTripId == null
                                        ? _Stage0LandingView(trip: _trip)
                                        : _Stage1Form(
                                            key: ValueKey('s1_${_trip.id}_$_tripFreshness'),
                                            providerKey: _providerKey,
                                            trip: _trip,
                                            onEditDone: null,
                                            readOnly: widget.readOnly,
                                          ))
                                    : stage == 1
                                        ? _Stage2Form(
                                            key: ValueKey('s2_${_trip.id}_$_tripFreshness'),
                                            providerKey: _providerKey,
                                            trip: _trip,
                                            readOnly: widget.readOnly,
                                          )
                                        : _Stage3Form(
                                                key: ValueKey('s3_${_trip.id}_$_tripFreshness'),
                                                providerKey: _providerKey,
                                                trip: _trip,
                                                readOnly: widget.readOnly,
                                              ),
          ),
        ],
      ),
    );
  }
}

// ─── Trip state badge (5-state: Pending / Ongoing / In Transit / Completed / Cancelled) ──

(String, Color, Color) _tripStateColors(TripModel trip) {
  // A trip is "complete" either via the explicit /complete action (trip.status)
  // or by reaching Records (all 5 stages done + fully synced to RR) — the
  // latter never touches trip.status, so both must be checked here or the
  // badge stays stuck on "IN TRANSIT" for trips sitting in Records.
  final isRecordsComplete = trip.currentStage >= 5 && trip.rrSyncStatus == 'pod_synced';
  if (trip.isCancelled) return ('CANCELLED', const Color(0xFFFFDAD6), const Color(0xFFBA1A1A));
  if (trip.isCompleted || isRecordsComplete) return ('COMPLETED', const Color(0xFFECEEF0), const Color(0xFF546067));
  if (trip.currentStage >= 4) return ('IN TRANSIT', const Color(0xFFD7F0D9), const Color(0xFF1B5E20));
  if (trip.currentStage >= 1) return ('ONGOING', const Color(0xFFFFE8D5), const Color(0xFFFF6B00));
  return ('PENDING', const Color(0xFFFFF3E0), const Color(0xFFE65100));
}

class _TripStateBadge extends StatelessWidget {
  final TripModel trip;
  const _TripStateBadge({required this.trip});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _tripStateColors(trip);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w700, color: fg,
              letterSpacing: 0.6)),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  /// Which dot (0-4) is "where the user is right now" — computed directly by
  /// the parent from the exact same state that decides which form is on
  /// screen, so the two can never disagree. Not derived from trip.currentStage
  /// here — that was the old approach and it went stale after a same-session
  /// stage submit until the screen was reopened.
  final int activeIndex;
  final Function(int)? onStepTap;
  /// Active-step color — the RR theme's blue.
  final Color activeColor;
  const _StepIndicator({
    required this.activeIndex,
    this.onStepTap,
    this.activeColor = _primary,
  });

  static const _labels = ['Details', 'Compliance', 'Arrival', 'Exit', 'Unloading'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: List.generate(5, (i) {
          final isActive = activeIndex == i;
          final color   = isActive ? activeColor : _secondary;
          final bgColor = isActive ? activeColor.withValues(alpha: 0.12) : _border;

          final dot = AnimatedScale(
            // The active dot visibly grows the moment you land on it — the
            // one signal this indicator exists to give: "you are here".
            scale: isActive ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? activeColor : bgColor,
                border: Border.all(color: isActive ? activeColor : _border, width: isActive ? 0 : 1),
                boxShadow: isActive
                    ? [BoxShadow(color: activeColor.withValues(alpha: 0.35), blurRadius: 8, spreadRadius: 1)]
                    : [],
              ),
              child: Center(
                child: Text('${i + 1}',
                    style: _manrope(
                        size: 12,
                        weight: FontWeight.w800,
                        color: isActive ? Colors.white : color)),
              ),
            ),
          );

          // Fixed width regardless of label length — "Compliance"/"Unloading"
          // are longer words than "Arrival"/"Exit"/"Details", so without this
          // each dot's surrounding gap was as wide as its own label text,
          // making some stages look tightly packed and others wide open.
          final dotWidget = SizedBox(
            width: 58,
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onStepTap != null ? () => onStepTap!(i) : null,
                  child: dot,
                ),
                const SizedBox(height: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: _inter(
                      size: 8.5,
                      weight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: color),
                  child: Text(_labels[i], textAlign: TextAlign.center),
                ),
              ],
            ),
          );

          if (i == 4) return dotWidget;

          return Expanded(
            child: Row(
              children: [
                dotWidget,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Container(
                      height: 2,
                      color: _border,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Stage 1: Truck Detail Registration ───────────────────────────────────────

class _Stage1Form extends ConsumerStatefulWidget {
  final (String, int) providerKey;
  final TripModel trip;
  /// Called after a successful update-submit when the user was editing stage 1 from stage 2.
  final VoidCallback? onEditDone;
  final bool readOnly;
  const _Stage1Form({super.key, required this.providerKey, required this.trip, this.onEditDone, this.readOnly = false});

  @override
  ConsumerState<_Stage1Form> createState() => _Stage1FormState();
}

class _Stage1FormState extends ConsumerState<_Stage1Form> {
  final _formKey = GlobalKey<FormState>();
  final _picker  = ImagePicker();

  // ── Per-field attribution tracking ─────────────────────────────────────────
  /// Attributions restored from draft: fieldKey → @username
  final Map<String, String> _fieldAttributions = {};
  /// Fields touched by the current user this session (sent to backend on save)
  final Set<String> _touchedByMe = {};
  void _touchField(String key) => _touchedByMe.add(key);
  String? _attrOf(String key) => _fieldAttributions[key];

  // ── Text fields ─────────────────────────────────────────────────────────────
  final _driverName     = TextEditingController();
  final _driverPhone    = TextEditingController();
  final _drivingLicense = TextEditingController();
  final _aadhaar        = TextEditingController();
  final _rcNumber       = TextEditingController();
  final _pucNumber      = TextEditingController();
  final _fitnessNumber  = TextEditingController();
  final _permitNumber   = TextEditingController();
  final _insuranceNumber = TextEditingController();

  // ── Focus nodes (for auto-scroll on validation error) ─────────────────────
  final _driverNameFocus     = FocusNode();
  final _driverPhoneFocus    = FocusNode();
  final _drivingLicenseFocus = FocusNode();
  final _aadhaarFocus        = FocusNode();

  // ── File uploads (bytes + filename, for newly picked files) ─────────────────
  ({Uint8List bytes, String name})? _dlDoc;
  ({Uint8List bytes, String name})? _dlBackDoc;
  ({Uint8List bytes, String name})? _aadhaarDoc;
  ({Uint8List bytes, String name})? _aadhaarBackDoc;
  ({Uint8List bytes, String name})? _rcDoc;
  ({Uint8List bytes, String name})? _rcBackDoc;
  ({Uint8List bytes, String name})? _insuranceDoc;
  ({Uint8List bytes, String name})? _pollutionDoc;
  ({Uint8List bytes, String name})? _fitnessDoc;
  ({Uint8List bytes, String name})? _permitDoc;
  ({Uint8List bytes, String name})? _panDoc;
  ({Uint8List bytes, String name})? _taxDeclDoc;
  ({Uint8List bytes, String name})? _cancelledChequeDoc;

  Timer? _debounce;
  DateTime? _lastSaved;

  // ── RR pre-fill (driver/vehicle already hired on a prior trip) ─────────────
  // Photo bytes fetched via the file-preview proxy, keyed by doc slot:
  // dl_front/dl_back/aadhaar_front/aadhaar_back/rc_front/puc/fitness/permit.
  final Map<String, Uint8List> _rrPreview = {};

  // ── Appoint New Driver (LP/RR-ops only) ─────────────────────────────────────
  bool _showDriverReassign = false;
  final _newDriverSearchCtrl = TextEditingController();
  Map<String, dynamic>? _pendingNewDriver; // {_id, name, phone} from search
  bool _reassigning = false;

  bool get _canManageRr {
    final user = ref.read(authProvider).user;
    return user?.roleKey == 'logistic_partner' || user?.isLpRrOperations == true;
  }

  @override
  void initState() {
    super.initState();
    _prefillFromDraft();
    // Individual listeners so we know WHICH field the current user touched
    _driverName.addListener(()     { _touchField('driver_name');     _onFieldChanged(); });
    _driverPhone.addListener(()    { _touchField('driver_phone');    _onFieldChanged(); });
    _drivingLicense.addListener(() { _touchField('driving_license'); _onFieldChanged(); });
    _aadhaar.addListener(()        { _touchField('aadhaar');         _onFieldChanged(); });
    _rcNumber.addListener(()       { _touchField('rc_number');       _onFieldChanged(); });
    _pucNumber.addListener(()      { _touchField('puc_number');      _onFieldChanged(); });
    _fitnessNumber.addListener(()  { _touchField('fitness_number');  _onFieldChanged(); });
    _permitNumber.addListener(()   { _touchField('permit_number');   _onFieldChanged(); });
    _insuranceNumber.addListener(() { _touchField('insurance_number'); _onFieldChanged(); });
    _maybeLoadRrPrefill();
  }

  // A driver/vehicle already hired before may already have docs on RR — pull
  // them in so this doesn't need re-entry, same as RR web itself does. Only
  // for a genuinely fresh Stage 1 (no draft, not yet submitted); a convenience
  // enhancement, never blocking — any failure (no RR session yet, network
  // issue, etc.) is silently skipped.
  Future<void> _maybeLoadRrPrefill() async {
    final trip = widget.trip;
    if (trip.draftData != null || trip.currentStage >= 1) return;
    final driverRrId = trip.rrDriverId;
    final vehicleRrId = trip.rrVehicleId;
    if ((driverRrId == null || driverRrId.isEmpty) &&
        (vehicleRrId == null || vehicleRrId.isEmpty)) {
      return;
    }

    try {
      final data = await ref.read(rrSyncApiProvider).getPrefill(
        driverRrId: driverRrId,
        vehicleRrId: vehicleRrId,
      );

      await _applyDriverPrefill(data['driver'] as Map<String, dynamic>?, overwrite: false);

      final vehicle = data['vehicle'] as Map<String, dynamic>?;
      if (vehicle != null) {
        final rc = vehicle['rc'] as Map<String, dynamic>?;
        if (rc != null) {
          final num_ = rc['number'] as String?;
          if (_rcNumber.text.isEmpty && num_ != null && num_.isNotEmpty) _rcNumber.text = num_;
          await _fetchRrPreview(rc['front_file_id'] as String?, 'rc_front');
          await _fetchRrPreview(rc['back_file_id'] as String?, 'rc_back');
        }
        final puc = vehicle['puc'] as Map<String, dynamic>?;
        if (puc != null) {
          final num_ = puc['number'] as String?;
          if (_pucNumber.text.isEmpty && num_ != null && num_.isNotEmpty) _pucNumber.text = num_;
          await _fetchRrPreview(puc['front_file_id'] as String?, 'puc');
        }
        final fitness = vehicle['fitness'] as Map<String, dynamic>?;
        if (fitness != null) {
          final num_ = fitness['number'] as String?;
          if (_fitnessNumber.text.isEmpty && num_ != null && num_.isNotEmpty) _fitnessNumber.text = num_;
          await _fetchRrPreview(fitness['front_file_id'] as String?, 'fitness');
        }
        final permit = vehicle['permit'] as Map<String, dynamic>?;
        if (permit != null) {
          final num_ = permit['number'] as String?;
          if (_permitNumber.text.isEmpty && num_ != null && num_.isNotEmpty) _permitNumber.text = num_;
          await _fetchRrPreview(permit['front_file_id'] as String?, 'permit');
        }
        final insurance = vehicle['insurance'] as Map<String, dynamic>?;
        if (insurance != null) {
          final num_ = insurance['policy_number'] as String?;
          if (_insuranceNumber.text.isEmpty && num_ != null && num_.isNotEmpty) _insuranceNumber.text = num_;
          await _fetchRrPreview(insurance['front_file_id'] as String?, 'insurance');
        }
      }
    } catch (_) {
      // No RR session yet, network issue, etc. — pre-fill is a convenience,
      // never required to fill out Stage 1.
    }
  }

  /// Shared by the initial auto pre-fill (fills only empty fields, never
  /// clobbers) and the explicit "Appoint New Driver" reassignment flow
  /// (overwrites, since the user just deliberately picked a different
  /// driver). [overwrite] controls which behavior applies.
  Future<void> _applyDriverPrefill(Map<String, dynamic>? driver, {required bool overwrite}) async {
    if (driver == null) return;
    final name = driver['name'] as String?;
    if ((overwrite || _driverName.text.isEmpty) && name != null && name.isNotEmpty) {
      _driverName.text = name;
    }
    final phone = driver['phone'] as String?;
    if ((overwrite || _driverPhone.text.isEmpty) && phone != null && phone.isNotEmpty) {
      _driverPhone.text = phone.length >= 10 ? phone.substring(phone.length - 10) : phone;
    }
    final dl = driver['dl'] as Map<String, dynamic>?;
    if (overwrite) {
      _dlDoc = null;
      _dlBackDoc = null;
      _rrPreview.remove('dl_front');
      _rrPreview.remove('dl_back');
      _drivingLicense.text = '';
    }
    if (dl != null) {
      final num_ = dl['number'] as String?;
      if ((overwrite || _drivingLicense.text.isEmpty) && num_ != null && num_.isNotEmpty) {
        _drivingLicense.text = num_;
      }
      await _fetchRrPreview(dl['front_file_id'] as String?, 'dl_front');
      await _fetchRrPreview(dl['back_file_id'] as String?, 'dl_back');
    }
    final aadhaar = driver['aadhaar'] as Map<String, dynamic>?;
    if (overwrite) {
      _aadhaarDoc = null;
      _aadhaarBackDoc = null;
      _rrPreview.remove('aadhaar_front');
      _rrPreview.remove('aadhaar_back');
      _aadhaar.text = '';
    }
    if (aadhaar != null) {
      final num_ = aadhaar['number'] as String?;
      if ((overwrite || _aadhaar.text.isEmpty) && num_ != null && num_.isNotEmpty) {
        _aadhaar.text = num_;
      }
      await _fetchRrPreview(aadhaar['front_file_id'] as String?, 'aadhaar_front');
      await _fetchRrPreview(aadhaar['back_file_id'] as String?, 'aadhaar_back');
    }
    if (mounted) setState(() {});
  }

  // A driver was picked via the search field above — pull their existing
  // docs (if any) so LP/RR-ops doesn't need to re-enter anything, overwriting
  // whatever the previous driver's fields showed (this is a deliberate
  // reassignment, not the initial fresh-load pre-fill).
  Future<void> _onNewDriverSelected(Map<String, dynamic> u) async {
    setState(() => _pendingNewDriver = u);
    final driverRrId = u['user_id'] as String?;
    if (driverRrId == null || driverRrId.isEmpty) return;
    try {
      final data = await ref.read(rrSyncApiProvider).getPrefill(driverRrId: driverRrId);
      await _applyDriverPrefill(data['driver'] as Map<String, dynamic>?, overwrite: true);
    } catch (_) {
      // Pre-fill failure here isn't fatal — LP/RR-ops can still fill the
      // new driver's details manually before reassigning.
    }
  }

  Future<void> _confirmReassignDriver() async {
    final newDriver = _pendingNewDriver;
    if (newDriver == null || _reassigning) return;
    final driverRrId = newDriver['user_id'] as String?;
    if (driverRrId == null || driverRrId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reassign Driver?', style: _inter(size: 16, weight: FontWeight.w700, color: _onSurface)),
        content: Text(
          'This trip will be reassigned to ${newDriver['name'] ?? 'the selected driver'} on RR — '
          'the My Trips list and crew records will update to reflect this.',
          style: _inter(size: 13, color: _secondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reassign')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final session = await ensureRrSession(context, ref);
    if (session == null || !mounted) return;

    setState(() => _reassigning = true);
    try {
      await ref.read(rrSyncApiProvider).reassignDriver(
        tripId: widget.trip.id,
        rrToken: session.token,
        driverRrId: driverRrId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Driver reassigned', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _success,
        behavior: SnackBarBehavior.floating,
      ));
      setState(() {
        _showDriverReassign = false;
        _pendingNewDriver = null;
        _newDriverSearchCtrl.clear();
      });
      ref.read(tripProvider.notifier).fetchSingleTrip(widget.trip.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not reassign driver', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _reassigning = false);
    }
  }

  Future<void> _fetchRrPreview(String? rrFileId, String key) async {
    if (rrFileId == null || rrFileId.isEmpty) return;
    try {
      final resp = await ref.read(dioProvider).get(
        '/api/rr/file-preview/$rrFileId',
        options: Options(responseType: ResponseType.bytes),
      );
      if (!mounted) return;
      setState(() => _rrPreview[key] = Uint8List.fromList(resp.data as List<int>));
    } catch (_) {
      // Skip this one photo silently — not fatal to the rest of pre-fill.
    }
  }

  // ── Draft restore ────────────────────────────────────────────────────────────

  void _prefillFromDraft() {
    final trip = widget.trip;

    // Always load persistent field attributions first (survive stage submission)
    trip.fieldAttributions?.forEach((k, v) {
      if (v is String) _fieldAttributions[k] = v;
    });

    final draft = trip.draftData;

    // Prefer draft data over committed trip fields (draft = in-progress edits)
    if (draft != null && draft['stage'] == 1) {
      final d = draft['data'] as Map<String, dynamic>? ?? {};
      _driverName.text     = d['driver_name']    as String? ?? '';
      final rawPhone       = d['driver_phone']   as String? ?? '';
      _driverPhone.text    = rawPhone.startsWith('+91') ? rawPhone.substring(3) : rawPhone;
      _drivingLicense.text = d['driving_license'] as String? ?? '';
      _aadhaar.text        = d['aadhaar']         as String? ?? '';
      _rcNumber.text       = d['rc_number']       as String? ?? '';
      _pucNumber.text      = d['puc_number']      as String? ?? '';
      _fitnessNumber.text  = d['fitness_number']  as String? ?? '';
      _permitNumber.text   = d['permit_number']   as String? ?? '';
      _insuranceNumber.text = d['insurance_number'] as String? ?? '';
      _dlDoc              = _restoreFile(d, 'dl_doc');
      _dlBackDoc          = _restoreFile(d, 'dl_back_doc');
      _aadhaarDoc         = _restoreFile(d, 'aadhaar_doc');
      _aadhaarBackDoc     = _restoreFile(d, 'aadhaar_back_doc');
      _rcDoc              = _restoreFile(d, 'rc_doc');
      _rcBackDoc          = _restoreFile(d, 'rc_back_doc');
      _insuranceDoc       = _restoreFile(d, 'insurance_doc');
      _pollutionDoc       = _restoreFile(d, 'pollution_doc');
      _fitnessDoc         = _restoreFile(d, 'fitness_doc');
      _permitDoc          = _restoreFile(d, 'permit_doc');
      _panDoc             = _restoreFile(d, 'pan_doc');
      _taxDeclDoc         = _restoreFile(d, 'tax_decl_doc');
      _cancelledChequeDoc = _restoreFile(d, 'cancelled_cheque_doc');
      if (draft['saved_at'] != null) {
        _lastSaved = DateTime.tryParse(draft['saved_at'] as String);
      }
      // Draft attributions override persistent ones
      final attrs = draft['attributions'] as Map<String, dynamic>?;
      if (attrs != null) {
        attrs.forEach((k, v) { if (v is String) _fieldAttributions[k] = v; });
      }
      return;
    }

    // Fall back to committed trip fields (stage 1 already submitted)
    if (trip.currentStage >= 1) {
      _driverName.text = trip.s1DriverName ?? '';
      final rawPhone   = trip.s1DriverPhone ?? '';
      _driverPhone.text = rawPhone.startsWith('+91') ? rawPhone.substring(3) : rawPhone;
      _drivingLicense.text = trip.s1DrivingLicense ?? '';
      _aadhaar.text        = trip.s1Aadhaar ?? '';
      _rcNumber.text       = trip.s1RcNumber ?? '';
      _pucNumber.text      = trip.s1PucNumber ?? '';
      _fitnessNumber.text  = trip.s1FitnessNumber ?? '';
      _permitNumber.text   = trip.s1PermitNumber ?? '';
      _insuranceNumber.text = trip.s1InsuranceNumber ?? '';
      // File URLs are shown via _serverUrl fields — no bytes to restore
    }
  }

  ({Uint8List bytes, String name})? _restoreFile(Map<String, dynamic> d, String key) {
    final b64  = d['${key}_b64']  as String?;
    final name = d['${key}_name'] as String?;
    if (b64 == null || name == null) return null;
    try { return (bytes: base64Decode(b64), name: name); } catch (_) { return null; }
  }

  // ── Draft save ───────────────────────────────────────────────────────────────

  void _onFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  void _onUploadChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _saveDraft);
  }

  Map<String, dynamic> _fileDraftEntry(({Uint8List bytes, String name})? f, String key) {
    if (f == null) return {};
    return {'${key}_b64': base64Encode(f.bytes), '${key}_name': f.name};
  }

  Future<void> _saveDraft({bool duringDispose = false}) async {
    if (!duringDispose && !mounted) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/draft', data: {
        'stage': 1,
        'data': {
          'driver_name':     _driverName.text.trim(),
          'driver_phone':    '+91${_driverPhone.text.trim()}',
          'driving_license': _drivingLicense.text.trim(),
          'aadhaar':         _aadhaar.text.trim(),
          'rc_number':       _rcNumber.text.trim(),
          'puc_number':      _pucNumber.text.trim(),
          'fitness_number':  _fitnessNumber.text.trim(),
          'permit_number':   _permitNumber.text.trim(),
          'insurance_number': _insuranceNumber.text.trim(),
          ..._fileDraftEntry(_dlDoc,              'dl_doc'),
          ..._fileDraftEntry(_dlBackDoc,          'dl_back_doc'),
          ..._fileDraftEntry(_aadhaarDoc,         'aadhaar_doc'),
          ..._fileDraftEntry(_aadhaarBackDoc,     'aadhaar_back_doc'),
          ..._fileDraftEntry(_rcDoc,              'rc_doc'),
          ..._fileDraftEntry(_rcBackDoc,          'rc_back_doc'),
          ..._fileDraftEntry(_insuranceDoc,       'insurance_doc'),
          ..._fileDraftEntry(_pollutionDoc,       'pollution_doc'),
          ..._fileDraftEntry(_fitnessDoc,         'fitness_doc'),
          ..._fileDraftEntry(_permitDoc,          'permit_doc'),
          ..._fileDraftEntry(_panDoc,             'pan_doc'),
          ..._fileDraftEntry(_taxDeclDoc,         'tax_decl_doc'),
          ..._fileDraftEntry(_cancelledChequeDoc, 'cancelled_cheque_doc'),
        },
        // Per-field attribution: backend resolves these to current_user.username
        if (_touchedByMe.isNotEmpty)
          'attributions': {for (final k in _touchedByMe) k: true},
      });
      if (!duringDispose && mounted) setState(() => _lastSaved = DateTime.now());
    } on DioException catch (e) {
      // Surface draft save failures so they are visible during testing
      if (!duringDispose && mounted) _showDraftSaveError(context, e);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      unawaited(_saveDraft(duringDispose: true));
    } else {
      _debounce?.cancel();
    }
    for (final c in [
      _driverName, _driverPhone, _drivingLicense, _aadhaar,
      _rcNumber, _pucNumber, _fitnessNumber, _permitNumber, _insuranceNumber,
      _newDriverSearchCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [_driverNameFocus, _driverPhoneFocus, _drivingLicenseFocus, _aadhaarFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Validators ───────────────────────────────────────────────────────────────

  String? _validateDriverName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Driver Name is required';
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v.trim())) return 'Only alphabets allowed';
    if (v.trim().length > 25) return 'Maximum 25 characters';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) return 'Enter exactly 10 digits';
    return null;
  }

  String? _validateAadhaar(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final cleaned = v.trim().replaceAll(' ', '');
    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) return 'Aadhaar must be exactly 12 digits';
    return null;
  }

  // Matches RR's own server-side format exactly (rrbc-api/app/rr_utils/
  // common_functions.py's is_driving_licence_valid): state code (2 letters)
  // + RTO code (2 digits) + optional single series letter + year (19xx/20xx)
  // + 7 digits — 15 chars without the series letter, 16 with it, after
  // stripping separators (which _submit() always does before sending).
  // Loose format checks (10-18 any alphanumeric) let clearly-invalid values
  // through locally that RR's own sync then rejects outright — this closes
  // that gap so the error surfaces immediately, not after a failed sync.
  String? _validateDrivingLicense(String? v) {
    if (v == null || v.trim().isEmpty) return 'Driving License is required';
    final cleaned = v.trim().replaceAll(RegExp(r'[\s/\-]'), '').toUpperCase();
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]?(19|20)[0-9]{2}[0-9]{7}$').hasMatch(cleaned)) {
      return 'Invalid format — e.g. RJ1420230012345 (state+RTO+year+7 digits)';
    }
    return null;
  }

  // Matches RR's own rule exactly (validator.py's _validate_check_format for
  // Registration Certificate): rejects a purely-alphabetic or purely-numeric
  // value, since a real RC number is always a mix of both. RR also enforces
  // a cross-vehicle uniqueness check server-side that can't be replicated
  // client-side without a live lookup — this only covers the format half.
  String? _validateRcNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final cleaned = v.trim();
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(cleaned);
    final hasDigit = RegExp(r'[0-9]').hasMatch(cleaned);
    if (!hasLetter || !hasDigit) {
      return 'Invalid RC number — must contain both letters and digits';
    }
    return null;
  }

  // PUC/Fitness/Permit/Insurance have no fixed nationwide numbering standard
  // (unlike DL/Aadhaar/RC) and RR itself applies no format validation to
  // these — confirmed by reading RR's validator source. A light sanity
  // check only (reasonable length), not a fabricated strict format.
  String? _validateGenericDocNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    if (v.trim().length < 4) return 'Too short to be a valid number';
    return null;
  }

  // ── File picker ──────────────────────────────────────────────────────────────

  Future<void> _pickFile(
    ImageSource source,
    void Function(({Uint8List bytes, String name}) f) onPicked,
  ) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      onPicked((bytes: bytes, name: picked.name));
      setState(() {});
      _onUploadChanged();
    } catch (e) {
      if (!mounted) return;
      _showPickError(context, e, source);
    }
  }

  // ── Auto-scroll to first invalid field ────────────────────────────────────

  void _scrollToFirstError() {
    final checks = [
      (_driverNameFocus,     _validateDriverName(_driverName.text)),
      (_driverPhoneFocus,    _validatePhone(_driverPhone.text)),
      (_drivingLicenseFocus, _validateDrivingLicense(_drivingLicense.text)),
      (_aadhaarFocus,        _validateAadhaar(_aadhaar.text)),
    ];
    for (final (focus, error) in checks) {
      if (error != null) {
        focus.requestFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = focus.context;
          if (ctx != null) {
            Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 300));
          }
        });
        return;
      }
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  // A doc is satisfied by either a freshly-picked file or an already-uploaded
  // server URL from a prior submission. Aadhaar (number + front/back photos)
  // is intentionally NOT required — only Driving License is mandatory to
  // proceed to Stage 2.
  List<String> _missingRequiredDocs() {
    final missing = <String>[];
    void check(String label, ({Uint8List bytes, String name})? doc, String? existingUrl) {
      if (doc == null && (existingUrl == null || existingUrl.isEmpty)) missing.add(label);
    }
    check('Driving License (Front)', _dlDoc, widget.trip.s1DrivingLicenseUrl);
    check('Driving License (Back)', _dlBackDoc, widget.trip.s1DrivingLicenseBackUrl);
    return missing;
  }

  // Pre-filled RR photos (`_rrPreview`) are fetched purely for display —
  // without this step they'd never satisfy the required-docs check or get
  // attached to the submit payload, silently forcing the user to re-upload
  // a document RR already has and defeating the whole point of pre-fill.
  // Promote each preview to a real local pick (only where nothing's already
  // been locally picked or previously saved to our own backend), so it both
  // counts as present and gets saved to our own upload storage too.
  void _promoteRrPreviewsToLocalFiles() {
    ({Uint8List bytes, String name})? promote(
      Uint8List? preview, ({Uint8List bytes, String name})? existing, String? existingUrl, String name,
    ) {
      if (existing != null || (existingUrl != null && existingUrl.isNotEmpty)) return existing;
      if (preview == null) return existing;
      return (bytes: preview, name: name);
    }

    _dlDoc = promote(_rrPreview['dl_front'], _dlDoc, widget.trip.s1DrivingLicenseUrl, 'dl_front_from_rr.jpg');
    _dlBackDoc = promote(_rrPreview['dl_back'], _dlBackDoc, widget.trip.s1DrivingLicenseBackUrl, 'dl_back_from_rr.jpg');
    _aadhaarDoc = promote(_rrPreview['aadhaar_front'], _aadhaarDoc, widget.trip.s1AadhaarUrl, 'aadhaar_front_from_rr.jpg');
    _aadhaarBackDoc = promote(_rrPreview['aadhaar_back'], _aadhaarBackDoc, widget.trip.s1AadhaarBackUrl, 'aadhaar_back_from_rr.jpg');
    _rcDoc = promote(_rrPreview['rc_front'], _rcDoc, widget.trip.s1Rc, 'rc_front_from_rr.jpg');
    _rcBackDoc = promote(_rrPreview['rc_back'], _rcBackDoc, widget.trip.s1RcBack, 'rc_back_from_rr.jpg');
    _pollutionDoc = promote(_rrPreview['puc'], _pollutionDoc, widget.trip.s1Pollution, 'puc_from_rr.jpg');
    _fitnessDoc = promote(_rrPreview['fitness'], _fitnessDoc, widget.trip.s1Fitness, 'fitness_from_rr.jpg');
    _permitDoc = promote(_rrPreview['permit'], _permitDoc, widget.trip.s1Permit, 'permit_from_rr.jpg');
    _insuranceDoc = promote(_rrPreview['insurance'], _insuranceDoc, widget.trip.s1Insurance, 'insurance_from_rr.jpg');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    _promoteRrPreviewsToLocalFiles();

    final missingDocs = _missingRequiredDocs();
    if (missingDocs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload: ${missingDocs.join(", ")}',
            style: _inter(size: 13, color: Colors.white),
          ),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final dlCleaned = _drivingLicense.text.trim()
        .replaceAll(RegExp(r'[\s/\-]'), '').toUpperCase();

    final fields = <String, dynamic>{
      'driver_name':     _driverName.text.trim(),
      'driver_phone':    '+91${_driverPhone.text.trim()}',
      'driving_license': dlCleaned,
      'aadhaar':         _aadhaar.text.trim().replaceAll(' ', ''),
      'rc_number':       _rcNumber.text.trim(),
      'puc_number':      _pucNumber.text.trim(),
      'fitness_number':  _fitnessNumber.text.trim(),
      'permit_number':   _permitNumber.text.trim(),
      'insurance_number': _insuranceNumber.text.trim(),
    };

    void _addFile(String key, ({Uint8List bytes, String name})? f) {
      if (f != null) fields[key] = MultipartFile.fromBytes(f.bytes, filename: f.name);
    }
    _addFile('driving_license_doc',       _dlDoc);
    _addFile('driving_license_doc_back',  _dlBackDoc);
    _addFile('aadhaar_doc',               _aadhaarDoc);
    _addFile('aadhaar_doc_back',          _aadhaarBackDoc);
    _addFile('rc_doc',               _rcDoc);
    _addFile('rc_doc_back',          _rcBackDoc);
    _addFile('insurance_doc',        _insuranceDoc);
    _addFile('pollution_doc',        _pollutionDoc);
    _addFile('fitness_doc',          _fitnessDoc);
    _addFile('permit_doc',           _permitDoc);
    _addFile('pan_doc',              _panDoc);
    _addFile('tax_declaration_doc',  _taxDeclDoc);
    _addFile('cancelled_cheque_doc', _cancelledChequeDoc);

    final isEdit = widget.trip.currentStage >= 1;
    final ok = await ref
        .read(tripStagesProvider(widget.providerKey).notifier)
        .submitStage1(FormData.fromMap(fields));

    if (ok && mounted) {
      final msg = isEdit ? 'Stage 1 updated successfully.' : 'Stage 1 saved. Proceed to compliance check.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      widget.onEditDone?.call();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: _inter(size: 12, color: _secondary),
    filled: true,
    fillColor: _surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 1.5)),
  );

  /// Builds an upload tile with optional per-field attribution display.
  /// [fieldKey] is used for touch tracking and attribution lookup.
  Widget _uploadTile(
    String label,
    String subtitle,
    ({Uint8List bytes, String name})? file,
    void Function(({Uint8List bytes, String name}) f) onPicked,
    VoidCallback onRemove, {
    String? existingUrl,
    String? fieldKey,
    Uint8List? rrPreviewBytes,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _DocUploadTile(
              label: label,
              subtitle: subtitle,
              bytes: file?.bytes,
              fileName: file?.name,
              existingUrl: file == null ? existingUrl : null,
              rrPreviewBytes: (file == null && existingUrl == null) ? rrPreviewBytes : null,
              onPickSource: (src) async {
                if (fieldKey != null) _touchField(fieldKey);
                await _pickFile(src, onPicked);
              },
              onRemove: () {
                if (fieldKey != null) _touchField(fieldKey);
                onRemove();
              },
              readOnly: widget.readOnly,
            ),
          ),
          _FieldAttribution(username: fieldKey != null ? _attrOf(fieldKey) : null),
          const SizedBox(height: 8),
        ],
      );

  /// Optional number field for a vehicle doc (RC/PUC/Fitness/Permit) — sits
  /// alongside its upload, same as DL/Aadhaar number fields do for driver docs.
  Widget _numberField(
    String label,
    TextEditingController controller,
    String fieldKey, {
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: controller,
          style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [LengthLimitingTextInputFormatter(30)],
          validator: validator ?? _validateGenericDocNumber,
          decoration: _dec(label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(tripStagesProvider(widget.providerKey)).isSubmitting;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage 1 attribution — who submitted this stage (LP side only)
            _StageAttribution(
              username: widget.trip.currentStage >= 1
                  ? widget.trip.s1SubmittedByUsername
                  : null,
            ),

            // ── Driver Details ─────────────────────────────────────────────────
            _SectionHeader(icon: Icons.person_outline_rounded, title: 'Driver Details'),

            // Appoint New Driver — LP/RR-ops only, FE never sees this at all.
            if (_canManageRr && (widget.trip.rrDriverId?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Appoint New Driver',
                                style: _inter(size: 13, weight: FontWeight.w700, color: _onSurface)),
                          ),
                          Switch(
                            value: _showDriverReassign,
                            onChanged: (v) => setState(() {
                              _showDriverReassign = v;
                              if (!v) {
                                _pendingNewDriver = null;
                                _newDriverSearchCtrl.clear();
                              }
                            }),
                          ),
                        ],
                      ),
                      if (_showDriverReassign) ...[
                        const SizedBox(height: 8),
                        RrSearchField<Map<String, dynamic>>(
                          label: 'Search Driver by Name or Phone',
                          controller: _newDriverSearchCtrl,
                          search: (q) async {
                            final session = await ensureRrSession(context, ref);
                            if (session == null || !mounted) return [];
                            return ref.read(rrSyncApiProvider)
                                .searchRrUsers(q, session.token, driversOnly: true);
                          },
                          itemLabel: (u) => u['name'] as String? ?? '',
                          itemSubtitle: (u) => u['phone'] as String? ?? '',
                          onSelected: (u) => _onNewDriverSelected(u),
                          onCleared: () => setState(() => _pendingNewDriver = null),
                        ),
                        if (_pendingNewDriver != null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _reassigning ? null : _confirmReassignDriver,
                              style: ElevatedButton.styleFrom(backgroundColor: _primary),
                              child: _reassigning
                                  ? const SizedBox(
                                      height: 16, width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text('Reassign to ${_pendingNewDriver!['name'] ?? 'this driver'}',
                                      style: _inter(size: 13, weight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

            // Driver Name — alphabets only, max 25
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: TextFormField(
                controller: _driverName,
                focusNode: _driverNameFocus,
                style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
                validator: _validateDriverName,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  LengthLimitingTextInputFormatter(25),
                ],
                decoration: _dec('Driver Name'),
              ),
            ),
            _FieldAttribution(username: _attrOf('driver_name')),
            const SizedBox(height: 8),

            // Driver Phone — +91 shown as static prefix, user enters 10 digits
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: TextFormField(
                controller: _driverPhone,
                focusNode: _driverPhoneFocus,
                keyboardType: TextInputType.number,
                style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
                validator: _validatePhone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: _dec('Phone Number').copyWith(
                  prefixText: '+91 ',
                  prefixStyle: _inter(size: 13, color: _onSurface, weight: FontWeight.w600),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
            ),
            _FieldAttribution(username: _attrOf('driver_phone')),
            const SizedBox(height: 8),

            // Driving License — alphanumeric, 10-18 chars
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TextFormField(
                controller: _drivingLicense,
                focusNode: _drivingLicenseFocus,
                style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
                validator: _validateDrivingLicense,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9/\-]')),
                  LengthLimitingTextInputFormatter(18),
                ],
                decoration: _dec('Driving License No.'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 4),
              child: Text(
                'New: RJ1420230012345   Old: RJ14/1234/2009',
                style: _inter(size: 11, color: _secondary),
              ),
            ),
            _FieldAttribution(username: _attrOf('driving_license')),
            const SizedBox(height: 8),

            // Aadhaar — exactly 12 digits
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: TextFormField(
                controller: _aadhaar,
                focusNode: _aadhaarFocus,
                keyboardType: TextInputType.number,
                style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
                validator: _validateAadhaar,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: _dec('Aadhaar Number (12 digits)'),
              ),
            ),
            _FieldAttribution(username: _attrOf('aadhaar')),
            const SizedBox(height: 8),

            // Driving License — Front & Back
            _DocPairSection(
              title: 'Driving License',
              frontTile: _uploadTile(
                'Front Side',
                'Photo of the front of the driving license',
                _dlDoc,
                (f) => _dlDoc = f,
                () { setState(() => _dlDoc = null); _onUploadChanged(); },
                existingUrl: widget.trip.s1DrivingLicenseUrl,
                fieldKey: 'dl_doc',
                rrPreviewBytes: _rrPreview['dl_front'],
              ),
              backTile: _uploadTile(
                'Back Side',
                'Photo of the back of the driving license',
                _dlBackDoc,
                (f) => _dlBackDoc = f,
                () { setState(() => _dlBackDoc = null); _onUploadChanged(); },
                existingUrl: widget.trip.s1DrivingLicenseBackUrl,
                fieldKey: 'dl_back_doc',
                rrPreviewBytes: _rrPreview['dl_back'],
              ),
            ),

            // Aadhaar Card — Front & Back
            _DocPairSection(
              title: 'Aadhaar Card',
              frontTile: _uploadTile(
                'Front Side',
                'Photo of the front of the Aadhaar card',
                _aadhaarDoc,
                (f) => _aadhaarDoc = f,
                () { setState(() => _aadhaarDoc = null); _onUploadChanged(); },
                existingUrl: widget.trip.s1AadhaarUrl,
                fieldKey: 'aadhaar_doc',
                rrPreviewBytes: _rrPreview['aadhaar_front'],
              ),
              backTile: _uploadTile(
                'Back Side',
                'Photo of the back of the Aadhaar card',
                _aadhaarBackDoc,
                (f) => _aadhaarBackDoc = f,
                () { setState(() => _aadhaarBackDoc = null); _onUploadChanged(); },
                existingUrl: widget.trip.s1AadhaarBackUrl,
                fieldKey: 'aadhaar_back_doc',
                rrPreviewBytes: _rrPreview['aadhaar_back'],
              ),
            ),
            const SizedBox(height: 8),

            // ── Vehicle Documents ──────────────────────────────────────────────
            _SectionHeader(icon: Icons.directions_car_outlined, title: 'Vehicle Documents'),
            // RC — Front & Back (RC is the only vehicle doc RR itself supports
            // a back side for; PUC/Fitness/Permit stay front-only, matching RR web)
            _numberField('RC Number', _rcNumber, 'rc_number', validator: _validateRcNumber),
            _DocPairSection(
              title: 'RC (Registration Certificate)',
              frontTile: _uploadTile(
                'Front Side',
                'Photo of the front of the RC',
                _rcDoc,
                (f) => _rcDoc = f,
                () { setState(() => _rcDoc = null); _onUploadChanged(); },
                existingUrl: widget.trip.s1Rc,
                fieldKey: 'rc_doc',
                rrPreviewBytes: _rrPreview['rc_front'],
              ),
              backTile: _uploadTile(
                'Back Side',
                'Photo of the back of the RC',
                _rcBackDoc,
                (f) => _rcBackDoc = f,
                () { setState(() => _rcBackDoc = null); _onUploadChanged(); },
                existingUrl: widget.trip.s1RcBack,
                fieldKey: 'rc_back_doc',
                rrPreviewBytes: _rrPreview['rc_back'],
              ),
            ),
            _numberField('Insurance Policy Number', _insuranceNumber, 'insurance_number'),
            _uploadTile('Insurance', 'Upload insurance document',
              _insuranceDoc, (f) => _insuranceDoc = f,
              () { setState(() => _insuranceDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1Insurance, fieldKey: 'insurance_doc',
              rrPreviewBytes: _rrPreview['insurance']),
            _numberField('PUC Number', _pucNumber, 'puc_number'),
            _uploadTile('Pollution Certificate', 'Upload pollution certificate',
              _pollutionDoc, (f) => _pollutionDoc = f,
              () { setState(() => _pollutionDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1Pollution, fieldKey: 'pollution_doc',
              rrPreviewBytes: _rrPreview['puc']),
            _numberField('Fitness Number', _fitnessNumber, 'fitness_number'),
            _uploadTile('Fitness Certificate', 'Upload fitness certificate',
              _fitnessDoc, (f) => _fitnessDoc = f,
              () { setState(() => _fitnessDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1Fitness, fieldKey: 'fitness_doc',
              rrPreviewBytes: _rrPreview['fitness']),
            _numberField('Permit Number', _permitNumber, 'permit_number'),
            _uploadTile('Permit', 'Upload permit document',
              _permitDoc, (f) => _permitDoc = f,
              () { setState(() => _permitDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1Permit, fieldKey: 'permit_doc',
              rrPreviewBytes: _rrPreview['permit']),
            const SizedBox(height: 8),

            // ── Owner Documents ────────────────────────────────────────────────
            _SectionHeader(icon: Icons.business_outlined, title: 'Owner Documents'),
            _uploadTile('PAN', 'Upload PAN card',
              _panDoc, (f) => _panDoc = f,
              () { setState(() => _panDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1Pan, fieldKey: 'pan_doc'),
            _uploadTile('Tax Declaration', 'Upload tax declaration document',
              _taxDeclDoc, (f) => _taxDeclDoc = f,
              () { setState(() => _taxDeclDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1TaxDeclaration, fieldKey: 'tax_decl_doc'),
            const SizedBox(height: 8),

            // ── Truck Owner Payment Details ────────────────────────────────────
            _SectionHeader(icon: Icons.account_balance_outlined, title: 'Truck Owner Payment Details'),
            _uploadTile('Cancelled Cheque (Owner / Transporter)', 'Upload a cancelled cheque',
              _cancelledChequeDoc, (f) => _cancelledChequeDoc = f,
              () { setState(() => _cancelledChequeDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1CancelledCheque, fieldKey: 'cancelled_cheque_doc'),
            const SizedBox(height: 8),

            if (_lastSaved != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined, size: 14, color: _success),
                    const SizedBox(width: 4),
                    Text('Last saved: ${_formatSaved(_lastSaved!)}',
                        style: _inter(size: 11, color: _success)),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (busy || widget.readOnly) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _StageTheme.rrWeb.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: busy
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save & Continue →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


String _formatSaved(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  return '${diff.inHours}h ago';
}

InputDecoration _stageFieldDec(String label) => InputDecoration(
  labelText: label,
  labelStyle: _inter(size: 12, color: _secondary),
  filled: true,
  fillColor: _surface,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primary, width: 1.5)),
);

// Safely extracts a human-readable message from a DioException's response
// body. FastAPI returns `detail` as a String for a plain HTTPException, but
// as a List of {loc, msg, type} objects for a 422 request-validation error —
// a naive `as String?` cast throws on every validation error instead of
// showing it, which is exactly what crashed Stage 5's resubmit-without-a-
// new-photo flow.
String _dioErrorDetail(DioException e, String fallback) {
  final data = e.response?.data;
  final detail = data is Map ? data['detail'] : null;
  if (detail is String && detail.isNotEmpty) return detail;
  if (detail is List) {
    final msgs = detail
        .map((d) => d is Map ? (d['msg']?.toString() ?? d.toString()) : d.toString())
        .where((s) => s.isNotEmpty)
        .toList();
    if (msgs.isNotEmpty) return msgs.join('; ');
  }
  return fallback;
}

// Surfaces a draft-save failure so it's visible instead of silently dropped
// (Stage 1's _saveDraft already did this; Stages 2-5 share this one helper).
void _showDraftSaveError(BuildContext context, Object e) {
  final status = e is DioException ? e.response?.statusCode : null;
  final detail = e is DioException
      ? _dioErrorDetail(e, e.message ?? 'Unknown error')
      : e.toString();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Draft save failed ($status): $detail',
        style: const TextStyle(fontSize: 12)),
    backgroundColor: Colors.orange.shade800,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 4),
  ));
}

// ─── Stage 2: Pre-Arrival Compliance Check ────────────────────────────────────

class _Stage2Form extends ConsumerStatefulWidget {
  final (String, int) providerKey;
  final TripModel trip;
  final VoidCallback? onEditDone;
  final bool readOnly;
  const _Stage2Form({super.key, required this.providerKey, required this.trip, this.onEditDone, this.readOnly = false});

  @override
  ConsumerState<_Stage2Form> createState() => _Stage2FormState();
}

class _Stage2FormState extends ConsumerState<_Stage2Form> {
  bool _specsVerified            = false;
  bool _docsVerified             = false;
  bool _driverDocsValid          = false;
  bool _entryPermission          = false; // actual state — set only by button press
  bool _entryPermissionChecked   = false; // visual checkbox — does not affect draft
  String? _dharamKantaLoc;  // 'inside' | 'outside'
  bool _s2WeightConfirmed   = false;
  final _emptyWeightCtrl    = TextEditingController();
  final _emptyWeightUnit    = ValueNotifier<String>('kg');
  XFile? _loadingSlipFile;   // optional loading slip — uploaded with Stage 2

  // ── Per-field attribution ─────────────────────────────────────────────────
  final Map<String, String> _fieldAttributions = {};
  final Set<String> _touchedByMe = {};
  void _touchField(String key) => _touchedByMe.add(key);
  String? _attrOf(String key) => _fieldAttributions[key];

  // ── Keys for auto-scroll on validation error ──────────────────────────────
  final _checklistKey         = GlobalKey();
  final _dharamKantaKey       = GlobalKey();
  final _weightSectionKey     = GlobalKey();
  final _entryPermissionKey   = GlobalKey();

  Timer? _debounce;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    _prefillFromDraft();
    _emptyWeightCtrl.addListener(_onWeightTextChanged);
  }

  @override
  void dispose() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      unawaited(_saveDraft(duringDispose: true));
    } else {
      _debounce?.cancel();
    }
    _emptyWeightCtrl.dispose();
    _emptyWeightUnit.dispose();
    super.dispose();
  }

  void _prefillFromDraft() {
    final trip = widget.trip;

    // Always load persistent field attributions first
    trip.fieldAttributions?.forEach((k, v) {
      if (v is String) _fieldAttributions[k] = v;
    });

    final draft = trip.draftData;
    if (draft != null && draft['stage'] == 2) {
      final d = draft['data'] as Map<String, dynamic>? ?? {};
      _specsVerified    = d['specs_verified']              as bool?   ?? false;
      _docsVerified     = d['docs_verified']               as bool?   ?? false;
      _driverDocsValid  = d['driver_docs_valid']           as bool?   ?? false;
      _entryPermissionChecked = d['entry_permission']       as bool?   ?? false;
      _dharamKantaLoc   = d['dharam_kanta_location']       as String?;
      _s2WeightConfirmed = d['s2_weight_confirmed']        as bool?   ?? false;
      _emptyWeightCtrl.text = d['empty_weight_before_loading'] as String? ?? '';
      _emptyWeightUnit.value = d['empty_weight_unit']      as String? ?? 'kg';
      // Draft attributions override persistent ones
      final attrs = draft['attributions'] as Map<String, dynamic>?;
      if (attrs != null) {
        attrs.forEach((k, v) { if (v is String) _fieldAttributions[k] = v; });
      }
      if (draft['saved_at'] != null) {
        _lastSaved = DateTime.tryParse(draft['saved_at'] as String);
      }
      return;
    }
    // Fall back to committed stage 2 data when re-editing
    if (trip.currentStage >= 2) {
      _specsVerified   = trip.s2SpecsVerified    ?? false;
      _docsVerified    = trip.s2DocsVerified     ?? false;
      _driverDocsValid = trip.s2DriverDocsValid  ?? false;
      _entryPermissionChecked = trip.s2EntryPermission  ?? false;

      // Restore dharam kanta data persisted at submission
      if (trip.s2DharamKantaLoc != null && trip.s2DharamKantaLoc!.isNotEmpty) {
        _dharamKantaLoc = trip.s2DharamKantaLoc;
        if (trip.s2DharamKantaLoc == 'outside' &&
            trip.s2EmptyWeightKg != null && trip.s2EmptyWeightKg!.isNotEmpty) {
          _emptyWeightCtrl.text = trip.s2EmptyWeightKg!;
          _emptyWeightUnit.value = trip.s2EmptyWeightUnit ?? 'kg';
          _s2WeightConfirmed = true;
        }
      }
    }
  }

  void _onWeightTextChanged() {
    _onFieldChanged();
  }

  void _onFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  void _onCheckChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  Future<void> _saveDraft({bool duringDispose = false}) async {
    if (!duringDispose && !mounted) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/draft', data: {
        'stage': 2,
        'data': {
          'specs_verified':             _specsVerified,
          'docs_verified':              _docsVerified,
          'driver_docs_valid':          _driverDocsValid,
          'entry_permission':           _entryPermission,
          'dharam_kanta_location':      _dharamKantaLoc ?? '',
          'empty_weight_before_loading': _emptyWeightCtrl.text.trim(),
          'empty_weight_unit':          _emptyWeightUnit.value,
          's2_weight_confirmed':        _s2WeightConfirmed,
        },
        if (_touchedByMe.isNotEmpty)
          'attributions': {for (final k in _touchedByMe) k: true},
      });
      if (!duringDispose && mounted) setState(() => _lastSaved = DateTime.now());
    } on DioException catch (e) {
      if (!duringDispose && mounted) _showDraftSaveError(context, e);
    } catch (_) {}
  }

  Future<void> _pickLoadingSlip(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;
      setState(() => _loadingSlipFile = picked);
    } catch (e) {
      if (!mounted) return;
      _showPickError(context, e, source);
    }
  }

  void _showSlipPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload Loading Slip', style: _manrope(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Attach the loading slip image', style: _inter(size: 12, color: _secondary)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _PickerOption(
                  icon: Icons.camera_alt_rounded, label: 'Camera', color: _primary,
                  onTap: () { Navigator.pop(context); _pickLoadingSlip(ImageSource.camera); },
                )),
                const SizedBox(width: 12),
                Expanded(child: _PickerOption(
                  icon: Icons.photo_library_rounded, label: 'Gallery', color: _secondary,
                  onTap: () { Navigator.pop(context); _pickLoadingSlip(ImageSource.gallery); },
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSlipTile() {
    final existingUrl = widget.trip.s2LoadingSlipUrl;

    // New file just picked — show thumbnail via FutureBuilder
    if (_loadingSlipFile != null) {
      return Container(
        decoration: BoxDecoration(
          color: _success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _success.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            FutureBuilder<Uint8List>(
              future: _loadingSlipFile!.readAsBytes(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(height: 140,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                }
                final bytes = snap.data!;
                return GestureDetector(
                  onTap: () => _showImagePreview(context, bytes: bytes),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        child: Image.memory(bytes,
                            width: double.infinity, height: 140, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: _success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_loadingSlipFile!.name,
                        style: _inter(size: 12, color: _success),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  GestureDetector(
                    onTap: _showSlipPicker,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Retake',
                          style: _manrope(size: 11, weight: FontWeight.w700, color: _primary)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _loadingSlipFile = null),
                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: _error),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Already uploaded to server — show thumbnail preview
    if (existingUrl != null) {
      final fullUrl = existingUrl.startsWith('http')
          ? existingUrl
          : '${AppConfig.apiBaseUrl}$existingUrl';
      return Container(
        decoration: BoxDecoration(
          color: _success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _success.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showImagePreview(context, url: fullUrl),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: Image.network(
                      fullUrl,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, prog) => prog == null
                          ? child
                          : const SizedBox(height: 140,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      errorBuilder: (_, __, ___) => const SizedBox(height: 80,
                          child: Center(child: Icon(Icons.broken_image_rounded, color: _secondary))),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, size: 16, color: _success),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Loading Slip',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: _success, fontFamily: 'Manrope')),
                  ),
                  GestureDetector(
                    onTap: _showSlipPicker,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('Replace',
                          style: _manrope(size: 11, weight: FontWeight.w700, color: _primary)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Nothing uploaded yet
    return GestureDetector(
      onTap: _showSlipPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE0E2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.upload_file_rounded, color: _secondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Loading Slip',
                      style: _manrope(size: 13, weight: FontWeight.w700, color: _onSurface)),
                  Text('Optional — tap to attach slip image',
                      style: _inter(size: 11, color: _secondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 300));
      }
    });
  }

  void _showError(GlobalKey key, String message) {
    _scrollToKey(key);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: _inter(size: 13, color: Colors.white)),
      backgroundColor: _error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _submit() async {
    // 1. All 3 verification checkboxes must be checked
    if (!_specsVerified || !_docsVerified || !_driverDocsValid) {
      _showError(_checklistKey, 'Please confirm all verification items before proceeding.');
      return;
    }

    // 2. Dharam Kanta location must be selected (inside or outside)
    if (_dharamKantaLoc == null) {
      _showError(_dharamKantaKey, 'Please select weighbridge location (Inside or Outside Factory).');
      return;
    }

    // 3. If Outside Factory, weight must be entered (> 0) and confirmed
    if (_dharamKantaLoc == 'outside') {
      final weightVal = double.tryParse(_emptyWeightCtrl.text.trim()) ?? 0;
      if (_emptyWeightCtrl.text.trim().isEmpty || weightVal <= 0 || !_s2WeightConfirmed) {
        _showError(_weightSectionKey,
            'Please enter a valid empty truck weight (greater than 0) and confirm it.');
        return;
      }
    }

    // 4. Entry permission checkbox must be checked
    if (!_entryPermissionChecked) {
      _showError(_entryPermissionKey, 'Please check "Truck Entry Permission Issued" before proceeding.');
      return;
    }

    if (!_entryPermission) {
      _scrollToKey(_entryPermissionKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entry Permission must be issued to proceed.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    // Persist DK data into shared provider state before submit
    if (_dharamKantaLoc == 'outside' && _emptyWeightCtrl.text.trim().isNotEmpty) {
      ref.read(tripStagesProvider(widget.providerKey).notifier)
          .setS2DharamKanta('outside', _emptyWeightCtrl.text.trim(), _emptyWeightUnit.value);
    }

    final formData = FormData.fromMap({
      'specs_verified':          _specsVerified.toString(),
      'docs_verified':           _docsVerified.toString(),
      'driver_docs_valid':       _driverDocsValid.toString(),
      'entry_permission':        _entryPermission.toString(),
      'dharam_kanta_location':   _dharamKantaLoc ?? '',
      if (_dharamKantaLoc == 'outside' && _emptyWeightCtrl.text.trim().isNotEmpty) ...{
        'empty_weight_before_loading': _emptyWeightCtrl.text.trim(),
        'empty_weight_unit':           _emptyWeightUnit.value,
      },
    });
    if (_loadingSlipFile != null) {
      final bytes = await _loadingSlipFile!.readAsBytes();
      formData.files.add(MapEntry(
        'loading_slip',
        MultipartFile.fromBytes(bytes, filename: _loadingSlipFile!.name),
      ));
    }
    final ok = await ref.read(tripStagesProvider(widget.providerKey).notifier).submitStage2(formData);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entry permission issued. Coordinate truck arrival.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      widget.onEditDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(tripStagesProvider(widget.providerKey)).isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stage 2 attribution — who submitted this stage (LP side only)
          _StageAttribution(
            username: widget.trip.currentStage >= 2
                ? widget.trip.s2SubmittedByUsername
                : null,
          ),

          // Trip info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: _primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.trip.tripNumber,
                          style: _manrope(size: 13, weight: FontWeight.w800, color: _primary)),
                      Text('${widget.trip.origin} → ${widget.trip.destination}',
                          style: _inter(size: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('RR Executive verifies:',
              style: _manrope(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('All items must be confirmed before issuing entry permission.',
              style: _inter(size: 12)),
          const SizedBox(height: 16),

          _CheckItem(
            key: _checklistKey,
            label: 'Truck specifications match requirement',
            value: _specsVerified,
            onChanged: (v) { setState(() => _specsVerified = v); _touchField('specs_verified'); _onCheckChanged(); },
          ),
          _CheckItem(
            label: 'All documents uploaded',
            value: _docsVerified,
            onChanged: (v) { setState(() => _docsVerified = v); _touchField('docs_verified'); _onCheckChanged(); },
          ),
          _CheckItem(
            label: 'Driver documents valid',
            value: _driverDocsValid,
            onChanged: (v) { setState(() => _driverDocsValid = v); _touchField('driver_docs_valid'); _onCheckChanged(); },
          ),
          const SizedBox(height: 20),

          // ── Dharam Kanta (Weighbridge) location ──
          Container(
            key: _dharamKantaKey,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 1.5),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.scale_outlined, color: _primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Dharam Kanta (Weighbridge)',
                      style: _manrope(size: 14, weight: FontWeight.w700)),
                ]),
                const SizedBox(height: 3),
                Text('Is the weighbridge inside or outside the factory?',
                    style: _inter(size: 12)),
                const SizedBox(height: 12),

                // Inside Factory checkbox
                _CheckItem(
                  label: 'Inside Factory',
                  value: _dharamKantaLoc == 'inside',
                  onChanged: (v) {
                    setState(() {
                      _dharamKantaLoc = v ? 'inside' : null;
                      if (v) {
                        _emptyWeightCtrl.clear();
                        _s2WeightConfirmed = false;
                      }
                    });
                    _touchField('dharam_kanta_location');
                    _onCheckChanged();
                  },
                ),

                // Outside Factory checkbox
                _CheckItem(
                  label: 'Outside Factory',
                  value: _dharamKantaLoc == 'outside',
                  onChanged: (v) {
                    setState(() {
                      _dharamKantaLoc = v ? 'outside' : null;
                      if (v) {
                        _emptyWeightCtrl.clear();
                        _s2WeightConfirmed = false;
                      }
                    });
                    _touchField('dharam_kanta_location');
                    _onCheckChanged();
                  },
                ),

                // Weight input — only shown when Outside Factory is selected
                if (_dharamKantaLoc == 'outside') ...[
                  const SizedBox(height: 14),
                  _WeighField(
                    key: _weightSectionKey,
                    controller: _emptyWeightCtrl,
                    label: 'Empty Truck Weight Before Loading',
                    hint: 'e.g. 12.5',
                    note: 'Weight recorded outside factory (before loading).',
                    unitNotifier: _emptyWeightUnit,
                    enabled: !_s2WeightConfirmed && !widget.readOnly,
                  ),
                  _FieldAttribution(username: _attrOf('empty_weight_before_loading')),
                  const SizedBox(height: 10),
                  if (!_s2WeightConfirmed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final val = double.tryParse(_emptyWeightCtrl.text.trim()) ?? 0;
                        if (_emptyWeightCtrl.text.trim().isEmpty || val <= 0) return;
                        _touchField('empty_weight_before_loading');
                        ref
                            .read(tripStagesProvider(widget.providerKey).notifier)
                            .setS2DharamKanta('outside', _emptyWeightCtrl.text.trim(), _emptyWeightUnit.value);
                        setState(() => _s2WeightConfirmed = true);
                        FocusScope.of(context).unfocus();
                        _saveDraft();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _StageTheme.rrWeb.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFDDE0E2),
                        disabledForegroundColor: _secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.input_rounded, size: 16),
                      label: const Text('Confirm Weight'),
                    ),
                  ),
                  if (_s2WeightConfirmed)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: _success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: _success, size: 16),
                        const SizedBox(width: 8),
                        Text('Weight recorded: ${_emptyWeightCtrl.text.trim()} ${_emptyWeightUnit.value}',
                            style: _manrope(size: 13, weight: FontWeight.w700, color: _success)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Entry permission — highlighted
          Container(
            key: _entryPermissionKey,
            decoration: BoxDecoration(
              color: _entryPermissionChecked
                  ? _success.withValues(alpha: 0.08)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _entryPermissionChecked ? _success : _primary,
                width: 1.5,
              ),
            ),
            child: _CheckItem(
              label: 'Truck Entry Permission Issued',
              sublabel: 'Factory logistics team receives truck number + driver details.',
              value: _entryPermissionChecked,
              onChanged: (v) => setState(() => _entryPermissionChecked = v),
              activeColor: _success,
            ),
          ),
          const SizedBox(height: 28),

          // ── Loading Slip (optional — can also be uploaded after Stage 2) ──
          _buildLoadingSlipTile(),
          const SizedBox(height: 16),

          if (_lastSaved != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_outlined, size: 14, color: _success),
                  const SizedBox(width: 4),
                  Text('Last saved: ${_formatSaved(_lastSaved!)}',
                      style: _inter(size: 11, color: _success)),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (busy || widget.readOnly) ? null : () {
                setState(() => _entryPermission = true);
                _submit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _entryPermissionChecked ? _success : _secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: busy
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Issue Entry Permission →'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Slip Mini-Stage (between Stage 2 and Stage 3) ───────────────────

class _LoadingSlipMini extends ConsumerStatefulWidget {
  final TripModel trip;
  final void Function(TripModel updated) onUploaded;
  const _LoadingSlipMini({super.key, required this.trip, required this.onUploaded});

  @override
  ConsumerState<_LoadingSlipMini> createState() => _LoadingSlipMiniState();
}

class _LoadingSlipMiniState extends ConsumerState<_LoadingSlipMini> {
  ({Uint8List bytes, String name})? _slipFile;
  bool _uploading = false;
  String? _errorMsg;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _prefillFromDraft();
  }

  void _prefillFromDraft() {
    final draft = widget.trip.draftData;
    if (draft == null) return;
    if (draft['stage'] != 'loading_slip') return;
    final data = draft['data'] as Map<String, dynamic>?;
    if (data == null) return;
    final b64 = data['slip_bytes'] as String?;
    final name = data['slip_name'] as String? ?? 'loading_slip.jpg';
    if (b64 != null && b64.isNotEmpty) {
      try {
        final bytes = base64Decode(b64);
        setState(() => _slipFile = (bytes: bytes, name: name));
      } catch (_) {}
    }
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/draft', data: {
        'stage': 'loading_slip',
        'data': {
          if (_slipFile != null) 'slip_bytes': base64Encode(_slipFile!.bytes),
          if (_slipFile != null) 'slip_name': _slipFile!.name,
        },
      });
    } catch (_) {}
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _slipFile = (bytes: bytes, name: picked.name);
        _errorMsg = null;
      });
      _saveDraft();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = _pickErrorMessage(e, source));
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload Loading Slip', style: _manrope(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Choose how to add the slip image', style: _inter(size: 12, color: _secondary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: _primary,
                      onTap: () { Navigator.pop(context); _pick(ImageSource.camera); },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: _secondary,
                      onTap: () { Navigator.pop(context); _pick(ImageSource.gallery); },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _upload() async {
    if (_slipFile == null) return;
    setState(() { _uploading = true; _errorMsg = null; });
    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'slip': MultipartFile.fromBytes(_slipFile!.bytes, filename: _slipFile!.name),
      });
      final resp = await dio.post(
        '/api/trips/${widget.trip.id}/loading-slip',
        data: formData,
      );
      final updated = TripModel.fromJson(
        (resp.data as Map<String, dynamic>)['trip'] as Map<String, dynamic>,
      );
      if (mounted) widget.onUploaded(updated);
    } catch (e) {
      final msg = e is DioException
          ? _dioErrorDetail(e, 'Upload failed')
          : e.toString();
      setState(() { _uploading = false; _errorMsg = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingUrl = widget.trip.s2LoadingSlipUrl;
    final showExisting = existingUrl != null && _slipFile == null;
    final imageUrl = existingUrl != null
        ? '${AppConfig.apiBaseUrl}$existingUrl'
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — green if already uploaded, orange if pending
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: showExisting
                  ? _success.withValues(alpha: 0.07)
                  : _primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: showExisting
                    ? _success.withValues(alpha: 0.25)
                    : _primary.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: showExisting
                        ? _success.withValues(alpha: 0.12)
                        : _primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    showExisting
                        ? Icons.check_circle_rounded
                        : Icons.receipt_long_rounded,
                    color: showExisting ? _success : _primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showExisting
                            ? 'Loading Slip Uploaded'
                            : 'Loading Slip Required',
                        style: _manrope(size: 15, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        showExisting
                            ? 'Slip uploaded by transporter. Tap image to replace if needed.'
                            : 'Upload the loading slip before the truck can proceed to the factory.',
                        style: _inter(size: 12, color: _secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(icon: Icons.upload_file_rounded, title: 'Loading Slip'),

          // Upload tile / preview
          GestureDetector(
            onTap: _showPickerSheet,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _slipFile != null
                      ? _success.withValues(alpha: 0.50)
                      : showExisting
                          ? _success.withValues(alpha: 0.30)
                          : _border,
                  width: (_slipFile != null || showExisting) ? 1.5 : 1,
                ),
              ),
              child: _slipFile != null
                  // ── Newly picked local file preview ──────────────────────
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.memory(
                            _slipFile!.bytes,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () { setState(() => _slipFile = null); _saveDraft(); },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close_rounded, size: 16, color: _error),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _success,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text('Ready to Upload', style: _inter(size: 11, color: Colors.white, weight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : showExisting
                  // ── Existing server-uploaded slip ─────────────────────────
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.network(
                            imageUrl!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) => progress == null
                                ? child
                                : SizedBox(
                                    height: 220,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _success,
                                        value: progress.expectedTotalBytes != null
                                            ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  ),
                            errorBuilder: (_, __, ___) => SizedBox(
                              height: 220,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_rounded,
                                        size: 36, color: _secondary.withValues(alpha: 0.4)),
                                    const SizedBox(height: 8),
                                    Text('Could not load image',
                                        style: _inter(size: 12, color: _secondary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Uploaded badge
                        Positioned(
                          top: 8, left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _success,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text('Slip Uploaded', style: _inter(size: 11, color: Colors.white, weight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        // Tap to replace hint
                        Positioned(
                          bottom: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text('Tap to replace', style: _inter(size: 11, color: Colors.white, weight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  // ── Empty — no slip yet ───────────────────────────────────
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 40, color: _secondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          Text('Tap to upload loading slip',
                              style: _inter(size: 13, weight: FontWeight.w600, color: _secondary)),
                          const SizedBox(height: 4),
                          Text('Camera or Gallery',
                              style: _inter(size: 11, color: _secondary.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
            ),
          ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: _error, size: 15),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMsg!, style: _inter(size: 12, color: _error))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Only show upload button when a new file has been picked (to replace)
          if (_slipFile != null || !showExisting)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_slipFile != null && !_uploading) ? _upload : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFDDE0E2),
                  disabledForegroundColor: _secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                icon: _uploading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.upload_rounded, size: 20),
                label: Text(_uploading ? 'Uploading...' : 'Submit Loading Slip'),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Stage 3: Truck Arrival at Factory ────────────────────────────────────────

class _Stage3Form extends ConsumerStatefulWidget {
  final (String, int) providerKey;
  final TripModel trip;
  final VoidCallback? onEditDone;
  final bool readOnly;
  const _Stage3Form({super.key, required this.providerKey, required this.trip, this.onEditDone, this.readOnly = false});

  @override
  ConsumerState<_Stage3Form> createState() => _Stage3FormState();
}

class _Stage3FormState extends ConsumerState<_Stage3Form> {
  bool _driverParked       = false;
  bool _docsSubmitted      = false;
  bool _securityVerified   = false;
  bool _driverExitedCabin  = false;
  bool _wheelStoppers      = false;
  bool _safetyGear         = false;

  // RR loading.truck_reach_datetime / loading.start_datetime
  DateTime? _vehicleReachDatetime;
  DateTime? _loadingStartDatetime;
  bool _showDatetimeErrors = false;

  // ── Per-field attribution ─────────────────────────────────────────────────
  final Map<String, String> _fieldAttributions = {};
  final Set<String> _touchedByMe = {};
  void _touchField(String key) => _touchedByMe.add(key);
  String? _attrOf(String key) => _fieldAttributions[key];

  // ── Keys for auto-scroll on validation error ──────────────────────────────
  final _driverParkedKey      = GlobalKey();
  final _docsSubmittedKey     = GlobalKey();
  final _securityVerifiedKey  = GlobalKey();
  final _driverExitedCabinKey = GlobalKey();
  final _wheelStoppersKey     = GlobalKey();
  final _safetyGearKey        = GlobalKey();
  final _vehicleReachKey      = GlobalKey();
  final _loadingStartKey      = GlobalKey();

  final _emptyTruckWeight  = TextEditingController();
  final _loadedTruckWeight = TextEditingController();
  final _emptyWeightUnit   = ValueNotifier<String>('kg');
  final _loadedWeightUnit  = ValueNotifier<String>('kg');
  ({Uint8List bytes, String name})? _weightSlipData;

  // "Loading Completed" checkbox — part of the checklist required before
  // Complete Stage; no longer gates visibility of the rest of the form.
  bool _loadingComplete = false;

  // Stage 2 Dharam Kanta data — persisted in draft for cross-session restore
  String? _s2DharamKantaLoc;
  String? _s2EmptyWeight;
  String? _s2EmptyWeightUnit;

  // Document uploads — stored as (bytes, filename) tuples for web compatibility
  ({Uint8List bytes, String name})? _ewayBillData;
  final _ewayBillNumberCtrl = TextEditingController();
  DateTime? _ewayBillIssueDate;
  DateTime? _ewayBillExpiryDate;
  ({Uint8List bytes, String name})? _materialDocs;
  // Invoice number off the same document, entered alongside the invoice value.
  final _invoiceNumberCtrl = TextEditingController();
  // Real invoice amount, entered once the invoice document above is actually
  // uploaded — replaces the rough placeholder entered at trip creation.
  final _actualInvoiceValueCtrl = TextEditingController();

  Timer? _debounce;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    _prefillFromDraft();
    _emptyTruckWeight.addListener(() { _touchField('empty_truck_weight'); _onFieldChanged(); });
    _loadedTruckWeight.addListener(() { _touchField('loaded_truck_weight'); _onFieldChanged(); });
    _emptyWeightUnit.addListener(_onFieldChanged);
    _loadedWeightUnit.addListener(_onFieldChanged);
    _ewayBillNumberCtrl.addListener(() { _touchField('eway_bill_number'); _onFieldChanged(); });
    _invoiceNumberCtrl.addListener(() { _touchField('invoice_number'); _onFieldChanged(); });
    _actualInvoiceValueCtrl.addListener(() { _touchField('actual_invoice_value'); _onFieldChanged(); });
    // Restore S2 Dharam Kanta into provider after first frame (ref available)
    if (_s2DharamKantaLoc == 'outside' && (_s2EmptyWeight?.isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tripStagesProvider(widget.providerKey).notifier)
            .setS2DharamKanta('outside', _s2EmptyWeight!, _s2EmptyWeightUnit ?? 'kg');
      });
    }
  }

  void _prefillFromDraft() {
    final trip = widget.trip;

    // Always load persistent field attributions first
    trip.fieldAttributions?.forEach((k, v) {
      if (v is String) _fieldAttributions[k] = v;
    });

    final draft = trip.draftData;
    if (draft == null || draft['stage'] != 3) {
      // No draft — prefill weights from committed trip data when re-editing
      if (trip.currentStage >= 3) {
        _emptyTruckWeight.text  = trip.s3EmptyTruckWeightKg  ?? '';
        _loadedTruckWeight.text = trip.s3LoadedTruckWeightKg ?? '';
        _emptyWeightUnit.value  = trip.s3EmptyTruckWeightUnit ?? 'kg';
        _loadedWeightUnit.value = trip.s3LoadedTruckWeightUnit ?? 'kg';
        if (trip.s3VehicleReachDatetime != null) {
          _vehicleReachDatetime = DateTime.tryParse(trip.s3VehicleReachDatetime!);
        }
        if (trip.s3LoadingStartDatetime != null) {
          _loadingStartDatetime = DateTime.tryParse(trip.s3LoadingStartDatetime!);
        }
        _ewayBillNumberCtrl.text = trip.s3EwayBillNumber ?? '';
        if (trip.s3EwayBillIssueDate != null) {
          _ewayBillIssueDate = DateTime.tryParse(trip.s3EwayBillIssueDate!);
        }
        if (trip.s3EwayBillExpiryDate != null) {
          _ewayBillExpiryDate = DateTime.tryParse(trip.s3EwayBillExpiryDate!);
        }
        _invoiceNumberCtrl.text = trip.s3InvoiceNumber ?? '';
        if (trip.s3ActualInvoiceValue != null) {
          _actualInvoiceValueCtrl.text = trip.s3ActualInvoiceValue!.toStringAsFixed(2);
        }
      }
      return;
    }
    final d = draft['data'] as Map<String, dynamic>? ?? {};
    _loadingComplete    = d['loading_complete']     as bool? ?? false;
    // Checkboxes aren't drafted individually — if loading_complete was true,
    // all 6 were necessarily true when it was set, so re-derive them here
    // rather than silently resubmitting false checklist values on restore.
    if (_loadingComplete) {
      _driverParked = _docsSubmitted = _securityVerified =
          _driverExitedCabin = _wheelStoppers = _safetyGear = true;
    }
    _emptyTruckWeight.text = d['empty_truck_weight']      as String? ?? '';
    _loadedTruckWeight.text = d['loaded_truck_weight']    as String? ?? '';
    _emptyWeightUnit.value = d['empty_truck_weight_unit'] as String? ?? 'kg';
    _loadedWeightUnit.value = d['loaded_truck_weight_unit'] as String? ?? 'kg';
    final vehicleReachStr = d['vehicle_reach_datetime'] as String?;
    if (vehicleReachStr != null) _vehicleReachDatetime = DateTime.tryParse(vehicleReachStr);
    final loadingStartStr = d['loading_start_datetime'] as String?;
    if (loadingStartStr != null) _loadingStartDatetime = DateTime.tryParse(loadingStartStr);
    // Restore Stage 2 Dharam Kanta data (if weight was recorded outside factory)
    _s2DharamKantaLoc   = d['s2_dharam_kanta_loc']    as String?;
    _s2EmptyWeight      = d['s2_empty_weight']         as String?;
    _s2EmptyWeightUnit  = d['s2_empty_weight_unit_s2'] as String?;
    // Restore loaded weight slip upload
    final slipB64  = d['weight_slip_b64']  as String?;
    final slipName = d['weight_slip_name'] as String?;
    if (slipB64 != null && slipName != null) {
      _weightSlipData = (bytes: base64Decode(slipB64), name: slipName);
    }
    // Restore e-way bill upload
    _ewayBillNumberCtrl.text = d['eway_bill_number'] as String? ?? '';
    final ewayIssueStr = d['eway_bill_issue_date'] as String?;
    if (ewayIssueStr != null) _ewayBillIssueDate = DateTime.tryParse(ewayIssueStr);
    final ewayExpiryStr = d['eway_bill_expiry_date'] as String?;
    if (ewayExpiryStr != null) _ewayBillExpiryDate = DateTime.tryParse(ewayExpiryStr);
    final ewayB64 = d['eway_bill_b64'] as String?;
    final ewayName = d['eway_bill_name'] as String?;
    if (ewayB64 != null && ewayName != null) {
      _ewayBillData = (bytes: base64Decode(ewayB64), name: ewayName);
    }
    // Restore invoice upload
    final matB64 = d['material_doc_b64'] as String?;
    final matName = d['material_doc_name'] as String?;
    if (matB64 != null && matName != null) {
      _materialDocs = (bytes: base64Decode(matB64), name: matName);
    } else {
      // Back-compat: older drafts stored a list under 'material_docs' — take
      // only the first entry, matching the new single-file behavior.
      final matList = d['material_docs'] as List<dynamic>?;
      if (matList != null && matList.isNotEmpty) {
        final m = matList.first as Map<String, dynamic>?;
        if (m != null && m['b64'] != null && m['name'] != null) {
          _materialDocs = (bytes: base64Decode(m['b64'] as String), name: m['name'] as String);
        }
      }
    }
    _invoiceNumberCtrl.text = d['invoice_number'] as String? ?? '';
    _actualInvoiceValueCtrl.text = d['actual_invoice_value'] as String? ?? '';
    // Draft attributions override persistent ones
    final attrs = draft['attributions'] as Map<String, dynamic>?;
    if (attrs != null) {
      attrs.forEach((k, v) { if (v is String) _fieldAttributions[k] = v; });
    }
    if (draft['saved_at'] != null) {
      _lastSaved = DateTime.tryParse(draft['saved_at'] as String);
    }
  }

  void _onFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  void _onCheckChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  Future<void> _saveDraft({bool duringDispose = false}) async {
    if (!duringDispose && !mounted) return;
    try {
      // Snapshot S2 Dharam Kanta from provider (same-session) or local vars (cross-session restore)
      final stagesState = ref.read(tripStagesProvider(widget.providerKey));
      final s2Loc    = stagesState.s2DharamKantaLoc  ?? _s2DharamKantaLoc;
      final s2Weight = stagesState.s2EmptyWeight      ?? _s2EmptyWeight;
      final s2Unit   = stagesState.s2EmptyWeightUnit  ?? _s2EmptyWeightUnit;

      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/draft', data: {
        'stage': 3,
        'data': {
          // Checkboxes are intentionally not drafted — loading_complete alone
          // gates phase 2, and can only be true if all 6 were checked when it
          // was set, so they're re-derived as true on restore (see prefill).
          'loading_complete':        _loadingComplete,
          'empty_truck_weight':      _emptyTruckWeight.text.trim(),
          'empty_truck_weight_unit': _emptyWeightUnit.value,
          'loaded_truck_weight':     _loadedTruckWeight.text.trim(),
          'loaded_truck_weight_unit': _loadedWeightUnit.value,
          if (_vehicleReachDatetime != null)
            'vehicle_reach_datetime': _vehicleReachDatetime!.toIso8601String(),
          if (_loadingStartDatetime != null)
            'loading_start_datetime': _loadingStartDatetime!.toIso8601String(),
          // Persist S2 Dharam Kanta so it survives re-entry
          if (s2Loc != null) ...{
            's2_dharam_kanta_loc':    s2Loc,
            's2_empty_weight':        s2Weight ?? '',
            's2_empty_weight_unit_s2': s2Unit ?? 'kg',
          },
          // Loaded weight slip upload
          if (_weightSlipData != null) ...{
            'weight_slip_b64':  base64Encode(_weightSlipData!.bytes),
            'weight_slip_name': _weightSlipData!.name,
          },
          // E-way bill upload
          'eway_bill_number': _ewayBillNumberCtrl.text.trim(),
          if (_ewayBillIssueDate != null)
            'eway_bill_issue_date': _ewayBillIssueDate!.toIso8601String(),
          if (_ewayBillExpiryDate != null)
            'eway_bill_expiry_date': _ewayBillExpiryDate!.toIso8601String(),
          if (_ewayBillData != null) ...{
            'eway_bill_b64':  base64Encode(_ewayBillData!.bytes),
            'eway_bill_name': _ewayBillData!.name,
          },
          // Invoice upload
          if (_materialDocs != null) ...{
            'material_doc_b64':  base64Encode(_materialDocs!.bytes),
            'material_doc_name': _materialDocs!.name,
          },
          'invoice_number': _invoiceNumberCtrl.text.trim(),
          'actual_invoice_value': _actualInvoiceValueCtrl.text.trim(),
        },
        if (_touchedByMe.isNotEmpty)
          'attributions': {for (final k in _touchedByMe) k: true},
      });
      if (mounted) setState(() => _lastSaved = DateTime.now());
    } catch (_) {}
  }

  final _picker = ImagePicker();

  @override
  void dispose() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      unawaited(_saveDraft(duringDispose: true));
    } else {
      _debounce?.cancel();
    }
    _emptyTruckWeight.dispose();
    _loadedTruckWeight.dispose();
    _emptyWeightUnit.dispose();
    _loadedWeightUnit.dispose();
    _ewayBillNumberCtrl.dispose();
    _invoiceNumberCtrl.dispose();
    _actualInvoiceValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEwayBill(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      setState(() => _ewayBillData = (bytes: bytes, name: picked.name));
      _touchField('eway_bill_doc');
      _saveDraft();
    } catch (e) {
      if (!mounted) return;
      _showPickError(context, e, source);
    }
  }

  Future<void> _pickMaterialDocs(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      setState(() => _materialDocs = (bytes: bytes, name: picked.name));
      _touchField('material_docs');
      _saveDraft();
    } catch (e) {
      if (!mounted) return;
      _showPickError(context, e, source);
    }
  }

  void _removeMaterialDoc() {
    setState(() => _materialDocs = null);
    _touchField('material_docs');
    _saveDraft();
  }

  bool get _checklistDone =>
      _driverParked && _docsSubmitted && _securityVerified &&
      _driverExitedCabin && _wheelStoppers && _safetyGear &&
      _vehicleReachDatetime != null && _loadingStartDatetime != null;

  bool get _allChecked => _checklistDone && _loadingComplete;

  void _scrollToKey3(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 300));
      }
    });
  }

  void _scrollToFirstUnchecked() {
    final checks = [
      (_driverParkedKey,      _driverParked),
      (_docsSubmittedKey,     _docsSubmitted),
      (_securityVerifiedKey,  _securityVerified),
      (_driverExitedCabinKey, _driverExitedCabin),
      (_wheelStoppersKey,     _wheelStoppers),
      (_safetyGearKey,        _safetyGear),
      (_vehicleReachKey,      _vehicleReachDatetime != null),
      (_loadingStartKey,      _loadingStartDatetime != null),
    ];
    for (final (key, checked) in checks) {
      if (!checked) {
        _scrollToKey3(key);
        return;
      }
    }
  }

  void _onLoadingCompleteToggle(bool v) {
    if (v && !_checklistDone) {
      setState(() => _showDatetimeErrors = true);
      _scrollToFirstUnchecked();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All steps must be completed before marking loading complete.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() => _loadingComplete = v);
    _saveDraft();
  }

  Future<void> _completeStage() async {
    if (!_checklistDone) {
      setState(() => _showDatetimeErrors = true);
      _scrollToFirstUnchecked();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All steps must be completed before completing the stage.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (!_loadingComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please check "Loading Completed" before completing the stage.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final stagesState = ref.read(tripStagesProvider(widget.providerKey));
    final s2Weight = stagesState.s2EmptyWeight ?? _s2EmptyWeight ?? '';
    final weightFromS2 =
        (stagesState.s2DharamKantaLoc == 'outside' || _s2DharamKantaLoc == 'outside') &&
        s2Weight.isNotEmpty;

    final fields = <String, dynamic>{
      'driver_parked':            _driverParked.toString(),
      'docs_submitted':           _docsSubmitted.toString(),
      'security_verified':        _securityVerified.toString(),
      'driver_exited_cabin':      _driverExitedCabin.toString(),
      'wheel_stoppers':           _wheelStoppers.toString(),
      'safety_gear':              _safetyGear.toString(),
      // Use Stage 2 weight if it was captured there, otherwise Stage 3 entry
      'empty_truck_weight_kg':    weightFromS2 ? s2Weight : _emptyTruckWeight.text.trim(),
      'empty_truck_weight_unit':  weightFromS2 ? (stagesState.s2EmptyWeightUnit ?? _s2EmptyWeightUnit ?? 'kg') : _emptyWeightUnit.value,
      'loaded_truck_weight_kg':   _loadedTruckWeight.text.trim(),
      'loaded_truck_weight_unit': _loadedWeightUnit.value,
      'vehicle_reach_datetime':   _vehicleReachDatetime!.toIso8601String(),
      'loading_start_datetime':   _loadingStartDatetime!.toIso8601String(),
      if (_ewayBillNumberCtrl.text.trim().isNotEmpty)
        'eway_bill_number': _ewayBillNumberCtrl.text.trim(),
      if (_ewayBillIssueDate != null)
        'eway_bill_issue_date': _ewayBillIssueDate!.toIso8601String(),
      if (_ewayBillExpiryDate != null)
        'eway_bill_expiry_date': _ewayBillExpiryDate!.toIso8601String(),
      if (_invoiceNumberCtrl.text.trim().isNotEmpty)
        'invoice_number': _invoiceNumberCtrl.text.trim(),
      if (_actualInvoiceValueCtrl.text.trim().isNotEmpty)
        'actual_invoice_value': _actualInvoiceValueCtrl.text.trim(),
    };

    if (_lastSaved != null) {
      // draft is cleared by server on submit — nothing extra needed
    }

    if (_weightSlipData != null) {
      fields['loaded_weight_slip'] = MultipartFile.fromBytes(
        _weightSlipData!.bytes,
        filename: _weightSlipData!.name,
      );
    }
    if (_ewayBillData != null) {
      fields['eway_bill'] = MultipartFile.fromBytes(
        _ewayBillData!.bytes,
        filename: _ewayBillData!.name,
      );
    }

    if (_materialDocs != null) {
      fields['material_docs'] = [
        MultipartFile.fromBytes(_materialDocs!.bytes, filename: _materialDocs!.name),
      ];
    }

    final formData = FormData.fromMap(fields);
    final ok = await ref.read(tripStagesProvider(widget.providerKey).notifier).submitStage3(formData);
    if (ok && mounted) {
      widget.onEditDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stagesState = ref.watch(tripStagesProvider(widget.providerKey));
    final busy = stagesState.isSubmitting;
    final s2Weight = stagesState.s2EmptyWeight ?? _s2EmptyWeight ?? '';
    final weightFromS2 =
        (stagesState.s2DharamKantaLoc == 'outside' || _s2DharamKantaLoc == 'outside') &&
        s2Weight.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stage 3 attribution — who submitted this stage (LP side only)
          _StageAttribution(
            username: widget.trip.currentStage >= 3
                ? widget.trip.s3SubmittedByUsername
                : null,
          ),

          Text('RR Executive coordinates with driver:',
              style: _manrope(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 16),

          _SectionHeader(icon: Icons.local_parking_rounded, title: 'Arrival Steps'),
          _CheckItem(
            key: _driverParkedKey,
            label: 'Driver parks outside factory',
            value: _driverParked,
            onChanged: (v) { setState(() => _driverParked = v); _touchField('driver_parked'); _onCheckChanged(); },
          ),
          _CheckItem(
            key: _docsSubmittedKey,
            label: 'Documents submitted to security',
            value: _docsSubmitted,
            onChanged: (v) { setState(() => _docsSubmitted = v); _touchField('docs_submitted'); _onCheckChanged(); },
          ),
          _CheckItem(
            key: _securityVerifiedKey,
            label: 'Security verifies vehicle requirements',
            value: _securityVerified,
            onChanged: (v) { setState(() => _securityVerified = v); _touchField('security_verified'); _onCheckChanged(); },
          ),
          const SizedBox(height: 8),

          _SectionHeader(icon: Icons.security_rounded, title: 'Driver Safety Rules'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withValues(alpha: 0.30)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _CheckItem(
                  key: _driverExitedCabinKey,
                  label: 'Driver must exit cabin',
                  value: _driverExitedCabin,
                  onChanged: (v) { setState(() => _driverExitedCabin = v); _touchField('driver_exited_cabin'); _onCheckChanged(); },
                  activeColor: _primary,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: _primary.withValues(alpha: 0.15)),
                _CheckItem(
                  key: _wheelStoppersKey,
                  label: 'Wheel stoppers installed',
                  value: _wheelStoppers,
                  onChanged: (v) { setState(() => _wheelStoppers = v); _touchField('wheel_stoppers'); _onCheckChanged(); },
                  activeColor: _primary,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: _primary.withValues(alpha: 0.15)),
                _CheckItem(
                  key: _safetyGearKey,
                  label: 'Safety shoes and helmet required',
                  value: _safetyGear,
                  onChanged: (v) { setState(() => _safetyGear = v); _touchField('safety_gear'); _onCheckChanged(); },
                  activeColor: _primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionHeader(icon: Icons.schedule_rounded, title: 'Loading Timing'),
          _DateTimeField(
            fieldKey: _vehicleReachKey,
            label: 'Vehicle Reach Date And Time',
            value: _vehicleReachDatetime,
            showError: _showDatetimeErrors && _vehicleReachDatetime == null,
            onChanged: (dt) {
              setState(() => _vehicleReachDatetime = dt);
              _touchField('vehicle_reach_datetime');
              _saveDraft();
            },
          ),
          _DateTimeField(
            fieldKey: _loadingStartKey,
            label: 'Loading Start Date And Time',
            value: _loadingStartDatetime,
            showError: _showDatetimeErrors && _loadingStartDatetime == null,
            onChanged: (dt) {
              setState(() => _loadingStartDatetime = dt);
              _touchField('loading_start_datetime');
              _saveDraft();
            },
          ),
          const SizedBox(height: 8),

          // Dharma Kanta — Empty Weight (hidden when already captured in Stage 2)
          if (!weightFromS2) ...[
            _SectionHeader(icon: Icons.scale_rounded, title: 'Dharma Kanta (Weigh Bridge)'),
            _WeighField(
              controller: _emptyTruckWeight,
              label: 'Empty Truck Weight',
              hint: 'e.g. 12.5',
              note: 'Record the empty truck weight before loading.',
              enabled: !widget.readOnly,
              unitNotifier: _emptyWeightUnit,
            ),
            _FieldAttribution(username: _attrOf('empty_truck_weight')),
            const SizedBox(height: 20),
          ],

          // Loading Completed — one more checklist item, required (with the rest) to Complete Stage
          Container(
            decoration: BoxDecoration(
              color: _loadingComplete ? _success.withValues(alpha: 0.08) : _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _loadingComplete ? _success.withValues(alpha: 0.30) : _border),
            ),
            child: _CheckItem(
              label: 'Loading Completed',
              value: _loadingComplete,
              activeColor: _success,
              onChanged: widget.readOnly ? (_) {} : _onLoadingCompleteToggle,
            ),
          ),
          const SizedBox(height: 20),

          // Loaded weight + Bilty + Material Documents + Complete Stage
          _WeighField(
              controller: _loadedTruckWeight,
              label: 'Loaded Truck Weight',
              hint: 'e.g. 28.5',
              note: 'Record the truck weight after loading is done.',
              enabled: !widget.readOnly,
              unitNotifier: _loadedWeightUnit,
              existingSlipUrl: _weightSlipData == null ? widget.trip.s3LoadedWeightSlipUrl : null,
              initialSlipBytes: _weightSlipData?.bytes,
              onSlipPicked: (bytes, name) {
                setState(() => _weightSlipData = (bytes: bytes, name: name));
                _touchField('loaded_weight_slip');
                _saveDraft();
              },
              onSlipRemoved: () {
                setState(() => _weightSlipData = null);
                _touchField('loaded_weight_slip');
                _saveDraft();
              },
            ),
            _FieldAttribution(username: _attrOf('loaded_truck_weight')),
            _FieldAttribution(username: _attrOf('loaded_weight_slip')),
            const SizedBox(height: 20),

            // ── E-way Bill Upload ──────────────────────────────────────
            _SectionHeader(icon: Icons.receipt_long_rounded, title: 'E-way Bill'),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: TextFormField(
                controller: _ewayBillNumberCtrl,
                style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
                decoration: _stageFieldDec('E-way Bill Number'),
              ),
            ),
            _FieldAttribution(username: _attrOf('eway_bill_number')),
            const SizedBox(height: 8),
            _DateTimeField(
              label: 'E-way Bill Issue Date',
              value: _ewayBillIssueDate,
              // RR's documents.eway_bill.issue_date has is_restricted_future_date
              // — a future value gets rejected with a 422 at sync time.
              disallowFuture: true,
              onChanged: (dt) {
                setState(() => _ewayBillIssueDate = dt);
                _touchField('eway_bill_issue_date');
                _saveDraft();
              },
            ),
            _DateTimeField(
              label: 'E-way Bill Expiry Date',
              value: _ewayBillExpiryDate,
              onChanged: (dt) {
                setState(() => _ewayBillExpiryDate = dt);
                _touchField('eway_bill_expiry_date');
                _saveDraft();
              },
            ),
            const SizedBox(height: 8),
            _DocUploadTile(
              label: 'Upload E-way Bill',
              subtitle: 'Attach the e-way bill document',
              bytes: _ewayBillData?.bytes,
              fileName: _ewayBillData?.name,
              existingUrl: _ewayBillData == null ? widget.trip.s3EwayBillUrl : null,
              onPickSource: _pickEwayBill,
              onRemove: () { setState(() => _ewayBillData = null); _touchField('eway_bill_doc'); _saveDraft(); },
              readOnly: widget.readOnly,
            ),
            _FieldAttribution(username: _attrOf('eway_bill_doc')),
            const SizedBox(height: 20),

            // ── Invoice Upload ─────────────────────────────
            _SectionHeader(icon: Icons.folder_open_rounded, title: 'Invoice'),
            _DocUploadTile(
              label: 'Upload Invoice',
              subtitle: 'Attach the invoice document',
              bytes: _materialDocs?.bytes,
              fileName: _materialDocs?.name,
              existingUrl: _materialDocs == null
                  ? (widget.trip.s3MaterialDocUrls?.isNotEmpty == true
                      ? widget.trip.s3MaterialDocUrls!.first
                      : null)
                  : null,
              onPickSource: _pickMaterialDocs,
              onRemove: _removeMaterialDoc,
              readOnly: widget.readOnly,
            ),
            _FieldAttribution(username: _attrOf('material_docs')),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: TextFormField(
                controller: _invoiceNumberCtrl,
                style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
                decoration: _stageFieldDec('Enter Invoice Number'),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            _FieldAttribution(username: _attrOf('invoice_number')),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: TextFormField(
                controller: _actualInvoiceValueCtrl,
                style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
                decoration: _stageFieldDec('Enter Invoice Value (₹, max 10 digits)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                  // Column is Numeric(12,2) — cap at 10 integer digits + '.' + 2
                  // decimals so the value can never exceed what the DB accepts
                  // (confirmed live: an 11-digit value crashed the submit with
                  // a raw 500 before the field or backend rejected it).
                  LengthLimitingTextInputFormatter(13),
                ],
              ),
            ),
            _FieldAttribution(username: _attrOf('actual_invoice_value')),
            const SizedBox(height: 28),

            if (_lastSaved != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined, size: 14, color: _success),
                    const SizedBox(width: 4),
                    Text('Last saved: ${_formatSaved(_lastSaved!)}',
                        style: _inter(size: 11, color: _success)),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (busy || widget.readOnly) ? null : _completeStage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: busy
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Complete Stage ✓'),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Completion View ──────────────────────────────────────────────────────────

class _CompletionView extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onDone;
  final VoidCallback onNextStage;
  final String? emptyWeightKg;
  final String emptyWeightUnit;
  final String? loadedWeightKg;
  final String loadedWeightUnit;

  const _CompletionView({
    required this.trip,
    required this.onDone,
    required this.onNextStage,
    this.emptyWeightKg,
    this.emptyWeightUnit = 'kg',
    this.loadedWeightKg,
    this.loadedWeightUnit = 'kg',
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: _success, size: 56),
          ),
          const SizedBox(height: 24),
          Text('Truck Loading Complete!',
              style: _manrope(size: 22, weight: FontWeight.w800, color: _success)),
          const SizedBox(height: 8),
          Text(trip.tripNumber,
              style: _manrope(size: 16, weight: FontWeight.w700, color: _secondary)),
          const SizedBox(height: 6),
          Text(
            '${trip.origin} → ${trip.destination}',
            style: _inter(size: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Loading complete. Proceed to factory exit.',
            textAlign: TextAlign.center,
            style: _inter(size: 13, color: _secondary),
          ),
          const SizedBox(height: 32),

          // Next Stage — primary CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNextStage,
              icon: const Icon(Icons.exit_to_app_rounded, size: 18),
              label: const Text('Next Stage — Truck Exit →'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _StageTheme.rrWeb.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Track Truck
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TruckTrackingScreen(
                    trip: trip,
                    emptyWeightKg: emptyWeightKg,
                    emptyWeightUnit: emptyWeightUnit,
                    loadedWeightKg: loadedWeightKg,
                    loadedWeightUnit: loadedWeightUnit,
                  ),
                ),
              ),
              icon: const Icon(Icons.local_shipping_rounded, size: 16, color: _primary),
              label: Text('Track Truck', style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Back to Dashboard — secondary
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onDone,
              style: OutlinedButton.styleFrom(
                foregroundColor: _secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: _border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

/// Groups a document's front and back upload tiles under a labelled header.
class _DocPairSection extends StatelessWidget {
  final String title;
  final Widget frontTile;
  final Widget backTile;
  const _DocPairSection({required this.title, required this.frontTile, required this.backTile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _secondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          frontTile,
          backTile,
        ],
      ),
    );
  }
}

/// Tiny per-field attribution tag shown directly below each field/upload box.
/// Shows "@username" only when [username] is non-null.
class _FieldAttribution extends StatelessWidget {
  final String? username;
  const _FieldAttribution({this.username});

  @override
  Widget build(BuildContext context) {
    if (username == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 8, left: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline_rounded, size: 11, color: Color(0xFF006B5E)),
          const SizedBox(width: 3),
          Text(
            '@$username',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF006B5E),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a subtle "@username" attribution badge indicating who submitted this stage.
/// Only rendered when [username] is non-null.
class _StageAttribution extends StatelessWidget {
  final String? username;
  const _StageAttribution({this.username});

  @override
  Widget build(BuildContext context) {
    if (username == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _success.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline_rounded, size: 14, color: _success),
          const SizedBox(width: 6),
          Text(
            'Submitted by @$username',
            style: _inter(size: 12, weight: FontWeight.w600, color: _success),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 8),
          Text(title, style: _manrope(size: 14, weight: FontWeight.w800, color: _onSurface)),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final TextInputType keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    this.required = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _inter(size: 12, color: _secondary),
          filled: true,
          fillColor: _surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _error),
          ),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _CheckItem({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.sublabel,
    this.activeColor = _success,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: value ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? activeColor : _secondary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: _inter(
                          size: 13,
                          weight: value ? FontWeight.w600 : FontWeight.w400,
                          color: value ? _onSurface : _secondary)),
                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(sublabel!,
                        style: _inter(size: 11, color: _secondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Combined date+time picker field, styled to match the other stage form fields.
/// Tapping opens a date picker then a time picker and merges them into one DateTime.
class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool showError;
  final Key? fieldKey;
  // RR's unloading.{truck_reach_datetime,start_datetime,end_datetime} schema
  // has is_restricted_future_date — a future value gets rejected with a 422
  // at sync time. Set true for those fields so it can't be picked in the
  // first place. RR's loading.* fields have no such restriction.
  final bool disallowFuture;

  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.showError = false,
    this.fieldKey,
    this.disallowFuture = false,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: (value != null && (!disallowFuture || !value!.isAfter(now))) ? value! : now,
      firstDate: DateTime(now.year - 1),
      lastDate: disallowFuture ? now : DateTime(now.year + 1),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: value != null ? TimeOfDay.fromDateTime(value!) : TimeOfDay.now(),
    );
    if (time == null) return;
    var picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (disallowFuture && picked.isAfter(now)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$label can\'t be a future date/time — using current time instead',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
        ));
      }
      picked = now;
    }
    onChanged(picked);
  }

  String _format(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Container(
      key: fieldKey,
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _pick(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: _inter(size: 13, color: showError ? _error : _secondary),
            suffixIcon: Icon(Icons.calendar_today_rounded, size: 18,
                color: showError ? _error : _secondary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: showError ? _error : const Color(0xFFE0E0E0)),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            errorText: showError ? '$label is required' : null,
          ),
          child: Text(
            hasValue ? _format(value!) : 'Select date & time',
            style: _manrope(
              size: 14,
              weight: FontWeight.w600,
              color: hasValue ? _onSurface : const Color(0xFFAAAAAA),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeighField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String note;
  final bool enabled;
  final ValueNotifier<String>? unitNotifier;
  final void Function(Uint8List bytes, String name)? onSlipPicked;
  final VoidCallback? onSlipRemoved;
  final String? existingSlipUrl;
  final Uint8List? initialSlipBytes;

  const _WeighField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.note,
    this.enabled = true,
    this.unitNotifier,
    this.onSlipPicked,
    this.onSlipRemoved,
    this.existingSlipUrl,
    this.initialSlipBytes,
  });

  @override
  State<_WeighField> createState() => _WeighFieldState();
}

class _WeighFieldState extends State<_WeighField> {
  Uint8List? _slipBytes;
  bool _existingCleared = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _slipBytes = widget.initialSlipBytes;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _slipBytes = bytes;
          _existingCleared = false;
        });
        widget.onSlipPicked?.call(bytes, picked.name);
      }
    } catch (e) {
      if (!mounted) return;
      _showPickError(context, e, source);
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload Weigh Slip',
                  style: _manrope(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Choose how to add the slip image',
                  style: _inter(size: 12, color: _secondary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: _primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFF1565C0),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitNotifier = widget.unitNotifier;
    final existingSlipUrl = widget.existingSlipUrl;
    final fullSlipUrl = existingSlipUrl == null
        ? null
        : existingSlipUrl.startsWith('http')
            ? existingSlipUrl
            : '${AppConfig.apiBaseUrl}$existingSlipUrl';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.enabled ? _surface : _bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: widget.enabled ? _border : _border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row + unit toggle
          Row(
            children: [
              Expanded(
                child: Text(widget.note,
                    style: _inter(size: 12, color: _secondary)),
              ),
              if (unitNotifier != null)
                ValueListenableBuilder<String>(
                  valueListenable: unitNotifier,
                  builder: (_, unit, __) => _UnitToggle(
                    selected: unit,
                    enabled: widget.enabled,
                    onChanged: (u) => unitNotifier.value = u,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: unitNotifier ?? ValueNotifier('kg'),
            builder: (_, unit, __) => TextFormField(
              controller: widget.controller,
              enabled: widget.enabled,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: _inter(size: 12, color: _secondary),
                hintText: unit == 'tons' ? 'e.g. 12.5' : 'e.g. 12500',
                hintStyle: _inter(size: 12, color: _secondary),
                prefixIcon:
                    const Icon(Icons.scale_outlined, size: 18, color: _secondary),
                suffixText: unit,
                suffixStyle:
                    _inter(size: 13, weight: FontWeight.w600, color: _primary),
                filled: true,
                fillColor:
                    widget.enabled ? _bg : _border.withValues(alpha: 0.3),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: _border.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _primary, width: 1.5),
                ),
              ),
            ),
          ),
          // Slip upload area
          const SizedBox(height: 12),
          if (_slipBytes != null)
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showImagePreview(context, bytes: _slipBytes),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _slipBytes!,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  if (widget.enabled) ...[
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: _showPickerSheet,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _slipBytes = null);
                          widget.onSlipRemoved?.call();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _error.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 10),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(10)),
                      ),
                      child: Text('Weigh Slip',
                          style: _inter(
                              size: 11,
                              color: Colors.white,
                              weight: FontWeight.w600)),
                    ),
                  ),
                ],
              )
            else if (fullSlipUrl != null && !_existingCleared)
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showImagePreview(context, url: fullSlipUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        fullSlipUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: _border.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image_rounded,
                                color: _secondary, size: 32),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  if (widget.enabled) ...[
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: _showPickerSheet,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _existingCleared = true);
                          widget.onSlipRemoved?.call();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _error.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 10),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(10)),
                      ),
                      child: Text('Weigh Slip',
                          style: _inter(
                              size: 11,
                              color: Colors.white,
                              weight: FontWeight.w600)),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: widget.enabled ? _showPickerSheet : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? _primary.withValues(alpha: 0.05)
                        : _border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.enabled
                          ? _primary.withValues(alpha: 0.30)
                          : _border.withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.upload_file_rounded,
                          color: widget.enabled ? _primary : _secondary,
                          size: 24),
                      const SizedBox(height: 6),
                      Text(
                        'Upload Weigh Slip',
                        style: _inter(
                            size: 12,
                            weight: FontWeight.w600,
                            color: widget.enabled ? _primary : _secondary),
                      ),
                      const SizedBox(height: 2),
                      Text('Camera or Gallery',
                          style: _inter(size: 11, color: _secondary)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// ─── Source picker bottom sheet helper ───────────────────────────────────────

Future<ImageSource?> _showSourcePicker(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFECEEF0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: _primary, size: 20),
              ),
              title: Text('Take Photo',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600,
                      color: _onSurface)),
              subtitle: Text('Use camera',
                  style: GoogleFonts.inter(fontSize: 12, color: _secondary)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded, color: _primary, size: 20),
              ),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600,
                      color: _onSurface)),
              subtitle: Text('Browse photos',
                  style: GoogleFonts.inter(fontSize: 12, color: _secondary)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
  );
}

// ─── Full-screen image preview ────────────────────────────────────────────────

void _showImagePreview(BuildContext context, {Uint8List? bytes, String? url}) {
  final Widget image = bytes != null
      ? Image.memory(bytes, fit: BoxFit.contain)
      : Image.network(
          url!,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, prog) => prog == null
              ? child
              : const Center(child: CircularProgressIndicator(color: Colors.white)),
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48)),
        );

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: image,
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Single-file Document Upload Tile ────────────────────────────────────────

class _DocUploadTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final Uint8List? bytes;
  final String? fileName;
  /// Server URL of an already-uploaded file. Shown when [bytes] is null.
  final String? existingUrl;
  /// Pre-filled photo bytes pulled from RR (a driver/vehicle already hired
  /// before) — shown only when [bytes] and [existingUrl] are both null, i.e.
  /// nothing has been locally saved for this doc slot yet on this trip.
  final Uint8List? rrPreviewBytes;
  final Future<void> Function(ImageSource) onPickSource;
  final VoidCallback onRemove;
  /// When true, only the tap-to-preview affordance is active — no pick/retake/remove.
  final bool readOnly;

  const _DocUploadTile({
    required this.label,
    required this.subtitle,
    required this.bytes,
    this.fileName,
    this.existingUrl,
    this.rrPreviewBytes,
    required this.onPickSource,
    required this.onRemove,
    this.readOnly = false,
  });

  Future<void> _pick(BuildContext context) async {
    final source = await _showSourcePicker(context);
    if (source != null) await onPickSource(source);
  }

  @override
  Widget build(BuildContext context) {
    // Newly picked local file — show thumbnail preview
    if (bytes != null) {
      return Container(
        decoration: BoxDecoration(
          color: _success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _success.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showImagePreview(context, bytes: bytes),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    child: Image.memory(bytes!,
                        width: double.infinity, height: 160, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: _success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName ?? 'Image selected',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w500, color: _success),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!readOnly) ...[
                    GestureDetector(
                      onTap: () => _pick(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Retake',
                            style: GoogleFonts.manrope(
                                fontSize: 11, fontWeight: FontWeight.w700, color: _primary)),
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: _error),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // File saved on server (returning to edit) — show image thumbnail preview
    if (existingUrl != null) {
      final fullUrl = existingUrl!.startsWith('http')
          ? existingUrl!
          : '${AppConfig.apiBaseUrl}$existingUrl';
      return Container(
        decoration: BoxDecoration(
          color: _success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _success.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showImagePreview(context, url: fullUrl),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    child: Image.network(
                      fullUrl,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, prog) => prog == null
                          ? child
                          : const SizedBox(height: 160,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      errorBuilder: (_, __, ___) => const SizedBox(height: 80,
                          child: Center(child: Icon(Icons.broken_image_rounded, color: _secondary))),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, size: 16, color: _success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label,
                        style: GoogleFonts.manrope(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _success),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (!readOnly)
                    GestureDetector(
                      onTap: () => _pick(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('Replace',
                            style: GoogleFonts.manrope(
                                fontSize: 11, fontWeight: FontWeight.w700, color: _primary)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Pre-filled from RR (a previously-hired driver/vehicle already has this
    // doc on file) — nothing locally saved yet on this trip. Full preview,
    // same as a local/existing file, just sourced from RR's file-preview proxy.
    if (rrPreviewBytes != null) {
      return Container(
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primary.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showImagePreview(context, bytes: rrPreviewBytes),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    child: Image.memory(rrPreviewBytes!,
                        width: double.infinity, height: 160, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.cloud_download_rounded, size: 16, color: _primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Already on RR',
                        style: GoogleFonts.manrope(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _primary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (!readOnly)
                    GestureDetector(
                      onTap: () => _pick(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('Replace',
                            style: GoogleFonts.manrope(
                                fontSize: 11, fontWeight: FontWeight.w700, color: _primary)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: readOnly ? null : () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.upload_file_rounded,
                  color: _primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _secondary)),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline_rounded,
                color: _primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Unit Toggle (Tons / Kg) ──────────────────────────────────────────────────

class _UnitToggle extends StatelessWidget {
  final String selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _UnitToggle({
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: _border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['kg', 'tons'].map((unit) {
            final active = selected == unit;
            return GestureDetector(
              onTap: enabled ? () => onChanged(unit) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  unit,
                  style: _inter(
                    size: 12,
                    weight: FontWeight.w700,
                    color: active ? Colors.white : _secondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: _manrope(
                    size: 13, weight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Stage 4: Truck Exit From Factory ─────────────────────────────────────────

class _Stage4Form extends ConsumerStatefulWidget {
  final TripModel trip;
  final void Function(TripModel updated) onComplete;
  final bool readOnly;
  const _Stage4Form({super.key, required this.trip, required this.onComplete, this.readOnly = false});

  @override
  ConsumerState<_Stage4Form> createState() => _Stage4FormState();
}

class _Stage4FormState extends ConsumerState<_Stage4Form> {
  // ── Phase 1: Exit checklist ───────────────────────────────────────────────
  bool _truckMoved      = false;
  bool _securityCheck   = false;
  bool _biltyChecked    = false;
  bool _weightChecked   = false;
  bool _materialChecked = false;
  bool _checklistSubmitting = false;

  // RR loading.end_datetime
  DateTime? _vehicleExitDatetime;
  bool _showExitDatetimeError = false;

  // ── Phase 2: Diesel receipt ───────────────────────────────────────────────
  bool _showDiesel    = false;   // true after checklist submitted or if re-editing
  ({Uint8List bytes, String name})? _dieselFile;
  bool _dieselUploading = false;
  String? _dieselError;

  // ── Per-field attribution ─────────────────────────────────────────────────
  final Map<String, String> _fieldAttributions = {};
  final Set<String> _touchedByMe = {};
  void _touchField(String key) => _touchedByMe.add(key);
  String? _attrOf(String key) => _fieldAttributions[key];

  final _picker = ImagePicker();
  Timer? _debounce;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    // If checklist already submitted, go straight to diesel phase
    if (widget.trip.currentStage >= 4) _showDiesel = true;
    _prefillFromDraft();
  }

  void _prefillFromDraft() {
    final trip = widget.trip;

    // Always load persistent field attributions first
    trip.fieldAttributions?.forEach((k, v) {
      if (v is String) _fieldAttributions[k] = v;
    });

    final draft = trip.draftData;
    if (draft == null || draft['stage'] != 4) {
      // No draft — prefill from committed trip data when re-editing
      if (trip.currentStage >= 4) {
        _truckMoved      = trip.s4TruckMoved       ?? false;
        _securityCheck   = trip.s4SecurityVerified  ?? false;
        _biltyChecked    = trip.s4BiltyChecked      ?? false;
        _weightChecked   = trip.s4WeightChecked     ?? false;
        _materialChecked = trip.s4MaterialChecked   ?? false;
        if (trip.s4VehicleExitDatetime != null) {
          _vehicleExitDatetime = DateTime.tryParse(trip.s4VehicleExitDatetime!);
        }
      }
      return;
    }
    final d = draft['data'] as Map<String, dynamic>? ?? {};
    // Checkboxes aren't drafted — restored as unchecked, user re-confirms them.
    // Restore diesel bytes if saved in draft
    final b64  = d['diesel_bytes'] as String?;
    final name = d['diesel_name']  as String? ?? 'diesel_receipt.jpg';
    if (b64 != null && b64.isNotEmpty) {
      try { _dieselFile = (bytes: base64Decode(b64), name: name); } catch (_) {}
    }
    final exitDtStr = d['vehicle_exit_datetime'] as String?;
    if (exitDtStr != null) _vehicleExitDatetime = DateTime.tryParse(exitDtStr);
    // Draft attributions override persistent ones
    final attrs = draft['attributions'] as Map<String, dynamic>?;
    if (attrs != null) {
      attrs.forEach((k, v) { if (v is String) _fieldAttributions[k] = v; });
    }
    if (draft['saved_at'] != null) {
      _lastSaved = DateTime.tryParse(draft['saved_at'] as String);
    }
  }

  void _onCheckChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  Future<void> _saveDraft({bool duringDispose = false}) async {
    if (!duringDispose && !mounted) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/draft', data: {
        'stage': 4,
        'data': {
          // Checkboxes intentionally not drafted — checklist submission is a
          // real network call, not a local phase gate, so on restore the user
          // just re-confirms them before submitting (no data-loss risk).
          if (_dieselFile != null) 'diesel_bytes': base64Encode(_dieselFile!.bytes),
          if (_dieselFile != null) 'diesel_name':  _dieselFile!.name,
          if (_vehicleExitDatetime != null)
            'vehicle_exit_datetime': _vehicleExitDatetime!.toIso8601String(),
        },
        if (_touchedByMe.isNotEmpty)
          'attributions': {for (final k in _touchedByMe) k: true},
      });
      if (!duringDispose && mounted) setState(() => _lastSaved = DateTime.now());
    } on DioException catch (e) {
      if (!duringDispose && mounted) _showDraftSaveError(context, e);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      unawaited(_saveDraft(duringDispose: true));
    } else {
      _debounce?.cancel();
    }
    super.dispose();
  }

  bool get _allChecklistDone =>
      _truckMoved && _securityCheck && _biltyChecked && _weightChecked && _materialChecked &&
      _vehicleExitDatetime != null;

  // ── Phase 1 submit: checklist only ────────────────────────────────────────
  Future<void> _submitChecklist() async {
    if (!_allChecklistDone) {
      setState(() => _showExitDatetimeError = true);
      return;
    }
    if (_checklistSubmitting) return;
    setState(() => _checklistSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/trips/${widget.trip.id}/stage/4', data: {
        'truck_moved':        _truckMoved,
        'security_verified':  _securityCheck,
        'bilty_checked':      _biltyChecked,
        'weight_checked':     _weightChecked,
        'material_checked':   _materialChecked,
        'vehicle_exit_datetime': _vehicleExitDatetime!.toIso8601String(),
      });
      if (mounted) setState(() { _checklistSubmitting = false; _showDiesel = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _checklistSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e', style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  // ── Phase 2: diesel receipt pick + upload ────────────────────────────────
  Future<void> _pickDiesel(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      setState(() { _dieselFile = (bytes: bytes, name: picked.name); _dieselError = null; });
      _touchField('diesel_receipt');
      _saveDraft();
    } catch (e) {
      if (!mounted) return;
      setState(() => _dieselError = _pickErrorMessage(e, source));
    }
  }

  void _showDieselPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload Diesel Receipt', style: _manrope(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Choose how to add the receipt image',
                  style: _inter(size: 12, color: _secondary)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _PickerOption(
                  icon: Icons.camera_alt_rounded, label: 'Camera', color: _primary,
                  onTap: () { Navigator.pop(context); _pickDiesel(ImageSource.camera); },
                )),
                const SizedBox(width: 12),
                Expanded(child: _PickerOption(
                  icon: Icons.photo_library_rounded, label: 'Gallery', color: _secondary,
                  onTap: () { Navigator.pop(context); _pickDiesel(ImageSource.gallery); },
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadDiesel() async {
    if (_dieselFile == null || _dieselUploading) return;
    setState(() { _dieselUploading = true; _dieselError = null; });
    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'receipt': MultipartFile.fromBytes(_dieselFile!.bytes, filename: _dieselFile!.name),
      });
      final resp = await dio.post(
        '/api/trips/${widget.trip.id}/stage/4/diesel',
        data: formData,
      );
      final updated = TripModel.fromJson(
        (resp.data as Map<String, dynamic>)['trip'] as Map<String, dynamic>,
      );
      if (mounted) widget.onComplete(updated);
    } catch (e) {
      final msg = e is DioException
          ? _dioErrorDetail(e, 'Upload failed')
          : e.toString();
      if (mounted) setState(() { _dieselUploading = false; _dieselError = msg; });
    }
  }

  Widget _buildCheckTile({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? _success.withValues(alpha: 0.06) : _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? _success.withValues(alpha: 0.35) : _border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? _success : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? _success : _secondary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: _manrope(
                  size: 14,
                  weight: FontWeight.w600,
                  color: value ? _success : _onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingDieselUrl = widget.trip.s4DieselReceiptUrl;
    final showExistingDiesel = existingDieselUrl != null && _dieselFile == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageAttribution(username: widget.trip.s4SubmittedByUsername),

          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _showDiesel
                  ? _success.withValues(alpha: 0.06)
                  : _primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _showDiesel
                    ? _success.withValues(alpha: 0.2)
                    : _primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (_showDiesel ? _success : _primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _showDiesel
                        ? Icons.local_gas_station_rounded
                        : Icons.exit_to_app_rounded,
                    color: _showDiesel ? _success : _primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _showDiesel ? 'Upload Diesel Receipt' : 'Truck Exit From Factory',
                        style: _manrope(size: 15, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _showDiesel
                            ? 'Upload the diesel receipt to complete Stage 4'
                            : 'Verify all exit procedures before releasing truck',
                        style: _inter(size: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!_showDiesel) ...[ // ── Phase 1: Checklist ──────────────────────
            _SectionHeader(icon: Icons.directions_car_outlined, title: 'Exit Procedure'),
            const SizedBox(height: 8),
            _buildCheckTile(
              value: _truckMoved,
              label: 'Truck moves to factory exit gate',
              onChanged: (v) { setState(() => _truckMoved = v ?? false); _touchField('truck_moved'); _onCheckChanged(); },
            ),
            _buildCheckTile(
              value: _securityCheck,
              label: 'Security verifies documents',
              onChanged: (v) { setState(() => _securityCheck = v ?? false); _touchField('security_check'); _onCheckChanged(); },
            ),
            const SizedBox(height: 16),

            _SectionHeader(icon: Icons.description_outlined, title: 'Documents Checked'),
            const SizedBox(height: 8),
            _buildCheckTile(
              value: _biltyChecked,
              label: 'E-way Bill',
              onChanged: (v) { setState(() => _biltyChecked = v ?? false); _touchField('bilty_checked'); _onCheckChanged(); },
            ),
            _buildCheckTile(
              value: _weightChecked,
              label: 'Loaded Weight Slip',
              onChanged: (v) { setState(() => _weightChecked = v ?? false); _touchField('weight_checked'); _onCheckChanged(); },
            ),
            _buildCheckTile(
              value: _materialChecked,
              label: 'Material Documents',
              onChanged: (v) { setState(() => _materialChecked = v ?? false); _touchField('material_checked'); _onCheckChanged(); },
            ),
            const SizedBox(height: 16),

            _SectionHeader(icon: Icons.schedule_rounded, title: 'Exit Timing'),
            const SizedBox(height: 8),
            _DateTimeField(
              label: 'Vehicle Exit Date And Time',
              value: _vehicleExitDatetime,
              showError: _showExitDatetimeError && _vehicleExitDatetime == null,
              onChanged: (dt) {
                setState(() => _vehicleExitDatetime = dt);
                _touchField('vehicle_exit_datetime');
                _saveDraft();
              },
            ),
            const SizedBox(height: 8),

            if (!_allChecklistDone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please confirm all items above before proceeding',
                        style: _inter(size: 12, color: const Color(0xFFE65100)),
                      ),
                    ),
                  ],
                ),
              ),
            if (!_allChecklistDone) const SizedBox(height: 12),
            if (_lastSaved != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined, size: 14, color: _success),
                    const SizedBox(width: 4),
                    Text('Last saved: ${_formatSaved(_lastSaved!)}',
                        style: _inter(size: 11, color: _success)),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_allChecklistDone && !_checklistSubmitting && !widget.readOnly) ? _submitChecklist : null,
                icon: _checklistSubmitting
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.logout_rounded, size: 18),
                label: Text(_checklistSubmitting ? 'Saving…' : 'Truck Exits Factory'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _StageTheme.rrWeb.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _border,
                  disabledForegroundColor: _secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else ...[ // ── Phase 2: Diesel Receipt ───────────────────────────

            // Checklist done banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _success.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: _success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Exit checklist complete. Now upload diesel receipt.',
                        style: _inter(size: 12, color: _success, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _SectionHeader(icon: Icons.local_gas_station_rounded, title: 'Diesel Receipt'),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _dieselFile != null
                      ? _success.withValues(alpha: 0.50)
                      : showExistingDiesel
                          ? _success.withValues(alpha: 0.30)
                          : _border,
                  width: (_dieselFile != null || showExistingDiesel) ? 1.5 : 1,
                ),
              ),
              child: _dieselFile != null
                  ? Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showImagePreview(context, bytes: _dieselFile!.bytes),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.memory(_dieselFile!.bytes,
                                height: 200, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ),
                        if (!widget.readOnly)
                          Positioned(
                            top: 8, right: 8,
                            child: GestureDetector(
                              onTap: () { setState(() => _dieselFile = null); _saveDraft(); },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Icon(Icons.close_rounded, size: 16, color: _error),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: _success, borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text('Ready to Upload',
                                  style: _inter(size: 11, color: Colors.white, weight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ],
                    )
                  : showExistingDiesel
                      ? Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _showImagePreview(context, url: '${AppConfig.apiBaseUrl}$existingDieselUrl'),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.network(
                                  '${AppConfig.apiBaseUrl}$existingDieselUrl',
                                  height: 200, width: double.infinity, fit: BoxFit.cover,
                                  loadingBuilder: (_, child, prog) => prog == null
                                      ? child
                                      : const SizedBox(height: 200,
                                          child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                  errorBuilder: (_, __, ___) => const SizedBox(height: 120,
                                      child: Center(child: Icon(Icons.broken_image_rounded))),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8, left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: _success, borderRadius: BorderRadius.circular(20)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Uploaded', style: _inter(size: 11, color: Colors.white, weight: FontWeight.w600)),
                                ]),
                              ),
                            ),
                            if (!widget.readOnly)
                              Positioned(
                                bottom: 8, right: 8,
                                child: GestureDetector(
                                  onTap: _showDieselPicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 12),
                                      const SizedBox(width: 4),
                                      Text('Tap to replace', style: _inter(size: 11, color: Colors.white)),
                                    ]),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : GestureDetector(
                          onTap: widget.readOnly ? null : _showDieselPicker,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Column(
                              children: [
                                Icon(Icons.add_photo_alternate_rounded,
                                    size: 40, color: _secondary.withValues(alpha: 0.5)),
                                const SizedBox(height: 10),
                                Text('Tap to upload diesel receipt',
                                    style: _inter(size: 13, weight: FontWeight.w600, color: _secondary)),
                                const SizedBox(height: 4),
                                Text('Camera or Gallery',
                                    style: _inter(size: 11, color: _secondary.withValues(alpha: 0.7))),
                              ],
                            ),
                          ),
                        ),
            ),
            _FieldAttribution(username: _attrOf('diesel_receipt')),

            if (_dieselError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: _error, size: 15),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_dieselError!, style: _inter(size: 12, color: _error))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            if (_lastSaved != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  const Icon(Icons.cloud_done_outlined, size: 14, color: _success),
                  const SizedBox(width: 4),
                  Text('Last saved: ${_formatSaved(_lastSaved!)}',
                      style: _inter(size: 11, color: _success)),
                ]),
              ),

            if (_dieselFile != null || !showExistingDiesel)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_dieselFile != null && !_dieselUploading && !widget.readOnly) ? _uploadDiesel : null,
                  icon: _dieselUploading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_rounded, size: 20),
                  label: Text(_dieselUploading ? 'Uploading…' : 'Submit Diesel Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _StageTheme.rrWeb.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFDDE0E2),
                    disabledForegroundColor: _secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Stage 5: Unloading (POD + Halting Charge) ────────────────────────────────

class _Stage5Form extends ConsumerStatefulWidget {
  final TripModel trip;
  final void Function(TripModel updated) onComplete;
  final bool readOnly;
  const _Stage5Form({super.key, required this.trip, required this.onComplete, this.readOnly = false});

  @override
  ConsumerState<_Stage5Form> createState() => _Stage5FormState();
}

class _Stage5FormState extends ConsumerState<_Stage5Form> {
  ({Uint8List bytes, String name})? _podFile;
  final _haltingChargeCtrl = TextEditingController();
  bool _uploading = false;
  String? _errorMsg;
  DateTime? _lastSaved;

  // RR unloading.{truck_reach_datetime,start_datetime,end_datetime}
  DateTime? _vehicleReachDatetime;
  DateTime? _unloadingStartDatetime;
  DateTime? _unloadingEndDatetime;
  bool _showDatetimeErrors = false;

  // ── Per-field attribution ─────────────────────────────────────────────────
  final Map<String, String> _fieldAttributions = {};
  final Set<String> _touchedByMe = {};
  void _touchField(String key) => _touchedByMe.add(key);
  String? _attrOf(String key) => _fieldAttributions[key];

  final _picker = ImagePicker();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _haltingChargeCtrl.addListener(() {
      _touchField('halting_charge');
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 1200), _saveDraft);
    });
    _prefillFromDraft();
  }

  @override
  void dispose() {
    _haltingChargeCtrl.dispose();
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      unawaited(_saveDraft(duringDispose: true));
    } else {
      _debounce?.cancel();
    }
    super.dispose();
  }

  void _prefillFromDraft() {
    final trip = widget.trip;

    // Always load persistent field attributions first
    trip.fieldAttributions?.forEach((k, v) {
      if (v is String) _fieldAttributions[k] = v;
    });

    final draft = trip.draftData;
    if (draft == null || draft['stage'] != 5) {
      if (trip.currentStage >= 5) {
        if (trip.s5HaltingCharge != null) {
          final hc = trip.s5HaltingCharge!;
          _haltingChargeCtrl.text =
              hc % 1 == 0 ? hc.toInt().toString() : hc.toStringAsFixed(2);
        }
        if (trip.s5VehicleReachDatetime != null) {
          _vehicleReachDatetime = DateTime.tryParse(trip.s5VehicleReachDatetime!);
        }
        if (trip.s5UnloadingStartDatetime != null) {
          _unloadingStartDatetime = DateTime.tryParse(trip.s5UnloadingStartDatetime!);
        }
        if (trip.s5UnloadingEndDatetime != null) {
          _unloadingEndDatetime = DateTime.tryParse(trip.s5UnloadingEndDatetime!);
        }
      }
      return;
    }
    final data = draft['data'] as Map<String, dynamic>? ?? {};
    final b64  = data['pod_bytes'] as String?;
    final name = data['pod_name']  as String? ?? 'pod.jpg';
    if (b64 != null && b64.isNotEmpty) {
      try { _podFile = (bytes: base64Decode(b64), name: name); } catch (_) {}
    }
    _haltingChargeCtrl.text = data['halting_charge'] as String? ?? '';
    final vehicleReachStr = data['vehicle_reach_datetime'] as String?;
    if (vehicleReachStr != null) _vehicleReachDatetime = DateTime.tryParse(vehicleReachStr);
    final unloadStartStr = data['unloading_start_datetime'] as String?;
    if (unloadStartStr != null) _unloadingStartDatetime = DateTime.tryParse(unloadStartStr);
    final unloadEndStr = data['unloading_end_datetime'] as String?;
    if (unloadEndStr != null) _unloadingEndDatetime = DateTime.tryParse(unloadEndStr);
    // Draft attributions override persistent ones
    final attrs = draft['attributions'] as Map<String, dynamic>?;
    if (attrs != null) {
      attrs.forEach((k, v) { if (v is String) _fieldAttributions[k] = v; });
    }
    if (draft['saved_at'] != null) {
      _lastSaved = DateTime.tryParse(draft['saved_at'] as String);
    }
  }

  Future<void> _saveDraft({bool duringDispose = false}) async {
    if (!duringDispose && !mounted) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/draft', data: {
        'stage': 5,
        'data': {
          if (_podFile != null) 'pod_bytes': base64Encode(_podFile!.bytes),
          if (_podFile != null) 'pod_name':  _podFile!.name,
          if (_haltingChargeCtrl.text.isNotEmpty) 'halting_charge': _haltingChargeCtrl.text,
          if (_vehicleReachDatetime != null)
            'vehicle_reach_datetime': _vehicleReachDatetime!.toIso8601String(),
          if (_unloadingStartDatetime != null)
            'unloading_start_datetime': _unloadingStartDatetime!.toIso8601String(),
          if (_unloadingEndDatetime != null)
            'unloading_end_datetime': _unloadingEndDatetime!.toIso8601String(),
        },
        if (_touchedByMe.isNotEmpty)
          'attributions': {for (final k in _touchedByMe) k: true},
      });
      if (!duringDispose && mounted) setState(() => _lastSaved = DateTime.now());
    } on DioException catch (e) {
      if (!duringDispose && mounted) _showDraftSaveError(context, e);
    } catch (_) {}
  }

  Future<void> _pickPod(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      setState(() { _podFile = (bytes: bytes, name: picked.name); _errorMsg = null; });
      _touchField('pod_doc');
      _saveDraft();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = _pickErrorMessage(e, source));
    }
  }

  void _showPodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload Proof of Delivery',
                  style: _manrope(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Choose how to add the POD document',
                  style: _inter(size: 12, color: _secondary)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _PickerOption(
                  icon: Icons.camera_alt_rounded, label: 'Camera', color: _primary,
                  onTap: () { Navigator.pop(context); _pickPod(ImageSource.camera); },
                )),
                const SizedBox(width: 12),
                Expanded(child: _PickerOption(
                  icon: Icons.photo_library_rounded, label: 'Gallery', color: _secondary,
                  onTap: () { Navigator.pop(context); _pickPod(ImageSource.gallery); },
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_podFile == null && widget.trip.s5PodUrl == null) {
      setState(() => _errorMsg = 'Please upload the Proof of Delivery document');
      return;
    }
    if (_vehicleReachDatetime == null || _unloadingStartDatetime == null || _unloadingEndDatetime == null) {
      setState(() => _showDatetimeErrors = true);
      return;
    }
    setState(() { _uploading = true; _errorMsg = null; });
    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        if (_podFile != null)
          'pod': MultipartFile.fromBytes(_podFile!.bytes, filename: _podFile!.name),
        if (_haltingChargeCtrl.text.trim().isNotEmpty)
          'halting_charge': _haltingChargeCtrl.text.trim(),
        'vehicle_reach_datetime':   _vehicleReachDatetime!.toIso8601String(),
        'unloading_start_datetime': _unloadingStartDatetime!.toIso8601String(),
        'unloading_end_datetime':   _unloadingEndDatetime!.toIso8601String(),
      });
      final resp = await dio.post(
          '/api/trips/${widget.trip.id}/stage/5', data: formData);
      final updated = TripModel.fromJson(
          (resp.data as Map<String, dynamic>)['trip'] as Map<String, dynamic>);
      if (mounted) widget.onComplete(updated);
    } catch (e) {
      final msg = e is DioException
          ? _dioErrorDetail(e, 'Upload failed')
          : e.toString();
      if (mounted) setState(() { _uploading = false; _errorMsg = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingPodUrl = widget.trip.s5PodUrl;
    final showExisting   = existingPodUrl != null && _podFile == null;
    final podImageUrl    = existingPodUrl != null
        ? '${AppConfig.apiBaseUrl}$existingPodUrl'
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageAttribution(
            username: widget.trip.currentStage >= 5
                ? widget.trip.s5SubmittedByUsername
                : null,
          ),
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: showExisting
                  ? _success.withValues(alpha: 0.07)
                  : _primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: showExisting
                    ? _success.withValues(alpha: 0.25)
                    : _primary.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (showExisting ? _success : _primary).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    showExisting
                        ? Icons.check_circle_rounded
                        : Icons.inventory_2_rounded,
                    color: showExisting ? _success : _primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showExisting ? 'Unloading Stage Complete' : 'Unloading Stage',
                        style: _manrope(size: 15, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        showExisting
                            ? 'POD uploaded. Tap to replace if needed.'
                            : 'Upload POD and enter halting charge if applicable.',
                        style: _inter(size: 12, color: _secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── POD Upload ────────────────────────────────────────────────────
          _SectionHeader(icon: Icons.receipt_long_rounded, title: 'Proof of Delivery (POD)'),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _podFile != null
                    ? _success.withValues(alpha: 0.50)
                    : showExisting
                        ? _success.withValues(alpha: 0.30)
                        : _border,
                width: (_podFile != null || showExisting) ? 1.5 : 1,
              ),
            ),
            child: _podFile != null
                ? Stack(children: [
                    GestureDetector(
                      onTap: () => _showImagePreview(context, bytes: _podFile!.bytes),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.memory(_podFile!.bytes,
                            height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ),
                    if (!widget.readOnly)
                      Positioned(
                        top: 8, right: 8,
                        child: GestureDetector(
                          onTap: () { setState(() => _podFile = null); _saveDraft(); },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child: Icon(Icons.close_rounded, size: 16, color: _error),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: _success, borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text('Ready to Upload',
                              style: _inter(size: 11, color: Colors.white,
                                  weight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ])
                : showExisting
                    ? Stack(children: [
                        GestureDetector(
                          onTap: () => _showImagePreview(context, url: podImageUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.network(
                              podImageUrl!,
                              height: 220, width: double.infinity, fit: BoxFit.cover,
                              loadingBuilder: (_, child, prog) => prog == null
                                  ? child
                                  : const SizedBox(height: 220,
                                      child: Center(
                                          child: CircularProgressIndicator(strokeWidth: 2))),
                              errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 120,
                                  child: Center(
                                      child: Icon(Icons.broken_image_rounded))),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8, left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: _success,
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text('POD Uploaded',
                                  style: _inter(size: 11, color: Colors.white,
                                      weight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                        if (!widget.readOnly)
                          Positioned(
                            bottom: 8, right: 8,
                            child: GestureDetector(
                              onTap: _showPodPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.swap_horiz_rounded,
                                      color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Tap to replace',
                                      style: _inter(size: 11, color: Colors.white)),
                                ]),
                              ),
                            ),
                          ),
                      ])
                    : GestureDetector(
                        onTap: widget.readOnly ? null : _showPodPicker,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Column(children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 40, color: _secondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 10),
                            Text('Tap to upload POD document',
                                style: _inter(size: 13, weight: FontWeight.w600,
                                    color: _secondary)),
                            const SizedBox(height: 4),
                            Text('Camera or Gallery',
                                style: _inter(
                                    size: 11,
                                    color: _secondary.withValues(alpha: 0.7))),
                          ]),
                        ),
                      ),
          ),
          _FieldAttribution(username: _attrOf('pod_doc')),
          const SizedBox(height: 24),

          // ── Unloading Timing ────────────────────────────────────────────────
          _SectionHeader(icon: Icons.schedule_rounded, title: 'Unloading Timing'),
          const SizedBox(height: 8),
          _DateTimeField(
            label: 'Vehicle Reach Date And Time',
            value: _vehicleReachDatetime,
            showError: _showDatetimeErrors && _vehicleReachDatetime == null,
            disallowFuture: true,
            onChanged: (dt) {
              setState(() => _vehicleReachDatetime = dt);
              _touchField('vehicle_reach_datetime');
              _saveDraft();
            },
          ),
          _DateTimeField(
            label: 'Unloading Start Date And Time',
            value: _unloadingStartDatetime,
            showError: _showDatetimeErrors && _unloadingStartDatetime == null,
            disallowFuture: true,
            onChanged: (dt) {
              setState(() => _unloadingStartDatetime = dt);
              _touchField('unloading_start_datetime');
              _saveDraft();
            },
          ),
          _DateTimeField(
            label: 'Unloading End Date And Time',
            value: _unloadingEndDatetime,
            showError: _showDatetimeErrors && _unloadingEndDatetime == null,
            disallowFuture: true,
            onChanged: (dt) {
              setState(() => _unloadingEndDatetime = dt);
              _touchField('unloading_end_datetime');
              _saveDraft();
            },
          ),
          const SizedBox(height: 8),

          // ── Halting Charge ────────────────────────────────────────────────
          _SectionHeader(
              icon: Icons.currency_rupee_rounded,
              title: 'Halting Charge (Optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _haltingChargeCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter amount in \u20b9 (e.g. 500)',
              hintStyle:
                  _inter(size: 13, color: _secondary.withValues(alpha: 0.6)),
              prefixIcon: const Icon(Icons.currency_rupee_rounded,
                  size: 18, color: _secondary),
              filled: true,
              fillColor: _surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
            ),
          ),
          _FieldAttribution(username: _attrOf('halting_charge')),
          const SizedBox(height: 24),

          if (_errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.error_outline_rounded, color: _error, size: 15),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_errorMsg!,
                        style: _inter(size: 12, color: _error))),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          if (_lastSaved != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                const Icon(Icons.cloud_done_outlined, size: 14, color: _success),
                const SizedBox(width: 4),
                Text('Last saved: ${_formatSaved(_lastSaved!)}',
                    style: _inter(size: 11, color: _success)),
              ]),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (!_uploading && !widget.readOnly) ? _submit : null,
              icon: _uploading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(_uploading ? 'Submitting\u2026' : 'Complete Unloading Stage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _StageTheme.rrWeb.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFDDE0E2),
                disabledForegroundColor: _secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.manrope(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stage 4 Complete View ────────────────────────────────────────────────────

class _Stage4CompleteView extends ConsumerStatefulWidget {
  final TripModel trip;
  final VoidCallback onDone;
  final bool readOnly;
  const _Stage4CompleteView({required this.trip, required this.onDone, this.readOnly = false});

  @override
  ConsumerState<_Stage4CompleteView> createState() => _Stage4CompleteViewState();
}

class _Stage4CompleteViewState extends ConsumerState<_Stage4CompleteView> {
  bool _notifying   = false;
  bool _notified    = false;
  bool _notifyingLP = false;
  bool _notifiedLP  = false;

  bool _syncingToRr = false;
  String? _rrSyncPromptError;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool get _canManageRr {
    final user = ref.read(authProvider).user;
    return user?.roleKey == 'logistic_partner' || user?.isLpRrOperations == true;
  }

  bool get _alreadySyncedToRr => widget.trip.rrSyncStatus == 'pod_synced';

  @override
  void initState() {
    super.initState();
    // Stages are no longer auto-synced as they're submitted — this is the
    // single sync trigger point, so proactively prompt LP/RR-ops the moment
    // all 5 stages are done, instead of relying on the easy-to-miss AppBar icon.
    if (widget.trip.rrTripId != null && !_alreadySyncedToRr && _canManageRr && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSyncPrompt();
      });
    }
  }

  @override
  void didUpdateWidget(_Stage4CompleteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only react to a live transition into pod_synced (e.g. a background
    // auto-sync completing while this screen is open) — never on first build,
    // so reopening an already-synced/Records trip never auto-closes on you.
    if (oldWidget.trip.rrSyncStatus != 'pod_synced' && widget.trip.rrSyncStatus == 'pod_synced') {
      _autoCloseOnSync();
    }
  }

  void _autoCloseOnSync() {
    if (_notifying || _notifyingLP) return;
    // didUpdateWidget runs during the build phase — showSnackBar() and any
    // other ScaffoldMessenger mutation must be deferred to after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Trip synced', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && !_disposed) widget.onDone();
      });
    });
  }

  // sync/retry only queues a BackgroundTask — the response returns before the
  // sync actually runs. Poll a few times (rather than waiting up to 30s for
  // the dashboard's ambient timer) so a manual "Sync Now" tap gets a timely
  // close once genuinely synced. Fetching feeds tripProvider → this screen's
  // ref.listen/didUpdateWidget, which does the actual close — nothing here
  // assumes success itself.
  Future<void> _pollForSyncCompletion() async {
    for (var i = 0; i < 6 && mounted && !_disposed; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || _disposed) return;
      try {
        await ref.read(tripProvider.notifier).fetchSingleTrip(widget.trip.id);
      } catch (_) {
        // Widget may have been deactivated (e.g. popped by _autoCloseOnSync)
        // between the mounted check above and this call — mounted alone
        // doesn't guard against that race, so just stop polling.
        return;
      }
    }
  }

  Future<void> _showSyncPrompt() async {
    final doSync = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('All stages complete', style: _manrope(size: 16, weight: FontWeight.w800)),
        content: Text(
          'This trip is fully completed. Sync all uploads and data to RR web now?',
          style: _inter(size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Later', style: _manrope(size: 13, weight: FontWeight.w700, color: _secondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _StageTheme.rrWeb.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Sync Now', style: _manrope(size: 13, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (doSync == true) await _syncToRr();
  }

  Future<void> _syncToRr() async {
    if (_syncingToRr) return;
    final session = await ensureRrSession(context, ref);
    if (session == null || !mounted) return;

    setState(() { _syncingToRr = true; _rrSyncPromptError = null; });
    try {
      final dio = ref.read(dioProvider);
      // sync/retry only queues a BackgroundTask and returns immediately — the
      // actual sync (and rrSyncStatus flipping to pod_synced) happens after
      // this response, so don't treat a 200 here as "done". Poll a few times
      // for the real completion signal, which feeds the same ref.listen/
      // didUpdateWidget path that closes the screen once it's genuinely synced.
      await dio.post('/api/rr/sync/retry/${widget.trip.id}', data: {});
      if (!mounted) return;
      setState(() { _syncingToRr = false; });
      unawaited(_pollForSyncCompletion());
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? _dioErrorDetail(e, 'Sync failed')
          : e.toString();
      setState(() { _syncingToRr = false; _rrSyncPromptError = msg; });
    }
  }

  Future<void> _notify() async {
    if (_notifying || _notified) return;
    setState(() => _notifying = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/trips/${widget.trip.id}/notify-stage4');
      if (mounted) {
        setState(() { _notified = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Load owner notified successfully!',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Notification failed: $e',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _notifying = false);
    }
  }

  Future<void> _notifyLP() async {
    if (_notifyingLP || _notifiedLP) return;
    setState(() => _notifyingLP = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/trips/${widget.trip.id}/notify-lp');
      if (mounted) {
        setState(() { _notifiedLP = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('LP team notified successfully!',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Notification failed: $e',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _notifyingLP = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_rounded, color: _primary, size: 56),
          ),
          const SizedBox(height: 24),
          Text('All Stages Completed!',
              style: _manrope(size: 22, weight: FontWeight.w800, color: _primary),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(trip.tripNumber,
              style: _manrope(size: 16, weight: FontWeight.w700, color: _secondary)),
          const SizedBox(height: 6),
          Text(
            '${trip.origin} → ${trip.destination}',
            style: _inter(size: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: (_alreadySyncedToRr ? _primary : _success).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (_alreadySyncedToRr ? _primary : _success).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _alreadySyncedToRr ? _primary : _success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(
                  _alreadySyncedToRr ? 'Synced to RR web' : 'All Stages Done',
                  style: _manrope(size: 13, weight: FontWeight.w700,
                      color: _alreadySyncedToRr ? _primary : _success),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'All stages completed including unloading.',
            textAlign: TextAlign.center,
            style: _inter(size: 13, color: _secondary),
          ),
          const SizedBox(height: 20),

          // Summary info row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Load', value: trip.loadItem),
                if (trip.weight != null) ...[
                  const Divider(height: 16, color: _border),
                  _SummaryRow(label: 'Weight', value: trip.weight!),
                ],
                if (trip.vehiclePlate != null) ...[
                  const Divider(height: 16, color: _border),
                  _SummaryRow(label: 'Vehicle', value: trip.vehiclePlate!),
                ],
                if (trip.driverName != null) ...[
                  const Divider(height: 16, color: _border),
                  _SummaryRow(label: 'Driver', value: trip.driverName!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Notify Load Owner button ──
          if (trip.loadOwnerOrgId != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_notifying || _notified || widget.readOnly) ? null : _notify,
                icon: _notifying
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_notified ? Icons.check_circle_rounded : Icons.notifications_rounded,
                        size: 18),
                label: Text(_notified
                    ? '${widget.trip.loadOwnerOrgName ?? 'Load Owner'} Notified'
                    : _notifying
                        ? 'Sending…'
                        : 'Notify ${widget.trip.loadOwnerOrgName ?? 'Load Owner'}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _notified ? _success : _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _success.withValues(alpha: 0.7),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Notify LP Team button (LP Worker only) ──
          if (ref.watch(authProvider).user?.isLogisticPartnerWorker == true)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_notifyingLP || _notifiedLP || widget.readOnly) ? null : _notifyLP,
              icon: _notifyingLP
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_notifiedLP ? Icons.check_circle_rounded : Icons.group_rounded,
                      size: 18),
              label: Text(_notifiedLP
                  ? '${widget.trip.lpOrgName ?? 'LP Team'} Notified'
                  : _notifyingLP
                      ? 'Sending…'
                      : 'Notify ${widget.trip.lpOrgName ?? 'LP Team'}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _notifiedLP ? _success : const Color(0xFF006B5E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: _success.withValues(alpha: 0.7),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Sync to RR button (LP/RR-ops only) ──
          if (trip.rrTripId != null && _canManageRr && !widget.readOnly) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_syncingToRr || _alreadySyncedToRr) ? null : _syncToRr,
                icon: _syncingToRr
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_alreadySyncedToRr ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
                        size: 18),
                label: Text(_alreadySyncedToRr
                    ? 'Synced to RR web'
                    : _syncingToRr
                        ? 'Syncing…'
                        : 'Sync to RR web'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alreadySyncedToRr ? _success.withValues(alpha: 0.7) : _StageTheme.rrWeb.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _success.withValues(alpha: 0.7),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (_rrSyncPromptError != null) ...[
              const SizedBox(height: 8),
              Text(_rrSyncPromptError!, textAlign: TextAlign.center, style: _inter(size: 11.5, color: _error)),
            ],
            const SizedBox(height: 12),
          ],

          // Back to Dashboard — secondary
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onDone,
              style: OutlinedButton.styleFrom(
                foregroundColor: _secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: _border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _inter(size: 13, color: _secondary)),
        Flexible(
          child: Text(value,
              style: _manrope(size: 13, weight: FontWeight.w700),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ─── Stage 0: Landing view (new trip, not yet synced to RR) ──────────────────

class _Stage0LandingView extends StatelessWidget {
  final TripModel trip;
  const _Stage0LandingView({required this.trip});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.upload_rounded, size: 36, color: Color(0xFFFF8F00)),
          ),
          const SizedBox(height: 20),
          Text('Stage 0 — RR Sync',
              style: _manrope(size: 18, weight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            'Before proceeding to Stage 1, complete the following steps:',
            style: _inter(size: 13, color: _secondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _StepRow(
            number: '1',
            title: 'Fill Stage 1 — Truck Registration',
            subtitle: 'Tap Stage 1 in the strip above to enter vehicle & driver details.',
            done: trip.currentStage >= 1,
          ),
          const SizedBox(height: 14),
          _StepRow(
            number: '2',
            title: 'Sync trip to RR',
            subtitle: 'Once Stage 1 is complete, use the "Send to RR" button above to push the trip.',
            done: trip.rrTripId != null,
          ),
          const SizedBox(height: 14),
          _StepRow(
            number: '3',
            title: 'Continue to Stage 2',
            subtitle: 'After RR sync, proceed with Pre-Arrival Compliance Check.',
            done: trip.currentStage >= 2,
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final bool done;
  const _StepRow({required this.number, required this.title, required this.subtitle, required this.done});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    const amber = Color(0xFFFF8F00);
    final color = done ? green : amber;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 14, color: green)
                : Text(number, style: _inter(size: 11, weight: FontWeight.w700, color: amber)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _manrope(size: 13, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle, style: _inter(size: 11, color: _secondary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stage 0: RR Sync Status Card ─────────────────────────────────────────

class _Stage0Card extends ConsumerStatefulWidget {
  final TripModel trip;
  final VoidCallback onSyncDone;
  final bool readOnly;
  const _Stage0Card({super.key, required this.trip, required this.onSyncDone, this.readOnly = false});

  @override
  ConsumerState<_Stage0Card> createState() => _Stage0CardState();
}

class _Stage0CardState extends ConsumerState<_Stage0Card> {
  bool    _sending = false;
  String? _sendError;

  Future<void> _sendToRr() async {
    final session = await ensureRrSession(context, ref);
    if (session == null || !mounted) return;
    setState(() { _sending = true; _sendError = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/api/rr/complete-trip/${widget.trip.id}',
        data: {'rr_token': session.token},
      );
      if (!mounted) return;
      widget.onSyncDone();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().split(':').last.trim();
      setState(() => _sendError = msg);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final synced = trip.rrTripId != null;
    final failed = !synced && trip.rrSyncStatus == 'failed';

    // Nothing actionable to show once synced — no "Synced to RR Web" banner.
    if (synced) return const SizedBox.shrink();

    final user = ref.read(authProvider).user;
    final canManageRr = user?.roleKey == 'logistic_partner' || user?.isLpRrOperations == true;
    if (!canManageRr) return const SizedBox.shrink();

    const bgRed   = Color(0xFFFFEBEE);
    const bgGrey  = Color(0xFFF5F5F5);

    final Color  cardBg;
    final Color  accentColor;
    final IconData icon;
    final String title;
    final String subtitle;

    if (failed) {
      cardBg      = bgRed;
      accentColor = _error;
      icon        = Icons.error_outline_rounded;
      title       = 'RR sync failed';
      subtitle    = trip.rrSyncError ?? 'Unknown error';
    } else {
      cardBg      = bgGrey;
      accentColor = const Color(0xFF9E9E9E);
      icon        = Icons.hourglass_top_rounded;
      title       = 'Not synced to RR';
      subtitle    = 'Tap retry to push this trip to RR Web';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: _manrope(size: 13, weight: FontWeight.w700, color: accentColor)),
              ),
              if (!synced && !_sending && !widget.readOnly)
                GestureDetector(
                  onTap: _sendToRr,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      failed ? 'Retry' : 'Send to RR',
                      style: _manrope(size: 12, weight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              if (_sending)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: _inter(size: 11, color: accentColor.withOpacity(0.85)),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (_sendError != null) ...[
            const SizedBox(height: 4),
            Text(_sendError!, style: _inter(size: 11, color: _error),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

/// Compact per-stage RR sync status row (S1 driver/vehicle docs, S2 loading slip,
/// S3 bilty/weight receipt, S4 fuel slip, S5 POD + halting charge). Each stage
/// syncs automatically in the background as it's submitted — this panel just
/// reflects that state and, for LP/RR-ops, offers a way to resume a stalled sync.
class _RrPerStageSyncPanel extends ConsumerStatefulWidget {
  final TripModel trip;
  final VoidCallback onRetryDone;
  final bool readOnly;
  const _RrPerStageSyncPanel({super.key, required this.trip, required this.onRetryDone, this.readOnly = false});

  @override
  ConsumerState<_RrPerStageSyncPanel> createState() => _RrPerStageSyncPanelState();
}

class _RrPerStageSyncPanelState extends ConsumerState<_RrPerStageSyncPanel> {
  bool _retrying = false;

  static const Map<int, String> _stageLabels = {
    1: 'S1 Docs',
    2: 'S2 Slip',
    3: 'S3 Docs',
    4: 'S4 Fuel',
    5: 'S5 POD',
  };

  String? _statusFor(int stage) {
    final t = widget.trip;
    switch (stage) {
      case 1: return t.rrS1SyncStatus;
      case 2: return t.rrS2SyncStatus;
      case 3: return t.rrS3SyncStatus;
      case 4: return t.rrS4SyncStatus;
      case 5: return t.rrS5SyncStatus;
    }
    return null;
  }

  String? _errorFor(int stage) {
    final t = widget.trip;
    switch (stage) {
      case 1: return t.rrS1SyncError;
      case 2: return t.rrS2SyncError;
      case 3: return t.rrS3SyncError;
      case 4: return t.rrS4SyncError;
      case 5: return t.rrS5SyncError;
    }
    return null;
  }

  Color _colorFor(String? status) {
    switch (status) {
      case 'synced':
      case 'loading_slip_synced':
      case 'bilty_synced':
      case 'pod_synced':
      case 'trip_created':
        return const Color(0xFF2E7D32);
      case 'failed':
        return _error;
      case 'auth_required':
        return const Color(0xFFB07800);
      case 'pending_trip_creation':
      case 'not_synced':
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _iconFor(String? status) {
    switch (status) {
      case 'synced':
      case 'loading_slip_synced':
      case 'bilty_synced':
      case 'pod_synced':
      case 'trip_created':
        return Icons.check_circle_rounded;
      case 'failed':
        return Icons.error_outline_rounded;
      case 'auth_required':
        return Icons.lock_outline_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Future<void> _retry() async {
    final session = await ensureRrSession(context, ref);
    if (session == null || !mounted) return;
    setState(() => _retrying = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/rr/sync/retry/${widget.trip.id}', data: {});
      if (!mounted) return;
      widget.onRetryDone();
    } catch (_) {
      // Errors surface naturally on next fetch via the per-stage error fields.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final canManageRr = (user?.roleKey == 'logistic_partner' || user?.isLpRrOperations == true) && !widget.readOnly;

    final statuses = {for (final s in _stageLabels.keys) s: _statusFor(s)};
    final hasAuthRequired = statuses.values.any((s) => s == 'auth_required');
    final hasFailed = statuses.values.any((s) => s == 'failed');
    final firstError = _stageLabels.keys
        .map((s) => _errorFor(s))
        .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('RR Sync', style: _manrope(size: 12, weight: FontWeight.w700, color: const Color(0xFF616161))),
              const Spacer(),
              if (canManageRr && (hasAuthRequired || hasFailed))
                GestureDetector(
                  onTap: _retrying ? null : _retry,
                  child: _retrying
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                        )
                      : Text(
                          hasAuthRequired ? 'Sign in to RR' : 'Retry',
                          style: _manrope(size: 11, weight: FontWeight.w700, color: _primary),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: _stageLabels.entries.map((e) {
              final status = statuses[e.key];
              final color = _colorFor(status);
              final chip = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconFor(status), size: 13, color: color),
                  const SizedBox(width: 3),
                  Text(e.value, style: _inter(size: 10.5, color: color)),
                  if (e.key == 1 && canManageRr) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 13, color: color),
                  ],
                ],
              );
              if (e.key == 1 && canManageRr) {
                return GestureDetector(
                  onTap: () => RrIdentityDocsSheet.show(context, ref, widget.trip),
                  child: chip,
                );
              }
              return chip;
            }).toList(),
          ),
          if (firstError != null) ...[
            const SizedBox(height: 4),
            Text(firstError, style: _inter(size: 10.5, color: _error),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

/// Lists Stage 1 driver/vehicle docs against what RR already has, so LP/RR-ops
/// can see WHY a doc didn't sync (RR already had an entry for that id_name —
/// auto-sync always skips on conflict rather than silently overwriting RR's
/// data) and, after previewing, explicitly override it with our copy.
class RrIdentityDocsSheet extends ConsumerStatefulWidget {
  final TripModel trip;
  const RrIdentityDocsSheet({super.key, required this.trip});

  static Future<void> show(BuildContext context, WidgetRef ref, TripModel trip) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => RrIdentityDocsSheet(trip: trip),
      ),
    );
  }

  @override
  ConsumerState<RrIdentityDocsSheet> createState() => _RrIdentityDocsSheetState();
}

class _RrIdentityDocsSheetState extends ConsumerState<RrIdentityDocsSheet> {
  bool _loading = true;
  String? _loadError;
  List<Map<String, dynamic>> _items = [];
  final Set<String> _overriding = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _errMsg(Object e) => e is DioException
      ? _dioErrorDetail(e, 'Request failed')
      : e.toString();

  Future<void> _load() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/api/rr/identity-status/${widget.trip.id}');
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(resp.data['items'] as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _loadError = _errMsg(e); });
    }
  }

  Future<void> _previewFile(String fileId) async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get(
        '/api/rr/file-preview/$fileId',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(resp.data as List<int>);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(children: [
            InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain)),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ]),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Preview failed: ${_errMsg(e)}', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _override(Map<String, dynamic> item) async {
    final session = await ensureRrSession(context, ref);
    if (session == null || !mounted) return;

    final key = '${item['entity_type']}_${item['id_name']}';
    setState(() => _overriding.add(key));
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/rr/identity-override', data: {
        'trip_id': widget.trip.id,
        'entity_type': item['entity_type'],
        'id_name': item['id_name'],
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_errMsg(e), style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _overriding.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final canOverride = user?.roleKey == 'logistic_partner' || user?.isLpRrOperations == true;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Driver & Vehicle RR Docs', style: _manrope(size: 16, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Status of each Stage 1 document against RR web',
                style: _inter(size: 12, color: _secondary)),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(_loadError!, style: _inter(size: 13, color: _error)),
              )
            else if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No driver/vehicle assigned to this trip yet.',
                    style: _inter(size: 13, color: _secondary)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 20),
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    final oursSynced = item['ours_synced'] == true;
                    final rrHasEntry = item['rr_has_entry'] == true;
                    final fileId = item['rr_file_id'] as String?;
                    final key = '${item['entity_type']}_${item['id_name']}';
                    final busy = _overriding.contains(key);

                    final String statusText;
                    final Color statusColor;
                    if (oursSynced) {
                      statusText = 'Synced by us';
                      statusColor = _success;
                    } else if (rrHasEntry) {
                      statusText = 'RR already has a different doc';
                      statusColor = const Color(0xFFB07800);
                    } else {
                      statusText = 'Not on RR yet';
                      statusColor = _secondary;
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['entity_type'] == 'driver' ? 'Driver' : 'Vehicle'} — ${item['id_name']}',
                                style: _manrope(size: 13, weight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(statusText, style: _inter(size: 11.5, color: statusColor)),
                            ],
                          ),
                        ),
                        if (rrHasEntry && fileId != null)
                          TextButton(
                            onPressed: () => _previewFile(fileId),
                            child: Text('Preview', style: _manrope(size: 12, weight: FontWeight.w700, color: _primary)),
                          ),
                        if (canOverride && !oursSynced)
                          busy
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                                )
                              : TextButton(
                                  onPressed: () => _override(item),
                                  child: Text(
                                    rrHasEntry ? 'Override' : 'Upload',
                                    style: _manrope(size: 12, weight: FontWeight.w700, color: _error),
                                  ),
                                ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
