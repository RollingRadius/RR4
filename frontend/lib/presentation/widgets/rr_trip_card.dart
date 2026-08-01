/// RR Web trip card — used for trips synced via POST /create_trip.
/// Read-only trip info summary; tapping the card opens RrTripStagesScreen for
/// the full S1-S5 process (checkboxes, uploads, per-stage RR doc sync).
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/presentation/screens/fleet_owner/rr_trip_stages_screen.dart';
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

  TripModel get trip => widget.trip;

  bool get _canManageRr {
    final user = ref.read(authProvider).user;
    return user?.roleKey == 'logistic_partner' || user?.isLpRrOperations == true;
  }

  /// True when RR's own booking step failed (e.g. an unapproved third-party
  /// vehicle hire) — a genuine attempted-and-errored sync, not the normal
  /// "not yet synced/pending" states a trip passes through before it's even
  /// tried. LP/RR-ops get a "Confirm Booking" retry action for this; FE
  /// (logistic_partner_worker) gets blocked from entering the trip at all
  /// until it's resolved, since there's nothing useful for them to do yet.
  bool get _needsBookingConfirmation => trip.rrSyncStatus == 'failed';

  Future<void> _confirmBooking() async {
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
          content: Text(success ? 'Booking confirmed' : 'Could not confirm booking',
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
            content: Text('Booking confirmed', style: _inter(size: 13, color: Colors.white)),
            backgroundColor: _done,
            behavior: SnackBarBehavior.floating,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              (trip.rrSyncError != null && trip.rrSyncError!.isNotEmpty)
                  ? 'Still failing: ${trip.rrSyncError}'
                  : 'Still failing — check back or try again',
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
            ? (e.response!.data['detail']?.toString() ?? 'Could not retry booking — try again')
            : 'Could not retry booking — try again';
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
    setState(() { _togglingS1 = true; _s1RequiredOverride = value; });
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${trip.id}/s1-required', data: {'required': value});
    } catch (e) {
      if (mounted) {
        setState(() => _s1RequiredOverride = !value);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update — try again',
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

  /// A Records trip (fully completed + synced — same condition the backend
  /// uses to move it into Records) opens read-only for LP/RR-ops and not at
  /// all for FE/LP-worker. Anything still in Fleet Status opens normally for
  /// whoever has access, unchanged.
  bool get _isRecordsTrip => trip.currentStage >= 5 && trip.rrSyncStatus == 'pod_synced';

  /// Tapping the card (outside the "Trip Info" expand toggle, which has its own
  /// tap handler and wins the hit-test first) opens the full S1-S5 stage process
  /// — same screen normal trips use — where checkboxes, uploads, and per-stage
  /// RR doc sync all happen for this particular trip.
  void _openStages(BuildContext context) {
    if (_isRecordsTrip) {
      if (!_canManageRr) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Completed trips are view only',
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
    if (_needsBookingConfirmation && !_canManageRr) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Let this trip get confirmed by your company',
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

  // ── Move to Records — long-press context menu, LP/RR-ops only ──────────────
  // Independent of sync progress: no gating on stage completeness or sync
  // status, intentional so abandoned/cancelled trips can be archived too.
  // One-directional for now, no "move back out" action.

  Future<void> _moveToRecords() async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/trips/${trip.id}/move-to-records');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Trip moved to Records', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _done,
        behavior: SnackBarBehavior.floating,
      ));
      widget.onRefresh?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not move trip to Records', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _showLongPressMenu(BuildContext context, Offset globalPosition) async {
    if (!_canManageRr) return; // FE never gets this menu
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
            alreadyInRecords ? 'Already in Records' : 'Move to Records',
            style: _inter(size: 13, weight: FontWeight.w600,
                color: alreadyInRecords ? _secondary : _onSurface),
          ),
        ),
      ],
    );
    if (selected == 'move_to_records') await _moveToRecords();
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      color: const Color(0xFFFFF3E0),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE65100), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Booking needs confirmation',
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
                  child: Text('Confirm Booking', style: _manrope(size: 12, color: Colors.white)),
                ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text('RR WEB',
                style: _manrope(size: 10, weight: FontWeight.w800, color: _white)),
          ),
          const Spacer(),
          if (rrNum != null && rrNum.isNotEmpty) ...[
            Text(rrNum,
                style: _manrope(size: 15, weight: FontWeight.w800, color: _white)),
          ] else
            Text(trip.tripNumber,
                style: _manrope(size: 13, weight: FontWeight.w600,
                    color: _white.withOpacity(0.7))),
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
        const SizedBox(height: 4),
        Text(
          [
            trip.loadItem,
            if (trip.weight != null && trip.weight!.isNotEmpty) trip.weight!,
          ].join(' · '),
          style: _inter(size: 12, color: _white.withOpacity(0.8)),
          overflow: TextOverflow.ellipsis,
        ),
      ]),
    );
  }

  // ── S1-required toggle (LP/RR-ops only, Fleet Status only) ────────────────────

  Widget _buildS1ToggleRow() {
    if (_isRecordsTrip || !_canManageRr) return const SizedBox.shrink();
    final required = _s1RequiredOverride ?? trip.s1Required;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      child: Row(children: [
        const Icon(Icons.badge_outlined, color: _rrBlue, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text('Allow FE to fill Stage 1',
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
    return InkWell(
      onTap: () => setState(() => _tripInfoExpanded = !_tripInfoExpanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(children: [
          const Icon(Icons.receipt_long_outlined, color: _rrBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Trip Info',
              style: _manrope(size: 13, weight: FontWeight.w700, color: _onSurface))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _doneBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Synced to RR',
                style: _inter(size: 11, weight: FontWeight.w600, color: _done)),
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

  // ── Step 1 expanded info ─────────────────────────────────────────────────────

  Widget _buildStep1Info() {
    return Container(
      color: const Color(0xFFF8FAFB),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Parties
        if (trip.consignorName != null || trip.consigneeName != null) ...[
          _InfoRow(icon: Icons.business_outlined, label: 'Consignor',
              value: trip.consignorName ?? '—'),
          if (trip.consignorGstin != null && trip.consignorGstin!.isNotEmpty)
            _InfoRow(icon: null, label: 'Consignor GSTIN', value: trip.consignorGstin!),
          _InfoRow(icon: Icons.business_center_outlined, label: 'Consignee',
              value: trip.consigneeName ?? '—'),
          if (trip.consigneeGstin != null && trip.consigneeGstin!.isNotEmpty)
            _InfoRow(icon: null, label: 'Consignee GSTIN', value: trip.consigneeGstin!),
          _Divider(),
        ],

        // Locations
        if (trip.pickupAddressLine1 != null || trip.pickupPin != null) ...[
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Pickup Address',
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
            label: 'Unload Address',
            value: [
              trip.unloadAddressLine1,
              trip.unloadAddressLine2,
              trip.unloadPin,
            ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
          ),
        ],
        if (trip.depotCode != null && trip.depotCode!.isNotEmpty)
          _InfoRow(icon: null, label: 'Depot Code', value: trip.depotCode!),
        _Divider(),

        // Material
        _InfoRow(icon: Icons.inventory_2_outlined, label: 'Material',
            value: trip.loadItem),
        if (trip.weight != null && trip.weight!.isNotEmpty)
          _InfoRow(icon: null, label: 'Weight', value: trip.weight!),
        if (trip.parcelDescription != null && trip.parcelDescription!.isNotEmpty)
          _InfoRow(icon: null, label: 'Description', value: trip.parcelDescription!),
        if (trip.invoiceValue != null)
          _InfoRow(icon: null, label: 'Total Invoice Value',
              value: '₹${trip.invoiceValue!.toStringAsFixed(0)}'),
        if (trip.partLoad == true)
          _InfoRow(icon: null, label: 'Part Load', value: 'Yes'),
        _Divider(),

        // Vehicle
        if (trip.vehicleNumber != null && trip.vehicleNumber!.isNotEmpty)
          _InfoRow(icon: Icons.local_shipping_outlined, label: 'Vehicle',
              value: trip.vehicleNumber!),
        if (trip.vehicleBodyType != null && trip.vehicleBodyType!.isNotEmpty)
          _InfoRow(icon: null, label: 'Body Type', value: trip.vehicleBodyType!),
        if (trip.axleType != null && trip.axleType!.isNotEmpty)
          _InfoRow(icon: null, label: 'Axle Type', value: trip.axleType!),
        if (trip.numberOfWheels != null)
          _InfoRow(icon: null, label: 'Wheels', value: '${trip.numberOfWheels}'),
        _Divider(),

        // Financials
        if (trip.expectedFreight != null)
          _InfoRow(icon: Icons.payments_outlined, label: 'Expected Freight',
              value: '₹${trip.expectedFreight!.toStringAsFixed(0)}'),
        _Divider(),

        // RR identifiers
        if (trip.rrTripNumber != null && trip.rrTripNumber!.isNotEmpty)
          _InfoRow(icon: Icons.tag_rounded, label: 'RR Trip Number',
              value: trip.rrTripNumber!),
        if (trip.rrBookingId != null && trip.rrBookingId!.isNotEmpty)
          _InfoRow(icon: null, label: 'RR Booking ID', value: trip.rrBookingId!),
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
