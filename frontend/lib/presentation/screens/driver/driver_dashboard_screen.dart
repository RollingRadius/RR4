import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/providers/location_tracking_provider.dart';
import 'package:fleet_management/data/services/location_service.dart' show LocationPermissionStatus;
import 'package:geolocator/geolocator.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/presentation/screens/trips/trip_detail_screen.dart';
// NOTE: driver dashboard is intentionally minimal + read-only for now —
// home, trip details (read-only), and logout only. Map/navigate and the
// quick-actions/stats/vehicle sections below are commented out, not
// deleted, so they're easy to bring back later.
// import 'package:fleet_management/presentation/screens/trips/trip_locate_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _primary = Color(0xFFEC5B13);
const _bg = Color(0xFFF8F6F6);
const _surface = Colors.white;
const _onSurface = Color(0xFF0F172A);
const _secondary = Color(0xFF64748B);
const _outline = Color(0xFFE2E8F0);

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

// ─── Screen ───────────────────────────────────────────────────────────────────

class DriverHomeDashboardScreen extends ConsumerStatefulWidget {
  const DriverHomeDashboardScreen({super.key});

  @override
  ConsumerState<DriverHomeDashboardScreen> createState() =>
      _DriverHomeDashboardScreenState();
}

class _DriverHomeDashboardScreenState extends ConsumerState<DriverHomeDashboardScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(tripProvider.notifier).loadTrips();
      await _ensureLocationPermissionAndTracking();
      await _syncTrackingToAssignment();
    });
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        await ref.read(tripProvider.notifier).silentRefresh();
        await _syncTrackingToAssignment();
      },
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Checks the REAL, live OS permission status on every login/dashboard
  /// load — not a locally-persisted "have we ever asked" flag. That flag-
  /// based design was wrong: it's scoped to the device/app-install, not the
  /// logged-in driver, so any earlier testing on the same device silently
  /// blocked the prompt for a genuinely new driver; and it never re-asked
  /// after a denial, or after Android's "Allow Once" (a temporary grant
  /// that Android itself automatically reverts once the app is fully closed
  /// and reopened — checking live status here means that reversion is
  /// picked up for free, no extra tracking needed).
  ///
  /// - Already granted persistently (whileInUse/always) → no prompt, just
  ///   make sure tracking is enabled server-side.
  /// - Not currently granted (denied, or deniedForever) → (re-)prompt every
  ///   login. For deniedForever, Android itself won't show its dialog again
  ///   (nothing we can do about that here — requestPermission() harmlessly
  ///   no-ops), so this isn't a nag loop, just an honest re-check.
  Future<void> _ensureLocationPermissionAndTracking() async {
    if (!mounted) return;
    final notifier = ref.read(locationTrackingProvider.notifier);
    await notifier.checkPermission();
    if (!mounted) return;

    final status = ref.read(locationTrackingProvider).permissionStatus;
    if (status == LocationPermissionStatus.whileInUse ||
        status == LocationPermissionStatus.always) {
      await notifier.selfEnableTracking();
      return;
    }

    // Not currently granted — ask again (fresh denial, first-ever login, or
    // a since-reverted "Allow Once"). The OS permission dialog is a long,
    // user-interruptible pause — the driver can background the app or nav
    // away before answering it, disposing this widget mid-await — recheck
    // `mounted` before touching `ref` again afterward.
    final granted = await notifier.requestPermission();
    if (!mounted) return;
    if (granted) {
      await notifier.selfEnableTracking();
    }
  }

  Future<void> _syncTrackingToAssignment() async {
    if (!mounted) return;
    await syncDriverTrackingToActiveTrip(ref);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _initials(String? fullName, String? username) {
    final name = (fullName?.isNotEmpty == true) ? fullName! : (username ?? '');
    final parts = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return 'D';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final tripState = ref.watch(tripProvider);
    final firstName = ((user?.fullName?.isNotEmpty == true)
            ? user!.fullName!.split(' ').first
            : user?.username) ??
        'Driver';

    final ongoingTrip =
        tripState.trips.where((t) => t.isOngoing).firstOrNull;
    // Stats/vehicle/quick-actions sections are commented out below for now
    // (minimal + read-only dashboard) — these are unused until re-enabled.
    // final completedCount =
    //     tripState.trips.where((t) => t.isCompleted).length;
    // final totalToday = tripState.trips.length;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Sticky header ─────────────────────────────────────────────────
          _Header(
            initials: _initials(user?.fullName, user?.username),
            greeting: _greeting(),
            name: firstName,
          ),
          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: () =>
                  ref.read(tripProvider.notifier).loadTrips(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active trip
                    if (tripState.isLoading)
                      const _ActiveTripShimmer()
                    else if (ongoingTrip != null)
                      _ActiveTripCard(trip: ongoingTrip)
                    else
                      const _NoActiveTripCard(),

                    // Stats / vehicle card / quick actions — commented out
                    // for now, keeping the driver dashboard minimal +
                    // read-only. Uncomment to bring these back.
                    //
                    // const SizedBox(height: 20),
                    // _StatsRow(
                    //     totalToday: totalToday,
                    //     completed: completedCount),
                    //
                    // const SizedBox(height: 20),
                    // if (ongoingTrip?.hasVehicle == true) ...[
                    //   _SectionLabel(label: 'Assigned Vehicle'),
                    //   const SizedBox(height: 12),
                    //   _VehicleCard(trip: ongoingTrip!),
                    //   const SizedBox(height: 20),
                    // ],
                    //
                    // _SectionLabel(label: 'Quick Actions'),
                    // const SizedBox(height: 12),
                    // const _QuickActionsGrid(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String initials;
  final String greeting;
  final String name;

  const _Header({
    required this.initials,
    required this.greeting,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFEC5B13), Color(0xFFBF4209)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                  color: _primary.withValues(alpha: 0.25), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: _manrope(
                    size: 16,
                    weight: FontWeight.w800,
                    color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: _inter(size: 12, weight: FontWeight.w500)),
                Text(name,
                    style: _manrope(size: 19, weight: FontWeight.w800)),
              ],
            ),
          ),
          _LocationPermissionToggle(),
          const SizedBox(width: 8),
          // Logout (driver dashboard is minimal — no notifications/settings for now)
          _LogoutButton(),
        ],
      ),
    );
  }
}

// ─── Location permission toggle ────────────────────────────────────────────────
//
// A pure status readout, not an independent on/off switch — it never grants
// or revokes permission itself. Tapping it either triggers the real OS
// permission prompt (if not yet permanently denied) or deep-links straight to
// the phone's settings screen (if it is) — Android itself won't show its own
// dialog again once a driver has permanently denied, so that's the only
// recovery path left. This also means a driver can't casually one-tap-disable
// tracking mid-trip from inside the app.
class _LocationPermissionToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(locationTrackingProvider).permissionStatus;
    final granted = status == LocationPermissionStatus.always ||
        status == LocationPermissionStatus.whileInUse;

    return GestureDetector(
      onTap: granted
          ? null
          : () async {
              if (status == LocationPermissionStatus.deniedForever) {
                await Geolocator.openAppSettings();
              } else if (status == LocationPermissionStatus.serviceDisabled) {
                await Geolocator.openLocationSettings();
              } else {
                await ref.read(locationTrackingProvider.notifier).requestPermission();
              }
              await ref.read(locationTrackingProvider.notifier).checkPermission();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: granted ? const Color(0xFFDCFCE7) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              granted ? Icons.location_on_rounded : Icons.location_off_rounded,
              size: 14,
              color: granted ? const Color(0xFF15803D) : const Color(0xFFC62828),
            ),
            const SizedBox(width: 4),
            Text(
              granted ? 'Tracking On' : 'Tap to Enable',
              style: _inter(
                size: 10,
                weight: FontWeight.w700,
                color: granted ? const Color(0xFF15803D) : const Color(0xFFC62828),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Logout button ────────────────────────────────────────────────────────────

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.logout_rounded, color: _onSurface, size: 20),
      ),
      onPressed: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go(AppConstants.routeLogin);
      },
    );
  }
}

// ─── Active trip card ─────────────────────────────────────────────────────────

class _ActiveTripCard extends ConsumerStatefulWidget {
  final TripModel trip;
  const _ActiveTripCard({required this.trip});

  @override
  ConsumerState<_ActiveTripCard> createState() => _ActiveTripCardState();
}

class _ActiveTripCardState extends ConsumerState<_ActiveTripCard> {
  // "Navigate" (live map) is commented out for now — driver dashboard is
  // minimal + read-only, Details is the only action. Uncomment along with
  // the trip_locate_screen.dart import above to bring it back.
  //
  // bool _locating = false;
  //
  // Future<void> _locate() async {
  //   setState(() => _locating = true);
  //   final loc = await ref
  //       .read(tripProvider.notifier)
  //       .fetchTripLocation(widget.trip.id);
  //   if (!mounted) return;
  //   setState(() => _locating = false);
  //   Navigator.of(context).push(MaterialPageRoute(
  //     builder: (_) =>
  //         TripLocateScreen(trip: widget.trip, location: loc),
  //   ));
  // }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Map gradient header ──────────────────────────────────────────
          Container(
            height: 130,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF2D6A9F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Grid pattern overlay (map-like)
                CustomPaint(
                  size: const Size(double.infinity, 130),
                  painter: _MapGridPainter(),
                ),
                // Content overlay
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('ACTIVE TRIP',
                                style: _inter(
                                    size: 9,
                                    weight: FontWeight.w800,
                                    color: Colors.white)
                                    .copyWith(letterSpacing: 1.0)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Progress',
                                  style: _inter(
                                      size: 10,
                                      color: Colors.white
                                          .withValues(alpha: 0.7))),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 80,
                                height: 6,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: 0.65,
                                    backgroundColor: Colors.white
                                        .withValues(alpha: 0.25),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            _primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(trip.destination,
                          style: _manrope(
                              size: 18,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                      if (trip.destinationSub != null)
                        Text(trip.destinationSub!,
                            style: _inter(
                                size: 11,
                                color: Colors.white
                                    .withValues(alpha: 0.75))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Trip details ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route row
                Row(
                  children: [
                    _RouteDot(filled: true, color: _primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FROM',
                              style: _inter(
                                  size: 9,
                                  weight: FontWeight.w700,
                                  color: _secondary)
                                  .copyWith(letterSpacing: 0.8)),
                          Text(trip.origin,
                              style: _manrope(
                                  size: 13, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: _secondary),
                    const SizedBox(width: 10),
                    _RouteDot(filled: false, color: _secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TO',
                              style: _inter(
                                  size: 9,
                                  weight: FontWeight.w700,
                                  color: _secondary)
                                  .copyWith(letterSpacing: 0.8)),
                          Text(trip.destination,
                              style: _manrope(
                                  size: 13, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Trip chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(
                        icon: Icons.tag_rounded,
                        label: trip.tripNumber),
                    if (trip.loadItem.isNotEmpty)
                      _Chip(
                          icon: Icons.inventory_2_outlined,
                          label: trip.loadItem),
                    if (trip.weight != null)
                      _Chip(
                          icon: Icons.scale_outlined,
                          label: trip.weight!),
                  ],
                ),
                const SizedBox(height: 14),
                // Action buttons — Details only, read-only (no entering
                // trip stages). "Navigate" is commented out for now, see
                // _ActiveTripCardState above.
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TripDetailScreen(trip: trip, readOnly: true),
                      ),
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side:
                          BorderSide(color: _primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No active trip placeholder ───────────────────────────────────────────────

class _NoActiveTripCard extends StatelessWidget {
  const _NoActiveTripCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_outlined,
                color: _primary, size: 30),
          ),
          const SizedBox(height: 14),
          Text('No Active Trip',
              style: _manrope(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('You have no ongoing trips right now.',
              style: _inter(size: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Active trip shimmer ──────────────────────────────────────────────────────

class _ActiveTripShimmer extends StatelessWidget {
  const _ActiveTripShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF2),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int totalToday;
  final int completed;

  const _StatsRow({required this.totalToday, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "Today's Load",
            value: '$totalToday',
            unit: 'Trips Total',
            accentLeft: false,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            label: 'Progress',
            value: '$completed',
            unit: 'Completed',
            accentLeft: true,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool accentLeft;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.accentLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: accentLeft
              ? BorderSide(
                  color: _primary.withValues(alpha: 0.45), width: 4)
              : const BorderSide(color: _outline),
          top: const BorderSide(color: _outline),
          right: const BorderSide(color: _outline),
          bottom: const BorderSide(color: _outline),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: _inter(
                  size: 10, weight: FontWeight.w700, color: _secondary)
                  .copyWith(letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style:
                      _manrope(size: 28, weight: FontWeight.w800)),
              const SizedBox(width: 5),
              Text(unit, style: _inter(size: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Vehicle card ─────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final TripModel trip;
  const _VehicleCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: _primary, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.vehiclePlate ?? 'Vehicle',
                        style: _manrope(
                            size: 16, weight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('In Service',
                          style: _inter(
                              size: 10,
                              weight: FontWeight.w700,
                              color: const Color(0xFF15803D))),
                    ),
                  ],
                ),
                if (trip.vehicleModel != null) ...[
                  const SizedBox(height: 2),
                  Text(trip.vehicleModel!,
                      style: _inter(size: 12)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_gas_station_outlined,
                        size: 14, color: _primary),
                    const SizedBox(width: 4),
                    Text('Assigned',
                        style: _inter(
                            size: 12,
                            weight: FontWeight.w600,
                            color: _onSurface)),
                    const SizedBox(width: 16),
                    const Icon(Icons.route_outlined,
                        size: 14, color: _secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${trip.origin} → ${trip.destination}',
                        style: _inter(size: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick actions grid ───────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    const actions = [
      _ActionItem(
        icon: Icons.report_problem_outlined,
        label: 'Report\nIssue',
        bg: Color(0xFFFFEDED),
        fg: Color(0xFFDC2626),
      ),
      _ActionItem(
        icon: Icons.receipt_long_outlined,
        label: 'Fuel\nReceipt',
        bg: Color(0xFFFFF3E8),
        fg: _primary,
      ),
      _ActionItem(
        icon: Icons.checklist_rounded,
        label: 'Safety\nCheck',
        bg: Color(0xFFF0FDF4),
        fg: Color(0xFF16A34A),
      ),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _QuickActionButton(action: action, context: context),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });
}

class _QuickActionButton extends StatelessWidget {
  final _ActionItem action;
  final BuildContext context;

  const _QuickActionButton(
      {required this.action, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('${action.label.replaceAll('\n', ' ')} — coming soon'),
          duration: const Duration(seconds: 2),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.fg, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: _inter(
                  size: 10,
                  weight: FontWeight.w700,
                  color: _onSurface)
                  .copyWith(letterSpacing: 0.3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: _inter(size: 11, weight: FontWeight.w700, color: _secondary)
          .copyWith(letterSpacing: 1.2),
    );
  }
}

// ─── Route dot ────────────────────────────────────────────────────────────────

class _RouteDot extends StatelessWidget {
  final bool filled;
  final Color color;

  const _RouteDot({required this.filled, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: filled ? null : Border.all(color: color, width: 2),
      ),
    );
  }
}

// ─── Info chip ────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _secondary),
          const SizedBox(width: 5),
          Text(label,
              style: _inter(
                  size: 11, weight: FontWeight.w600, color: _onSurface)),
        ],
      ),
    );
  }
}

// ─── Map grid painter (decorative) ───────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Road-like diagonal line
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height),
      Offset(size.width * 0.6, 0),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, size.height),
      Offset(size.width, size.height * 0.2),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
