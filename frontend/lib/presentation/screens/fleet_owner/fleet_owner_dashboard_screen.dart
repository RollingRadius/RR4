import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/vehicle_provider.dart';
import 'package:fleet_management/presentation/screens/fleet_owner/vehicle_management_screen.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/presentation/widgets/ongoing_trip_card.dart';

// ─── Typography ───────────────────────────────────────────────────────────────
TextStyle _manrope({
  double size = 14,
  FontWeight weight = FontWeight.w600,
  Color color = const Color(0xFF191C1E),
}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = const Color(0xFF546067),
}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

// ─── Colour tokens ────────────────────────────────────────────────────────────
const _primary = Color(0xFFFF6B00);
const _background = Color(0xFFF8F9FB);
const _surfaceLowest = Color(0xFFFFFFFF);
const _surfaceContainer = Color(0xFFECEEF0);
const _surfaceContainerLow = Color(0xFFF2F4F6);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _tertiary = Color(0xFF006B5E);
const _tertiaryContainer = Color(0xFF4AA898);
const _error = Color(0xFFBA1A1A);
const _errorContainer = Color(0xFFFFDAD6);
const _secondaryContainer = Color(0xFFD7E4EC);

// ─── Main screen ──────────────────────────────────────────────────────────────

class FleetOwnerDashboardScreen extends ConsumerStatefulWidget {
  const FleetOwnerDashboardScreen({super.key});

  @override
  ConsumerState<FleetOwnerDashboardScreen> createState() =>
      _FleetOwnerDashboardScreenState();
}

class _FleetOwnerDashboardScreenState
    extends ConsumerState<FleetOwnerDashboardScreen> {
  int _navIndex = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(vehicleProvider.notifier).loadVehicles();
      ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing');
    });
    // Real-time: silent background refresh every 30 s (no loading shimmer)
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing');
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final initials = _initials(user?.fullName ?? 'FO');

    final pages = [
      const _DashboardTab(),
      const _FleetTab(),
      const _AvailableLoadsTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: Column(
        children: [
          _TopBar(initials: initials),
          Expanded(
            child: IndexedStack(index: _navIndex, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : 'FO';
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String initials;
  const _TopBar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: _background,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.menu, color: _secondary, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'RR LOGISTICS',
                style: _manrope(
                  size: 18,
                  weight: FontWeight.w900,
                  color: _primary,
                ).copyWith(letterSpacing: 1.0),
              ),
            ),
            const Icon(Icons.notifications_outlined,
                color: _secondary, size: 24),
            const SizedBox(width: 12),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A2E44),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: _manrope(
                      size: 12, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    (Icons.dashboard_rounded, 'DASHBOARD'),
    (Icons.local_shipping_rounded, 'FLEET'),
    (Icons.search_rounded, 'LOADS'),
    (Icons.person_outline, 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceLowest.withValues(alpha: 0.82),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.6), width: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  final (icon, label) = _items[i];
                  final active = i == selectedIndex;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: active
                          ? const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8)
                          : const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: active ? _primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon,
                              color:
                                  active ? Colors.white : _secondary,
                              size: 22),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            style: _inter(
                              size: 9,
                              weight: FontWeight.w700,
                              color: active ? Colors.white : _secondary,
                            ).copyWith(letterSpacing: 0.6),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleState = ref.watch(vehicleProvider);
    final tripState = ref.watch(tripProvider);
    final user = ref.watch(authProvider).user;
    final firstName = user?.fullName.split(' ').first ?? 'Manager';

    final vehicles = vehicleState.vehicles;
    final ongoingTrips = tripState.ongoingTrips;
    final total = vehicles.length;
    final active =
        vehicles.where((v) => v['status'] == 'active').length;
    final maintenance =
        vehicles.where((v) => v['status'] == 'maintenance').length;
    final inactive =
        vehicles.where((v) => v['status'] == 'inactive').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Welcome back, $firstName',
            style: _manrope(size: 22, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text('Here\'s your fleet summary',
              style: _inter(size: 13, color: _secondary)),
          const SizedBox(height: 20),

          // Search New Loads — primary CTA
          _SearchLoadsButton(),
          const SizedBox(height: 12),

          // Manage Vehicles — secondary CTA
          _ManageVehiclesButton(),
          const SizedBox(height: 24),

          // KPI grid
          _KpiGrid(
              total: total,
              active: active,
              maintenance: maintenance,
              inactive: inactive),
          const SizedBox(height: 24),

          // ── Fleet Status — ongoing trips with Locate button ──────────
          _FleetStatusHeader(
            tripCount: ongoingTrips.length,
            isLive: !tripState.isLoading,
          ),
          const SizedBox(height: 12),
          if (tripState.isLoading && ongoingTrips.isEmpty)
            _TripLoadingShimmer()
          else if (ongoingTrips.isEmpty)
            _EmptyTrips()
          else
            ...ongoingTrips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: OngoingTripCard(trip: t),
              ),
            ),
          const SizedBox(height: 24),

          // Vehicle summary (compact, below trips)
          if (vehicles.isNotEmpty) ...[
            Text('Vehicles',
                style: _manrope(size: 15, weight: FontWeight.w700,
                    color: _secondary)),
            const SizedBox(height: 10),
            _VehicleList(vehicles: vehicles.take(3).toList()),
            const SizedBox(height: 24),
          ],

          _RecentActivity(),
        ],
      ),
    );
  }
}

// ─── Search New Loads Button (primary CTA) ────────────────────────────────────

class _SearchLoadsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/fleet-owner/available-loads'),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFE55C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search New Loads',
                    style: _manrope(
                        size: 16,
                        weight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Browse available load requirements',
                    style: _inter(
                        size: 12, color: Colors.white.withValues(alpha: 0.80)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Manage Vehicles Button ───────────────────────────────────────────────────

class _ManageVehiclesButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const VehicleManagementScreen()),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _surfaceLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: _primary.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.local_shipping_rounded, color: _primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Vehicles',
                    style: _manrope(
                        size: 15,
                        weight: FontWeight.w800,
                        color: _onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '11 capabilities — view, add, assign & more',
                    style: _inter(size: 12, color: _secondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: _secondary, size: 15),
          ],
        ),
      ),
    );
  }
}

// ─── KPI Grid ─────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final int total, active, maintenance, inactive;
  const _KpiGrid({
    required this.total,
    required this.active,
    required this.maintenance,
    required this.inactive,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: [
        _KpiCard(
            label: 'TOTAL VEHICLES',
            value: '$total',
            accent: _primary),
        _KpiCard(
            label: 'ACTIVE',
            value: '$active',
            accent: _tertiary),
        _KpiCard(
            label: 'MAINTENANCE',
            value: '$maintenance',
            accent: _error,
            showWarning: maintenance > 0),
        _KpiCard(
            label: 'INACTIVE',
            value: '$inactive',
            accent: const Color(0xFFBBC8D0)),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final Color accent;
  final bool showWarning;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.accent,
    this.showWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 4)),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: _inter(size: 9, weight: FontWeight.w700, color: _secondary)
                .copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                value,
                style: _manrope(
                    size: 32, weight: FontWeight.w800, color: _onSurface)
                    .copyWith(height: 1.0),
              ),
              if (showWarning) ...[
                const SizedBox(width: 6),
                const Icon(Icons.warning_rounded, color: _error, size: 18),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Vehicle List ─────────────────────────────────────────────────────────────

class _VehicleList extends StatelessWidget {
  final List<Map<String, dynamic>> vehicles;
  const _VehicleList({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: vehicles
          .map((v) => _VehicleCard(vehicle: v))
          .toList(),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  const _VehicleCard({required this.vehicle});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return _tertiary;
      case 'maintenance':
        return _error;
      default:
        return _secondary;
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'active':
        return _tertiaryContainer.withValues(alpha: 0.12);
      case 'maintenance':
        return _errorContainer;
      default:
        return _surfaceContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = vehicle['registration'] as String? ?? '—';
    final status = vehicle['status'] as String? ?? 'inactive';
    final type = vehicle['type'] as String? ?? 'truck';
    final driver = vehicle['driver'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconForType(type), color: _secondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reg,
                    style:
                        _manrope(size: 14, weight: FontWeight.w700)),
                if (driver != null)
                  Text(driver,
                      style: _inter(size: 12, color: _secondary)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusBg(status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: _inter(
                      size: 9,
                      weight: FontWeight.w700,
                      color: _statusColor(status))
                  .copyWith(letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'van':
        return Icons.airport_shuttle_rounded;
      case 'motorcycle':
        return Icons.two_wheeler_rounded;
      default:
        return Icons.local_shipping_rounded;
    }
  }
}

class _EmptyFleet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping_outlined,
                color: _secondary, size: 40),
            const SizedBox(height: 8),
            Text('No vehicles added yet',
                style: _inter(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _secondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Fleet Status Header ──────────────────────────────────────────────────────

class _FleetStatusHeader extends ConsumerWidget {
  final int tripCount;
  final bool isLive;
  const _FleetStatusHeader({required this.tripCount, required this.isLive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastUpdated = ref.watch(tripProvider).lastUpdated;
    final updatedStr = lastUpdated != null
        ? _fmt(lastUpdated)
        : null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fleet Status',
                  style: _manrope(size: 17, weight: FontWeight.w800)),
              Text(
                tripCount == 0
                    ? 'No active trips'
                    : '$tripCount trip${tripCount == 1 ? '' : 's'} in transit'
                        '${updatedStr != null ? ' · $updatedStr' : ''}',
                style: _inter(size: 12),
              ),
            ],
          ),
        ),
        if (isLive)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF22C55E)),
                ),
                const SizedBox(width: 5),
                Text('LIVE',
                    style: _inter(
                            size: 9,
                            weight: FontWeight.w800,
                            color: Color(0xFF2E7D32))
                        .copyWith(letterSpacing: 0.8)),
              ],
            ),
          ),
      ],
    );
  }
}

String _fmt(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return 'updated $h:$m';
}

// ─── Empty trips state ────────────────────────────────────────────────────────

class _EmptyTrips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _surfaceContainer, width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_rounded, color: _secondary, size: 40),
            const SizedBox(height: 8),
            Text('No ongoing trips',
                style: _inter(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _secondary)),
            const SizedBox(height: 4),
            Text('Create a trip to track it here in real time',
                style: _inter(size: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── Loading shimmer ──────────────────────────────────────────────────────────

class _TripLoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: _surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Recent Activity ──────────────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const activities = [
      (Icons.check_circle_outline_rounded, _tertiary,
          'Vehicle MH-12-AB-1234 completed trip', '2h ago'),
      (Icons.warning_amber_rounded, _error,
          'Maintenance due for RJ14-GB-9821', '4h ago'),
      (Icons.local_shipping_rounded, _primary,
          'New load matched for your fleet', '6h ago'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity',
            style: _manrope(size: 17, weight: FontWeight.w800)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _surfaceLowest,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8),
            ],
          ),
          child: Column(
            children: List.generate(activities.length, (i) {
              final (icon, color, title, time) = activities[i];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(title,
                              style: _inter(
                                  size: 13,
                                  weight: FontWeight.w500,
                                  color: _onSurface)),
                        ),
                        Text(time,
                            style:
                                _inter(size: 11, color: _secondary)),
                      ],
                    ),
                  ),
                  if (i < activities.length - 1)
                    const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFECEEF0)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Fleet Tab ────────────────────────────────────────────────────────────────

class _FleetTab extends ConsumerWidget {
  const _FleetTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehicleProvider).vehicles;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Fleet',
                  style: _manrope(size: 20, weight: FontWeight.w800)),
              TextButton.icon(
                onPressed: () => context.push('/vehicles/add'),
                icon: const Icon(Icons.add, size: 18, color: _primary),
                label: Text('Add Vehicle',
                    style: _inter(
                        size: 13,
                        weight: FontWeight.w700,
                        color: _primary)),
              ),
            ],
          ),
        ),
        Expanded(
          child: vehicles.isEmpty
              ? Center(child: _EmptyFleet())
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: vehicles.length,
                  itemBuilder: (_, i) =>
                      _VehicleCard(vehicle: vehicles[i]),
                ),
        ),
      ],
    );
  }
}

// ─── Available Loads Tab ──────────────────────────────────────────────────────

class _AvailableLoadsTab extends StatelessWidget {
  const _AvailableLoadsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.search_rounded, size: 52, color: _primary),
            ),
            const SizedBox(height: 20),
            Text('Available Loads',
                style: _manrope(size: 22, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Browse load requirements posted\nby load owners and bid for them.',
              textAlign: TextAlign.center,
              style: _inter(size: 14, color: _secondary),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Browse Loads'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
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
      ),
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFF1A2E44),
            child: Text(
              _initials(user?.fullName ?? 'FO'),
              style: _manrope(
                  size: 28, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? '—',
              style: _manrope(size: 20, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(user?.email ?? '—',
              style: _inter(size: 14, color: _secondary)),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Fleet Owner',
                style: _inter(
                    size: 12,
                    weight: FontWeight.w700,
                    color: _primary)),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: _secondary),
            title: Text('Settings',
                style: _inter(
                    size: 15,
                    weight: FontWeight.w600,
                    color: _onSurface)),
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: _error),
            title: Text('Logout',
                style: _inter(
                    size: 15,
                    weight: FontWeight.w600,
                    color: _error)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
