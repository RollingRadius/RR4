/// RR Web trip card — used for trips synced via POST /create_trip.
/// Read-only trip info summary; tapping the card opens RrTripStagesScreen for
/// the full S1-S5 process (checkboxes, uploads, per-stage RR doc sync).
library;

import 'dart:ui' show ImageFilter;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/l10n/app_localizations.dart';
import 'package:fleet_management/presentation/screens/fleet_owner/rr_trip_stages_screen.dart';
import 'package:fleet_management/presentation/screens/trips/create_trip_screen.dart';
import 'package:fleet_management/presentation/screens/trips/trip_locate_screen.dart';
import 'package:fleet_management/presentation/widgets/rr_booking_actions.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _rrBlue    = Color(0xFF1B6CA8);
const _rrBlueMid = Color(0xFF2980B9);
const _white     = Color(0xFFFFFFFF);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _done      = Color(0xFF2E7D32);
const _doneBg    = Color(0xFFE8F5E9);

TextStyle _manrope({
  double size = 14,
  FontWeight weight = FontWeight.w600,
  Color color = _onSurface,
}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _secondary,
}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

/// RR4's own `created_at` is a proper timezone-aware ISO timestamp (unlike
/// RR's naive-echo quirk seen elsewhere), so a plain parse + toLocal is safe.
String _fmtCreatedAt(String? iso) {
  if (iso == null) return '—';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '—';
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  return '${dt.day} ${months[dt.month - 1]}, $hour12:$minute $ampm';
}

// ─── Main card widget ─────────────────────────────────────────────────────────

class RrTripCard extends ConsumerStatefulWidget {
  final TripModel trip;

  /// Called after a successful loading slip upload so the parent can refresh.
  final VoidCallback? onRefresh;

  const RrTripCard({super.key, required this.trip, this.onRefresh});

  @override
  ConsumerState<RrTripCard> createState() => _RrTripCardState();
}

class _RrTripCardState extends ConsumerState<RrTripCard> {
  bool _tripInfoExpanded = false;
  bool _togglingS1 = false;
  bool _confirmingBooking = false;
  /// Local override so the switch reflects the toggle immediately, before
  /// the parent's next refresh brings back an updated TripModel.
  bool? _s1RequiredOverride;
  Offset? _lastTapPosition;
  /// Booking / trip cancels of this trip (reason, who, when); null = not loaded yet.
  List<Map<String, dynamic>>? _cancelEvents;

  TripModel get trip => widget.trip;

  bool get _canManageRr {
    final user = ref.read(authProvider).user;
    return user?.roleKey == 'logistic_partner' || user?.isLpRrOperations == true;
  }

  /// True when RR's own booking step (POST /create_trip) itself failed (e.g.
  /// an unapproved third-party vehicle hire) — a genuine attempted-and-errored
  /// booking, not the normal "not yet synced/pending" states a trip passes
  /// through before it's even tried. LP/RR-ops get a "Confirm Booking" retry
  /// action for this; FE (logistic_partner_worker) gets blocked from entering
  /// the trip at all until it's resolved, since there's nothing useful for
  /// them to do yet.
  ///
  /// Must check rrTripId == null too: `rr_sync_status` is reused by
  /// sync_all_to_rr for a LATER per-stage doc/slip sync failure on a trip
  /// that's already booked on RR (rr_trip_id/rr_parcel_id already set) — that
  /// is a completely different, unrelated failure, not "booking never
  /// happened", and must never show this "Confirm Booking" banner.
  bool get _needsBookingConfirmation =>
      trip.rrTripId == null && trip.rrSyncStatus == 'failed';

  Future<void> _confirmBooking() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _confirmingBooking = true);
    try {
      // Two genuinely different failure points need two different retry
      // endpoints:
      //  - rrTripId == null: the trip was never even created on RR — the
      //    original /api/rr/complete-trip call itself failed (this is what
      //    "Please add driver for vehicle."-style booking errors are —
      //    trip_stage stuck at "Bidding" on RR's side). /api/rr/sync/retry
      //    only retries per-STAGE syncs (1-5) based on current_stage, and is
      //    a silent no-op when current_stage is still 0 — it can never fix
      //    this. complete-trip is also synchronous, so no polling needed.
      //  - rrTripId already set: the trip exists on RR, a later stage's sync
      //    failed — /sync/retry is correct here, and does need polling since
      //    it only queues a background task.
      //
      // Both run via runRrAction — no RR login prompt unless the org
      // genuinely has no valid session (backend returns 409), since the org's
      // own auto-refreshing session already covers this the vast majority of
      // the time.
      if (trip.rrTripId == null) {
        final resp = await runRrAction(context, ref, () {
          final dio = ref.read(dioProvider);
          // RR's own /create_trip call has a 60s budget on the backend, plus
          // up to ~15s more if the org's cached RR token needed a silent
          // refresh first — extend past the app's global 60s receiveTimeout
          // so a genuinely-slow-but-successful RR call isn't misreported as
          // a client-side timeout.
          return dio.post('/api/rr/complete-trip/${trip.id}', data: const {},
              options: Options(receiveTimeout: const Duration(seconds: 90)));
        });
        if (!mounted) return;
        final success = resp.data is Map && (resp.data['success'] == true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? l10n.tripCardBookingConfirmed : l10n.tripCardBookingConfirmFailed,
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: success ? _done : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        await runRrAction(context, ref, () {
          final dio = ref.read(dioProvider);
          return dio.post('/api/rr/sync/retry/${trip.id}', data: const {});
        });
        if (!mounted) return;

        // /sync/retry only queues a background task and returns immediately
        // — poll for the real outcome (same pattern as
        // _Stage4CompleteView._pollForSyncCompletion in
        // rr_trip_stages_screen.dart) instead of showing a static message.
        bool? succeeded;
        for (var i = 0; i < 6 && mounted; i++) {
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          try {
            await ref.read(tripProvider.notifier).fetchSingleTrip(trip.id);
          } catch (_) {
            break;
          }
          if (!mounted) return;
          if (trip.rrSyncStatus != 'failed') {
            succeeded = true;
            break;
          }
        }
        if (!mounted) return;

        if (succeeded == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.tripCardBookingConfirmed, style: _inter(size: 13, color: Colors.white)),
            backgroundColor: _done,
            behavior: SnackBarBehavior.floating,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              (trip.rrSyncError != null && trip.rrSyncError!.isNotEmpty)
                  ? l10n.tripCardStillFailingWith(trip.rrSyncError!)
                  : l10n.tripCardStillFailing,
              style: _inter(size: 13, color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ));
        }
      }
      widget.onRefresh?.call();
    } catch (e) {
      if (mounted) {
        final msg = e is DioException && e.response?.data is Map
            ? (e.response!.data['detail']?.toString() ?? l10n.tripCardRetryBookingFailed)
            : l10n.tripCardRetryBookingFailed;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: _inter(size: 13, color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _confirmingBooking = false);
    }
  }

  Future<void> _toggleS1Required(bool value) async {
    final l10n = AppLocalizations.of(context);
    setState(() { _togglingS1 = true; _s1RequiredOverride = value; });
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${trip.id}/s1-required', data: {'required': value});
    } catch (e) {
      if (mounted) {
        setState(() => _s1RequiredOverride = !value);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.tripCardUpdateFailed,
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _togglingS1 = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  /// A Records trip (explicitly moved via long-press → Move to Records — same
  /// condition the backend uses) opens read-only for LP/RR-ops and not at all
  /// for FE/LP-worker. Anything still in Fleet Status opens normally and stays
  /// editable/re-syncable for whoever has access, even once fully synced —
  /// only the explicit archive action makes a trip read-only.
  bool get _isRecordsTrip => trip.movedToRecordsAt != null;

  /// Tapping the card (outside the "Trip Info" expand toggle, which has its own
  /// tap handler and wins the hit-test first) opens the full S1-S5 stage process
  /// — same screen normal trips use — where checkboxes, uploads, and per-stage
  /// RR doc sync all happen for this particular trip.
  void _openStages(BuildContext context) {
    if (_isRecordsTrip) {
      if (!_canManageRr) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).tripCardCompletedViewOnly,
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _secondary,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RrTripStagesScreen(trip: trip, readOnly: true)),
      );
      return;
    }
    // FE cannot fill the stages of a trip whose booking or trip is cancelled - in the app or on RR web (user,
    // 2026-11-24); the server refuses those saves for everyone anyway.
    if (!_canManageRr && (trip.status == 'cancelled' || trip.isBookingCancelled)) {
      final l10n = AppLocalizations.of(context);
      final tripCancelled = trip.status == 'cancelled';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(tripCancelled ? Icons.cancel_outlined : Icons.local_shipping_outlined, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tripCancelled ? l10n.tripCardFeTripCancelled : l10n.tripCardFeBookingCancelled,
                  style: _inter(size: 14, weight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 2),
              Text(tripCancelled ? l10n.tripCardFeTripCancelledHint : l10n.tripCardFeBookingCancelledHint,
                  style: _inter(size: 13, color: Colors.white)),
            ]),
          ),
        ]),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_needsBookingConfirmation && !_canManageRr) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).tripCardAwaitCompanyConfirm,
            style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _secondary,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RrTripStagesScreen(trip: trip)),
    ).then((_) => widget.onRefresh?.call());
  }

  /// LP/RR-ops only (gated at the call site) — opens the swipeable edit dialog
  /// for this trip's parcel details; refreshes the card when a save went through.
  Future<void> _openEdit() async {
    // A floating card over the trip list — margin on all four sides so every
    // corner is visibly rounded (not a sheet flush against one screen edge,
    // which only ever shows two rounded corners). Tap-outside still dismisses;
    // CreateTripScreen's own PopScope (canPop: false) intercepts that pop the
    // same as the system back button and routes it through the same
    // discard-changes confirmation, so an edit can never be lost by a stray tap.
    final size = MediaQuery.sizeOf(context);
    final dialogHeight = size.height * 0.86;
    // showGeneralDialog instead of showDialog — showDialog's barrier is a flat
    // colour with no way to blur what's behind it. barrierColor is left fully
    // transparent here; the frosted look is painted ourselves below.
    final saved = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: AppLocalizations.of(context).tripCardDismiss,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              // Tap the blurred trip list behind the card to dismiss — routed
              // through maybePop so CreateTripScreen's PopScope still gets the
              // chance to show its discard-changes confirmation first.
              onTap: () => Navigator.of(dialogContext).maybePop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(color: Colors.black.withValues(alpha: 0.30)),
              ),
            ),
          ),
          Center(
            child: Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: (size.height - dialogHeight) / 2,
              ),
              backgroundColor: const Color(0xFFF8F9FB), // matches CreateTripScreen's own _bg
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(dialogContext).bottom),
                child: SizedBox(
                  height: dialogHeight,
                  width: double.infinity,
                  child: CreateTripScreen(editTrip: trip),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (saved == true) widget.onRefresh?.call();
  }

  /// LP/RR-ops only (gated at the call site via _canManageRr) — opens the
  /// same live-location map Load Owner already has for their own trips, so
  /// LP/RR-ops can track whichever driver is currently linked to this trip.
  void _openTrackScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TripLocateScreen(trip: trip)),
    );
  }

  // ── Move to Records — long-press context menu, LP/RR-ops only ──────────────
  // Independent of sync progress: no gating on stage completeness or sync
  // status, intentional so abandoned/cancelled trips can be archived too.
  // One-directional for now, no "move back out" action.

  Future<void> _moveToRecords() async {
    final l10n = AppLocalizations.of(context);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/trips/${trip.id}/move-to-records');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.tripCardMovedToRecords, style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _done,
        behavior: SnackBarBehavior.floating,
      ));
      widget.onRefresh?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.tripCardMoveToRecordsFailed, style: _inter(size: 13, color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // Manual early release: frees the driver from this trip's assignment-lock
  // (can be booked onto a new trip immediately) and blanks this trip's own
  // live-location map — before POD, without touching status/stage data.
  // Reversible via _resumeDriverTracking, so the confirm dialog no longer
  // needs to warn this is permanent.
  Future<void> _stopDriverTracking() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tripCardStopTrackingTitle),
        content: Text(l10n.tripCardStopTrackingBody(trip.driverName ?? l10n.tripCardTheDriver)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.tripCardStopTrackingButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/trips/${trip.id}/stop-tracking');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.tripCardTrackingStopped, style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _done,
        behavior: SnackBarBehavior.floating,
      ));
      widget.onRefresh?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.tripCardStopTrackingFailed, style: _inter(size: 13, color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // Undoes _stopDriverTracking — the driver's app picks this back up on its
  // next tracking sync (app open/resume or the 30s poll), no driver-side
  // action needed.
  Future<void> _resumeDriverTracking() async {
    final l10n = AppLocalizations.of(context);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/trips/${trip.id}/resume-tracking');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.tripCardTrackingResumed, style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _done,
        behavior: SnackBarBehavior.floating,
      ));
      widget.onRefresh?.call();
    } catch (e) {
      if (!mounted) return;
      final isConflict = e is DioException &&
          e.response?.statusCode == 400 &&
          (e.response?.data?['detail']?.toString().contains('already has an open trip') ?? false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isConflict
              ? l10n.tripCardResumeConflict(trip.driverName ?? l10n.tripCardThisDriver)
              : l10n.tripCardResumeFailed,
          style: _inter(size: 13, color: Colors.white),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _showLongPressMenu(BuildContext context, Offset globalPosition) async {
    if (!_canManageRr) return; // FE never gets this menu
    final l10n = AppLocalizations.of(context);
    final alreadyInRecords = trip.movedToRecordsAt != null;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'move_to_records',
          enabled: !alreadyInRecords,
          child: Text(
            alreadyInRecords ? l10n.tripCardAlreadyInRecords : l10n.tripCardMoveToRecords,
            style: _inter(size: 13, weight: FontWeight.w600,
                color: alreadyInRecords ? _secondary : _onSurface),
          ),
        ),
        ..._bookingMenuItems(l10n),
      ],
    );
    await _handleMenuChoice(selected);
  }

  /// Cancel booking / Book another truck / Cancel trip (trips in RR web only; md/RR_BOOKING_CANCEL_RULES.md).
  List<PopupMenuEntry<String>> _bookingMenuItems(AppLocalizations l10n) {
    if (trip.rrTripId == null || trip.status == 'cancelled') return const [];
    PopupMenuItem<String> item(String value, String label, bool enabled, {bool danger = false}) => PopupMenuItem(
          value: value,
          enabled: enabled,
          child: Text(label, style: _inter(size: 13, weight: FontWeight.w600,
              color: !enabled ? _secondary : (danger ? Colors.red.shade700 : _onSurface))),
        );
    return [
      const PopupMenuDivider(),
      if (trip.isBookingCancelled)
        item('rebook', l10n.bookingMenuRebook, canRebook(trip))
      else
        item('cancel_booking',
            tripHasLoadedWeight(trip) ? l10n.bookingMenuNoCancelWeight : l10n.bookingMenuCancelBooking,
            canCancelBooking(trip), danger: true),
      item('cancel_trip', canCancelTrip(trip) ? l10n.bookingMenuCancelTrip : l10n.bookingMenuCancelTripDisabled,
          canCancelTrip(trip), danger: true),
    ];
  }

  Future<void> _handleMenuChoice(String? selected) async {
    if (selected == null || !mounted) return;
    var changed = false;
    switch (selected) {
      case 'move_to_records':
        await _moveToRecords();
        return;
      case 'cancel_booking':
        changed = await runCancelBooking(context, ref, trip);
      case 'rebook':
        changed = await runRebook(context, ref, trip);
      case 'cancel_trip':
        changed = await runCancelTrip(context, ref, trip);
    }
    if (!changed || !mounted) return;
    try {
      await ref.read(tripProvider.notifier).fetchSingleTrip(trip.id);
    } catch (_) {}
    widget.onRefresh?.call();
    if (_tripInfoExpanded) await _loadCancelEvents();
  }

  Future<void> _showMoreMenu(BuildContext anchorContext) async {
    final l10n = AppLocalizations.of(context);
    final box = anchorContext.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset(0, box.size.height), ancestor: overlay);
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
      items: _bookingMenuItems(l10n).where((e) => e is! PopupMenuDivider).toList(),
    );
    await _handleMenuChoice(selected);
  }

  /// Soft red panel shared by the booking-cancelled and trip-cancelled marks (user, 2026-11-24): round icon badge,
  /// bold title, short line, optional action below (stacked: side by side they do not fit a narrow phone at a large
  /// font).
  Widget _cancelPanel({required IconData icon, required String title, String? subtitle, Widget? action}) {
    final red = Colors.red.shade700;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      color: const Color(0xFFFFF1F1),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: const Color(0xFFFFE0E0), shape: BoxShape.circle),
            child: Icon(icon, color: red, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: _manrope(size: 13, weight: FontWeight.w800, color: red)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: _inter(size: 12, color: const Color(0xFF8E2B2B))),
              ],
            ]),
          ),
        ]),
        if (action != null) ...[const SizedBox(height: 10), action],
      ]),
    );
  }

  /// A cancelled trip stays in the dashboard list, marked like this (user, 2026-11-24).
  Widget _buildTripCancelledBanner() {
    final l10n = AppLocalizations.of(context);
    return _cancelPanel(icon: Icons.block_rounded, title: l10n.tripCardFeTripCancelled);
  }

  Widget _buildBookingCancelledBanner() {
    final l10n = AppLocalizations.of(context);
    return _cancelPanel(
      icon: Icons.local_shipping_outlined,
      title: l10n.tripCardFeBookingCancelled,
      subtitle: l10n.tripCardFeBookingCancelledHint,
      action: (_canManageRr && canRebook(trip))
          ? FilledButton.icon(
              onPressed: () => _handleMenuChoice('rebook'),
              icon: const Icon(Icons.add_road_rounded, size: 18),
              label: Text(l10n.bookingMenuRebook, style: _manrope(size: 13, weight: FontWeight.w700, color: Colors.white)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                elevation: 0,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openStages(context),
        onTapDown: (details) => _lastTapPosition = details.globalPosition,
        onLongPress: () => _showLongPressMenu(context, _lastTapPosition ?? Offset.zero),
        child: Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _rrBlue.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (_needsBookingConfirmation && _canManageRr) _buildConfirmBookingBanner(),
              if (trip.isBookingCancelled && trip.status != 'cancelled') _buildBookingCancelledBanner(),
              if (trip.status == 'cancelled') _buildTripCancelledBanner(),
              _buildS1ToggleRow(),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F8)),
              _buildStep1Tile(),
              if (_tripInfoExpanded) _buildStep1Info(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Confirm Booking banner (LP/RR-ops only, shown when RR sync failed) ────────

  Widget _buildConfirmBookingBanner() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      color: const Color(0xFFFFF3E0),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE65100), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.tripCardBookingNeedsConfirm,
                style: _inter(size: 12, weight: FontWeight.w600, color: const Color(0xFFE65100))),
          ),
          const SizedBox(width: 8),
          _confirmingBooking
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE65100)),
                )
              : ElevatedButton(
                  onPressed: _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l10n.tripCardConfirmBooking, style: _manrope(size: 12, color: Colors.white)),
                ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    final rrNum = trip.rrTripNumber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF124E7E), _rrBlueMid],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: (rrNum != null && rrNum.isNotEmpty)
                ? Text(rrNum,
                    style: _manrope(size: 15, weight: FontWeight.w800, color: _white),
                    overflow: TextOverflow.ellipsis)
                : Text(trip.tripNumber,
                    style: _manrope(size: 13, weight: FontWeight.w600,
                        color: _white.withOpacity(0.7)),
                    overflow: TextOverflow.ellipsis),
          ),
          if (trip.vehicleNumber != null && trip.vehicleNumber!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(trip.vehicleNumber!,
                style: _manrope(size: 13, weight: FontWeight.w700, color: _white)),
          ],
          if (_canManageRr && !_isRecordsTrip) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: l10n.tripCardEditTrip,
              child: InkWell(
                onTap: _openEdit,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, color: _white, size: 18),
                ),
              ),
            ),
          ],
          if (_canManageRr && !_isRecordsTrip && trip.rrTripId != null && trip.status != 'cancelled')
            Builder(builder: (anchor) => Tooltip(
              message: l10n.bookingMoreActions,
              child: InkWell(
                onTap: () => _showMoreMenu(anchor),
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.more_vert, color: _white, size: 18),
                ),
              ),
            )),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Text(trip.origin,
                style: _manrope(size: 13, weight: FontWeight.w700, color: _white),
                overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded,
                color: _white.withOpacity(0.7), size: 16),
          ),
          Expanded(
            child: Text(trip.destination,
                style: _manrope(size: 13, weight: FontWeight.w700, color: _white),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Text(
              l10n.tripCardCreated(_fmtCreatedAt(trip.createdAt)),
              style: _inter(size: 12, color: _white.withOpacity(0.8)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trip.s4BiltyNumber != null && trip.s4BiltyNumber!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Icon(Icons.receipt_long_rounded, color: _white.withOpacity(0.8), size: 13),
            const SizedBox(width: 4),
            Text(
              l10n.tripCardBiltyNo(trip.s4BiltyNumber!),
              style: _inter(size: 12, color: _white.withOpacity(0.9), weight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ]),
      ]),
    );
  }

  // ── S1-required toggle (LP/RR-ops only, Fleet Status only) ────────────────────

  Widget _buildS1ToggleRow() {
    if (_isRecordsTrip || !_canManageRr) return const SizedBox.shrink();
    final required = _s1RequiredOverride ?? trip.s1Required;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      child: Row(children: [
        const Icon(Icons.badge_outlined, color: _rrBlue, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(l10n.tripCardAllowFeStage1,
              style: _inter(size: 12, weight: FontWeight.w600, color: _onSurface)),
        ),
        _togglingS1
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: _rrBlue),
              )
            : Switch(
                value: required,
                activeColor: _rrBlue,
                onChanged: _toggleS1Required,
              ),
      ]),
    );
  }

  // ── Trip info collapsible tile ────────────────────────────────────────────────

  Widget _buildStep1Tile() {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () {
        setState(() => _tripInfoExpanded = !_tripInfoExpanded);
        if (_tripInfoExpanded) _loadCancelEvents();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(children: [
          const Icon(Icons.receipt_long_outlined, color: _rrBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.tripCardTripInfo,
              style: _manrope(size: 13, weight: FontWeight.w700, color: _onSurface))),
          // Flexible: in Hindi at a large font on a narrow phone the badge did not fit next to the title.
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _doneBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(l10n.tripCardSyncedToRr,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: _inter(size: 11, weight: FontWeight.w600, color: _done)),
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            _tripInfoExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: _secondary,
            size: 20,
          ),
        ]),
      ),
    );
  }

  // ── Cancellations (booking / trip cancelled from the app) ───────────────────
  // Reason, who and when of every booking cancel and trip cancel (GET /api/rr/booking-events; RR web keeps no such
  // history - md/RR_BOOKING_CANCEL_RULES.md). Loaded when Trip Info is opened.

  Future<void> _loadCancelEvents() async {
    if (trip.rrTripId == null || !trip.hasCancellations) return;   // never cancelled: no request at all
    if (!_canManageRr) return;   // the booking history is for LP / RR-ops only (user, 2026-11-24)
    try {
      final r = await ref.read(dioProvider).get('/api/rr/booking-events/${trip.id}');
      final all = ((r.data as Map)['events'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() => _cancelEvents = all
          .where((e) => e['event'] == 'booking_cancelled' || e['event'] == 'trip_cancelled' ||
              (e['event'] as String? ?? '').startsWith('rr_web_'))
          .toList());
    } catch (_) {
      // Best-effort: Trip Info still shows everything else.
    }
  }

  String _bookingEventTitle(AppLocalizations l10n, String? event) => switch (event) {
        'trip_cancelled' => l10n.bookingCancelTripDone,
        'rr_web_trip_cancelled' => l10n.rrWebTripCancelled,
        'rr_web_booking_cancelled' => l10n.rrWebBookingCancelled,
        'rr_web_rebooked' => l10n.rrWebRebooked,
        'rr_web_driver_changed' => l10n.rrWebDriverChanged,
        'rr_web_updated' => l10n.rrWebUpdatedEntry,
        _ => l10n.bookingCancelDone,
      };

  Widget _buildCancelEvents(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            _cancelEvents!.any((e) => (e['event'] as String? ?? '').startsWith('rr_web_'))
                ? l10n.bookingHistoryTitleAll
                : l10n.bookingHistoryTitle,
            style: _manrope(size: 13, weight: FontWeight.w700, color: Colors.red.shade700)),
        const SizedBox(height: 6),
        for (final e in _cancelEvents!)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon((e['event'] as String? ?? '').startsWith('rr_web_') ? Icons.sync_alt_rounded : Icons.cancel_outlined,
                  size: 16, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_bookingEventTitle(l10n, e['event'] as String?),
                      style: _inter(size: 12, weight: FontWeight.w700, color: _onSurface)),
                  Text(l10n.bookingHistoryWhenBy(_fmtCreatedAt(e['at'] as String?), (e['by'] as String?) ?? '—'),
                      style: _inter(size: 11)),
                  if (e['event'] == 'rr_web_rebooked')
                    Text(l10n.rrWebTruckChange((e['old_vehicle_number'] as String?) ?? '—',
                        (e['new_vehicle_number'] as String?) ?? '—'), style: _inter(size: 12, color: _onSurface)),
                  if (e['event'] == 'rr_web_rebooked' || e['event'] == 'rr_web_driver_changed')
                    Text(l10n.rrWebNewDriver((e['new_driver_name'] as String?) ?? '—'),
                        style: _inter(size: 12, color: _onSurface)),
                  if ((e['reason'] as String?)?.isNotEmpty ?? false)
                    Text(
                        e['event'] == 'rr_web_updated'
                            ? l10n.rrWebChangedFields(e['reason'] as String)
                            : l10n.bookingHistoryReason(e['reason'] as String),
                        style: _inter(size: 12, color: _onSurface)),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }

  // ── Step 1 expanded info ─────────────────────────────────────────────────────

  Widget _buildStep1Info() {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: const Color(0xFFF8FAFB),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Track is an action, not a read-only field — kept visually distinct
        // (tappable row + chevron) from the plain _InfoRow entries below it.
        // LP/RR-ops only, same gating as everywhere else on this card.
        if (_canManageRr) ...[
          InkWell(
            onTap: () => _openTrackScreen(context),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: _rrBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l10n.tripCardTrackDriver,
                        style: _manrope(size: 13, weight: FontWeight.w700, color: _rrBlue)),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: _rrBlue.withOpacity(0.7)),
                ],
              ),
            ),
          ),
          _Divider(),
          if (trip.driverTrackingStopped)
            InkWell(
              onTap: _resumeDriverTracking,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: _rrBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.tripCardResumeTracking,
                          style: _manrope(size: 13, weight: FontWeight.w700, color: _rrBlue)),
                    ),
                  ],
                ),
              ),
            )
          else
            InkWell(
              onTap: _stopDriverTracking,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_off_outlined, size: 18, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.tripCardStopTracking,
                          style: _manrope(size: 13, weight: FontWeight.w700, color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ),
          _Divider(),
        ],
        _InfoRow(icon: Icons.schedule_outlined, label: l10n.tripCardLabelCreatedAt,
            value: _fmtCreatedAt(trip.createdAt)),
        _Divider(),
        if (_canManageRr && (_cancelEvents ?? const []).isNotEmpty) ...[   // LP / RR-ops only (user, 2026-11-24)
          _buildCancelEvents(l10n),
          _Divider(),
        ],

        // Parties
        if (trip.consignorName != null || trip.consigneeName != null) ...[
          _InfoRow(icon: Icons.business_outlined, label: l10n.tripCardLabelConsignor,
              value: trip.consignorName ?? '—'),
          if (trip.consignorGstin != null && trip.consignorGstin!.isNotEmpty)
            _InfoRow(icon: null, label: l10n.tripCardLabelConsignorGstin, value: trip.consignorGstin!),
          _InfoRow(icon: Icons.business_center_outlined, label: l10n.tripCardLabelConsignee,
              value: trip.consigneeName ?? '—'),
          if (trip.consigneeGstin != null && trip.consigneeGstin!.isNotEmpty)
            _InfoRow(icon: null, label: l10n.tripCardLabelConsigneeGstin, value: trip.consigneeGstin!),
          _Divider(),
        ],

        // Locations
        if (trip.pickupAddressLine1 != null || trip.pickupPin != null) ...[
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: l10n.tripCardLabelPickupAddress,
            value: [
              trip.pickupAddressLine1,
              trip.pickupAddressLine2,
              trip.pickupPin,
            ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
          ),
        ],
        if (trip.unloadAddressLine1 != null || trip.unloadPin != null) ...[
          _InfoRow(
            icon: Icons.flag_outlined,
            label: l10n.tripCardLabelUnloadAddress,
            value: [
              trip.unloadAddressLine1,
              trip.unloadAddressLine2,
              trip.unloadPin,
            ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
          ),
        ],
        if (trip.depotCode != null && trip.depotCode!.isNotEmpty)
          _InfoRow(icon: null, label: l10n.tripCardLabelDepotCode, value: trip.depotCode!),
        _Divider(),

        // Material
        _InfoRow(icon: Icons.inventory_2_outlined, label: l10n.tripCardLabelMaterial,
            value: trip.loadItem),
        if (trip.weight != null && trip.weight!.isNotEmpty)
          _InfoRow(icon: null, label: l10n.tripCardLabelWeight, value: trip.weight!),
        if (trip.parcelDescription != null && trip.parcelDescription!.isNotEmpty)
          _InfoRow(icon: null, label: l10n.tripCardLabelDescription, value: trip.parcelDescription!),
        if (trip.invoiceValue != null)
          _InfoRow(icon: null, label: l10n.tripCardLabelTotalInvoiceValue,
              value: '₹${trip.invoiceValue!.toStringAsFixed(0)}'),
        if (trip.partLoad == true)
          _InfoRow(icon: null, label: l10n.tripCardLabelPartLoad, value: l10n.commonYes),
        _Divider(),

        // Vehicle
        if (trip.vehicleNumber != null && trip.vehicleNumber!.isNotEmpty)
          _InfoRow(icon: Icons.local_shipping_outlined, label: l10n.tripCardLabelVehicle,
              value: trip.vehicleNumber!),
        if (trip.vehicleBodyType != null && trip.vehicleBodyType!.isNotEmpty)
          _InfoRow(icon: null, label: l10n.tripCardLabelBodyType, value: trip.vehicleBodyType!),
        if (trip.axleType != null && trip.axleType!.isNotEmpty)
          _InfoRow(icon: null, label: l10n.tripCardLabelAxleType, value: trip.axleType!),
        if (trip.numberOfWheels != null)
          _InfoRow(icon: null, label: l10n.tripCardLabelWheels, value: '${trip.numberOfWheels}'),
        if (trip.s4BiltyNumber != null && trip.s4BiltyNumber!.isNotEmpty) ...[
          _Divider(),
          _InfoRow(icon: Icons.receipt_long_rounded, label: l10n.tripCardLabelBiltyNumber,
              value: trip.s4BiltyNumber!),
        ],
      ]),
    );
  }
}

// ─── Info row (trip info read-only fields) ────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 20,
        child: icon != null
            ? Icon(icon, size: 15, color: _secondary)
            : null,
      ),
      const SizedBox(width: 4),
      SizedBox(
        width: 120,
        child: Text(label, style: _inter(size: 12)),
      ),
      Expanded(
        child: Text(value,
            style: _inter(size: 12, color: _onSurface, weight: FontWeight.w500)),
      ),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 12, thickness: 1, color: Color(0xFFF0F4F8));
}
