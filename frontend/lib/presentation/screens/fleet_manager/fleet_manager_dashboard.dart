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
import 'package:fleet_management/providers/available_loads_provider.dart';
import 'package:fleet_management/data/models/load_requirement_model.dart';
import 'package:fleet_management/presentation/widgets/ongoing_trip_card.dart';
import 'package:fleet_management/presentation/screens/fleet_owner/trip_stages_screen.dart';

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

class FleetManagerDashboard extends ConsumerStatefulWidget {
  const FleetManagerDashboard({super.key});

  @override
  ConsumerState<FleetManagerDashboard> createState() =>
      _FleetManagerDashboardState();
}

class _FleetManagerDashboardState
    extends ConsumerState<FleetManagerDashboard> {
  int _navIndex = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(vehicleProvider.notifier).loadVehicles();
      ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing');
      ref.read(availableLoadsProvider.notifier).loadAvailableLoads();
    });
    // Silent background refresh every 30 s
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing');
        ref.read(availableLoadsProvider.notifier).silentRefresh();
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
    final pendingLoadsCount = ref.watch(availableLoadsProvider).loads.length;

    final pages = [
      _DashboardTab(onViewLoads: () => setState(() => _navIndex = 2)),
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
        pendingLoadsCount: pendingLoadsCount,
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
  final int pendingLoadsCount;
  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
    this.pendingLoadsCount = 0,
  });

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
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(icon,
                                  color: active ? Colors.white : _secondary,
                                  size: 22),
                              // Badge on LOADS tab (index 2)
                              if (i == 2 && pendingLoadsCount > 0)
                                Positioned(
                                  right: -6,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pendingLoadsCount > 99
                                          ? '99+'
                                          : '$pendingLoadsCount',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
  final VoidCallback onViewLoads;
  const _DashboardTab({required this.onViewLoads});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleState = ref.watch(vehicleProvider);
    final tripState = ref.watch(tripProvider);
    final loadsState = ref.watch(availableLoadsProvider);
    final user = ref.watch(authProvider).user;
    final firstName = user?.fullName.split(' ').first ?? 'Fleet Manager';

    final vehicles = vehicleState.vehicles;
    final ongoingTrips = tripState.ongoingTrips;
    final pendingLoads = loadsState.loads;
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
          Text('Fleet Management Panel',
              style: _inter(size: 13, color: _secondary)),
          const SizedBox(height: 16),

          // ── Pending loads alert banner ───────────────────────────────
          if (pendingLoads.isNotEmpty)
            _PendingLoadsBanner(
              count: pendingLoads.length,
              loads: pendingLoads.take(2).toList(),
              onViewAll: onViewLoads,
            ),
          if (pendingLoads.isNotEmpty) const SizedBox(height: 16),

          // Search New Loads — primary CTA
          _SearchLoadsButton(onTap: onViewLoads),
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

// ─── Pending Loads Alert Banner ───────────────────────────────────────────────

class _PendingLoadsBanner extends StatelessWidget {
  final int count;
  final List<LoadRequirementModel> loads;
  final VoidCallback onViewAll;
  const _PendingLoadsBanner({
    required this.count,
    required this.loads,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFF6B00), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_shipping_outlined,
                color: Color(0xFFFF6B00), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count new load ${count == 1 ? 'requirement' : 'requirements'} available',
                style: _inter(
                    size: 13,
                    weight: FontWeight.w600,
                    color: const Color(0xFF7A3200)),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFFFF6B00), size: 14),
          ],
        ),
      ),
    );
  }
}

// ─── Search New Loads Button (primary CTA) ────────────────────────────────────

class _SearchLoadsButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _SearchLoadsButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/fleet-manager/available-loads'),
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

class _AvailableLoadsTab extends ConsumerStatefulWidget {
  const _AvailableLoadsTab();

  @override
  ConsumerState<_AvailableLoadsTab> createState() => _AvailableLoadsTabState();
}

class _AvailableLoadsTabState extends ConsumerState<_AvailableLoadsTab> {
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(availableLoadsProvider.notifier).loadAvailableLoads());
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(availableLoadsProvider.notifier).loadAvailableLoads(
          pickup: _pickupCtrl.text.trim(),
          drop: _dropCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(availableLoadsProvider);

    return Column(
      children: [
        // ── Search bar ─────────────────────────────────────────────────
        Container(
          color: _background,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search Loads',
                  style: _manrope(size: 20, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Browse pending requirements from load owners',
                  style: _inter(size: 12, color: _secondary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SearchField(
                      controller: _pickupCtrl,
                      hint: 'Pickup city…',
                      icon: Icons.trip_origin_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SearchField(
                      controller: _dropCtrl,
                      hint: 'Drop city…',
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _search,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Results ────────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _primary))
              : state.error != null
                  ? _LoadsError(message: state.error!)
                  : state.loads.isEmpty
                      ? _LoadsEmpty()
                      : RefreshIndicator(
                          color: _primary,
                          onRefresh: () => ref
                              .read(availableLoadsProvider.notifier)
                              .loadAvailableLoads(
                                pickup: _pickupCtrl.text.trim(),
                                drop: _dropCtrl.text.trim(),
                              ),
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: state.loads.length,
                            itemBuilder: (_, i) => _AvailableLoadCard(
                              load: state.loads[i],
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _SearchField(
      {required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: _inter(size: 13, color: const Color(0xFF191C1E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _inter(size: 13),
        prefixIcon: Icon(icon, size: 16, color: _secondary),
        filled: true,
        fillColor: _surfaceLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _surfaceContainer),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _surfaceContainer),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Available Load Card ───────────────────────────────────────────────────────

class _AvailableLoadCard extends ConsumerWidget {
  final LoadRequirementModel load;
  const _AvailableLoadCard({required this.load});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFulfilling = ref.watch(availableLoadsProvider).isFulfilling;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ref ID + company name
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            load.refId,
                            style: _manrope(
                                size: 13,
                                weight: FontWeight.w800,
                                color: const Color(0xFF001e40)),
                          ),
                          if (load.companyName != null)
                            Text(
                              load.companyName!,
                              style: _inter(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: _secondary),
                            ),
                          if (load.companyCity != null ||
                              load.companyState != null)
                            Text(
                              [
                                if (load.companyCity != null) load.companyCity!,
                                if (load.companyState != null)
                                  load.companyState!,
                              ].join(', '),
                              style: _inter(size: 11, color: _secondary),
                            ),
                        ],
                      ),
                    ),
                    _LoadStatusChip(status: load.status),
                  ],
                ),
                const SizedBox(height: 14),

                // Route
                _RouteRow(
                    pickup: load.pickupLocation ?? '—',
                    drop: load.unloadLocation ?? '—'),
                const SizedBox(height: 14),

                // Trucks needed — highlighted row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _primary.withValues(alpha: 0.20), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping_outlined,
                          size: 15, color: _primary),
                      const SizedBox(width: 7),
                      Text(
                        'Trucks Needed: ',
                        style: _inter(
                            size: 12,
                            weight: FontWeight.w500,
                            color: const Color(0xFF7A3200)),
                      ),
                      Text(
                        '${load.truckCount}',
                        style: _manrope(
                            size: 14,
                            weight: FontWeight.w800,
                            color: _primary),
                      ),
                      Text(
                        ' truck${load.truckCount == 1 ? '' : 's'}',
                        style: _inter(
                            size: 12,
                            weight: FontWeight.w600,
                            color: const Color(0xFF7A3200)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Specs chips
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    if (load.materialType != null)
                      _SpecChip(
                          icon: Icons.inventory_2_outlined,
                          label: load.materialType!),
                    if (load.capacity != null)
                      _SpecChip(
                          icon: Icons.scale_outlined,
                          label: load.capacity!),
                    if (load.axelType != null)
                      _SpecChip(
                          icon: Icons.settings_outlined,
                          label: load.axelType!),
                    if (load.bodyType != null)
                      _SpecChip(
                          icon: Icons.category_outlined,
                          label: load.bodyType!),
                    if (load.entryDate != null)
                      _SpecChip(
                          icon: Icons.calendar_today_outlined,
                          label: load.entryDate!),
                  ],
                ),
              ],
            ),
          ),

          // Divider + Fulfill button
          Divider(
              height: 1,
              color: _surfaceContainer.withValues(alpha: 0.7),
              indent: 16,
              endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: isFulfilling
                    ? null
                    : () => _showFulfillSheet(context, ref, load),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFE55C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: _primary.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Fulfill This Load',
                        style: _manrope(
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFulfillSheet(
      BuildContext context, WidgetRef ref, LoadRequirementModel load) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FulfillSheet(load: load),
    );
  }
}

// ── Route row ─────────────────────────────────────────────────────────────────

class _RouteRow extends StatelessWidget {
  final String pickup, drop;
  const _RouteRow({required this.pickup, required this.drop});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: _primary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(pickup,
              style: _manrope(
                  size: 13, weight: FontWeight.w700,
                  color: const Color(0xFF001e40)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded, size: 14, color: _secondary),
        ),
        Expanded(
          child: Text(drop,
              style: _manrope(
                  size: 13, weight: FontWeight.w700,
                  color: const Color(0xFF001e40)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

// ── Spec chip ─────────────────────────────────────────────────────────────────

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _secondary),
          const SizedBox(width: 5),
          Text(label,
              style:
                  _inter(size: 11, weight: FontWeight.w600, color: _secondary)),
        ],
      ),
    );
  }
}

// ── Load status chip ──────────────────────────────────────────────────────────

class _LoadStatusChip extends StatelessWidget {
  final String status;
  const _LoadStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'matched' => (
          'MATCHED',
          const Color(0xFFD5E3FC),
          const Color(0xFF0D47A1)
        ),
      'fulfilled' => ('DONE', const Color(0xFFECEEF0), _secondary),
      'cancelled' => (
          'CANCELLED',
          const Color(0xFFFFDAD6),
          const Color(0xFFBA1A1A)
        ),
      _ => ('PENDING', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: _inter(size: 9, weight: FontWeight.w700, color: fg)
              .copyWith(letterSpacing: 0.8)),
    );
  }
}

// ── Fulfill bottom sheet ──────────────────────────────────────────────────────

class _FulfillSheet extends ConsumerStatefulWidget {
  final LoadRequirementModel load;
  const _FulfillSheet({required this.load});

  @override
  ConsumerState<_FulfillSheet> createState() => _FulfillSheetState();
}

class _FulfillSheetState extends ConsumerState<_FulfillSheet> {
  String? _selectedVehicleId;
  String? _selectedDriverId;

  Future<void> _confirm() async {
    final trip = await ref.read(availableLoadsProvider.notifier).fulfillLoad(
          widget.load.id,
          vehicleId: _selectedVehicleId,
          driverId: _selectedDriverId,
        );

    if (!mounted) return;
    Navigator.of(context).pop(); // close bottom sheet

    if (trip != null) {
      // Navigate directly into the 3-stage compliance flow
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TripStagesScreen(trip: trip),
        ),
      );
    } else {
      final err = ref.read(availableLoadsProvider).error ?? 'Fulfillment failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err,
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleProvider).vehicles;
    final isBusy = ref.watch(availableLoadsProvider).isFulfilling;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: _surfaceContainer,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Text('Fulfill Load Requirement',
              style: _manrope(size: 18, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${widget.load.refId} · ${widget.load.pickupLocation ?? '—'} → ${widget.load.unloadLocation ?? '—'}',
              style: _inter(size: 12, color: _secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 24),

          // Truck count info
          _InfoRow(
            icon: Icons.local_shipping_rounded,
            label: 'Trucks Needed',
            value: '${widget.load.truckCount}',
          ),
          if (widget.load.materialType != null)
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Material',
              value: widget.load.materialType!,
            ),
          if (widget.load.capacity != null)
            _InfoRow(
              icon: Icons.scale_outlined,
              label: 'Capacity',
              value: widget.load.capacity!,
            ),
          const SizedBox(height: 20),

          // Vehicle selector
          if (vehicles.isNotEmpty) ...[
            Text('Assign Vehicle (optional)',
                style: _inter(
                    size: 12, weight: FontWeight.w700, color: _secondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _surfaceContainer),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedVehicleId,
                  isExpanded: true,
                  hint: Text('Select vehicle',
                      style: _inter(size: 13, color: _secondary)),
                  style: _inter(
                      size: 13,
                      color: const Color(0xFF191C1E),
                      weight: FontWeight.w500),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('None',
                          style: _inter(size: 13, color: _secondary)),
                    ),
                    ...vehicles.map((v) {
                      final reg = v['registration'] as String? ?? '—';
                      final id = v['id'] as String?;
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(reg),
                      );
                    }),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedVehicleId = val),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isBusy ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.manrope(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Fulfillment'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _secondary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: _inter(
                  size: 13, weight: FontWeight.w600, color: _secondary)),
          Text(value,
              style: _inter(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFF191C1E))),
        ],
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _LoadsEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child:
                  const Icon(Icons.search_off_rounded, size: 44, color: _primary),
            ),
            const SizedBox(height: 16),
            Text('No loads available',
                style: _manrope(size: 18, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'No pending load requirements at the moment.\nCheck back later or adjust your search.',
              textAlign: TextAlign.center,
              style: _inter(size: 13, color: _secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadsError extends StatelessWidget {
  final String message;
  const _LoadsError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 44, color: _error),
            const SizedBox(height: 12),
            Text('Could not load', style: _manrope(size: 16)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: _inter(size: 13, color: _secondary)),
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
            child: Text('Fleet Management',
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
