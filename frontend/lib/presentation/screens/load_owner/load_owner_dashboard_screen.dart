import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/presentation/widgets/ongoing_trip_card.dart';

// ─── Typography helpers (Stitch: Manrope headline, Inter body) ────────────────
TextStyle _manrope(
        {double size = 14,
        FontWeight weight = FontWeight.w600,
        Color color = const Color(0xFF191C1E)}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter(
        {double size = 13,
        FontWeight weight = FontWeight.w400,
        Color color = const Color(0xFF546067)}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

// ─── Colour tokens ────────────────────────────────────────────────────────────
const _primary = Color(0xFFFF6B00);
const _background = Color(0xFFF8F9FB);
const _surfaceLowest = Color(0xFFFFFFFF);
const _surfaceContainer = Color(0xFFECEEF0);
const _surfaceContainerLow = Color(0xFFF2F4F6);
const _surfaceContainerHigh = Color(0xFFE6E8EA);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _tertiary = Color(0xFF006B5E);
const _tertiaryContainer = Color(0xFF4AA898);
const _error = Color(0xFFBA1A1A);
const _errorContainer = Color(0xFFFFDAD6);
const _secondaryFixed = Color(0xFFBBC8D0);
const _secondaryContainer = Color(0xFFD7E4EC);

// ─── Load data model ──────────────────────────────────────────────────────────

class LoadItem {
  final String id;
  final String? pickupLocation;
  final String? unloadLocation;
  final String? materialType;
  final String? entryDate;
  final int truckCount;
  final String status;
  final String createdAt;

  const LoadItem({
    required this.id,
    this.pickupLocation,
    this.unloadLocation,
    this.materialType,
    this.entryDate,
    required this.truckCount,
    required this.status,
    required this.createdAt,
  });

  factory LoadItem.fromJson(Map<String, dynamic> json) => LoadItem(
        id: json['id'] as String,
        pickupLocation: json['pickup_location'] as String?,
        unloadLocation: json['unload_location'] as String?,
        materialType: json['material_type'] as String?,
        entryDate: json['entry_date'] as String?,
        truckCount: json['truck_count'] as int? ?? 1,
        status: json['status'] as String? ?? 'pending',
        createdAt: json['created_at'] as String? ?? '',
      );

  String get displayId {
    final clean = id.replaceAll('-', '');
    final short = clean.length >= 8
        ? clean.substring(0, 8).toUpperCase()
        : clean.toUpperCase();
    return '#L-$short';
  }

  String get routeLabel {
    final from =
        (pickupLocation?.isNotEmpty == true) ? pickupLocation! : 'Origin';
    final to =
        (unloadLocation?.isNotEmpty == true) ? unloadLocation! : 'Destination';
    return '$from → $to';
  }

  String get name =>
      (materialType?.isNotEmpty == true) ? materialType! : 'Load Requirement';

  bool get isDelayed => status == 'delayed';
  bool get isCompleted => status == 'completed';
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final _loadsProvider = FutureProvider.autoDispose<List<LoadItem>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/api/loads');
  final data = response.data as Map<String, dynamic>;
  final list = data['loads'] as List? ?? [];
  return list
      .map((e) => LoadItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Main screen ──────────────────────────────────────────────────────────────

class LoadOwnerDashboardScreen extends ConsumerStatefulWidget {
  const LoadOwnerDashboardScreen({super.key});

  @override
  ConsumerState<LoadOwnerDashboardScreen> createState() =>
      _LoadOwnerDashboardScreenState();
}

class _LoadOwnerDashboardScreenState
    extends ConsumerState<LoadOwnerDashboardScreen> {
  int _navIndex = 0;
  late final List<Widget> _pages;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _DashboardTab(),
      _LoadsTab(onCreateLoad: () => context.push('/load-owner/upload')),
      const _TrackingTab(),
      const _DocsTab(),
    ];
    Future.microtask(
        () => ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing'));
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
    final initials = _initials(user?.fullName ?? 'JD');

    return Scaffold(
      backgroundColor: _background,
      body: Column(
        children: [
          _TopBar(initials: initials),
          Expanded(
            child: IndexedStack(index: _navIndex, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _navIndex,
        onTap: (i) {
          if (i == 4) {
            _showProfileSheet(context);
          } else {
            setState(() => _navIndex = i);
          }
        },
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: _primary),
              title: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : 'JD';
}

// ─── Top App Bar ──────────────────────────────────────────────────────────────

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
            const Spacer(),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
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
    (Icons.local_shipping_rounded, 'LOADS'),
    (Icons.explore_outlined, 'TRACKING'),
    (Icons.description_outlined, 'DOCS'),
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
                color: Colors.white.withValues(alpha: 0.6),
                width: 0.5,
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
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
                      ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                      : const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: active ? _primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          color: active ? Colors.white : _secondary, size: 22),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: active ? Colors.white : _secondary,
                        ),
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
    final loadsAsync = ref.watch(_loadsProvider);
    final tripState = ref.watch(tripProvider);
    final ongoingTrips = tripState.ongoingTrips;

    return loadsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _primary)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _error, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Failed to load data',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _onSurface),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(_loadsProvider),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary, foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (loads) {
        final total = loads.length;
        final inTransit =
            loads.where((l) => l.status == 'in_transit').length;
        final delayed = loads.where((l) => l.isDelayed).length;
        final completed = loads.where((l) => l.isCompleted).length;
        final topLoad = loads.isNotEmpty ? loads.first : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KpiGrid(
                  total: total,
                  inTransit: inTransit,
                  delayed: delayed,
                  completed: completed),
              const SizedBox(height: 24),
              // ── Shipment Status — with live trip cards ────────────────
              _ShipmentStatusWithTrips(
                loads: loads,
                trips: ongoingTrips,
                isLive: !tripState.isLoading,
              ),
              const SizedBox(height: 24),

              if (topLoad != null) _ActiveLoadDetail(load: topLoad),
              if (topLoad == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.local_shipping_outlined,
                            color: _secondary, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No loads posted yet',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _secondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Post your first load requirement\nto see activity here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: _secondary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── KPI Grid ─────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final int total;
  final int inTransit;
  final int delayed;
  final int completed;

  const _KpiGrid({
    required this.total,
    required this.inTransit,
    required this.delayed,
    required this.completed,
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
        _KpiCard(label: 'TOTAL ACTIVE', value: '$total', accent: _primary),
        _KpiCard(label: 'IN TRANSIT', value: '$inTransit', accent: _tertiary),
        _KpiCard(
            label: 'DELAYED',
            value: '$delayed',
            accent: _error,
            showWarning: delayed > 0),
        _KpiCard(
            label: 'COMPLETED', value: '$completed', accent: _secondaryFixed),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
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
            style: _inter(
              size: 9,
              weight: FontWeight.w700,
              color: _secondary,
            ).copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                value,
                style: _manrope(
                  size: 32,
                  weight: FontWeight.w800,
                  color: _onSurface,
                ).copyWith(height: 1.0),
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

// ─── Shipment Status with live trip cards ────────────────────────────────────

class _ShipmentStatusWithTrips extends StatelessWidget {
  final List<LoadItem> loads;
  final List<dynamic> trips;  // List<TripModel>
  final bool isLive;

  const _ShipmentStatusWithTrips({
    required this.loads,
    required this.trips,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shipment Status',
                style: _manrope(size: 17, weight: FontWeight.w800)),
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
        ),
        const SizedBox(height: 12),

        // ── Trip cards ───────────────────────────────────────────────────
        if (trips.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: _surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route_rounded,
                      color: _secondary, size: 40),
                  const SizedBox(height: 8),
                  Text('No active trips',
                      style: _inter(
                          size: 14,
                          weight: FontWeight.w600,
                          color: _secondary)),
                  const SizedBox(height: 4),
                  Text('Assigned trips will appear here',
                      style: _inter(size: 12)),
                ],
              ),
            ),
          )
        else
          ...trips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OngoingTripCard(trip: t),
            ),
          ),

        // ── Posted loads (compact horizontal scroll below trips) ─────────
        if (loads.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Posted Loads',
                  style: _manrope(size: 14, weight: FontWeight.w700,
                      color: _secondary)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    padding: EdgeInsets.zero),
                child: const Text('View All',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: loads.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _ShipmentCard(load: loads[i]),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Shipment Status Section (kept for reference / other uses) ───────────────

class _ShipmentSection extends StatelessWidget {
  final List<LoadItem> loads;
  const _ShipmentSection({required this.loads});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shipment Status',
              style: _manrope(size: 17, weight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: _primary,
                padding: EdgeInsets.zero,
              ),
              child: const Text('View All',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (loads.isEmpty)
          Container(
            height: 176,
            decoration: BoxDecoration(
              color: _surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_shipping_outlined,
                      color: _secondary, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'No active shipments',
                    style: TextStyle(
                        color: _secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: loads.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _ShipmentCard(load: loads[i]),
            ),
          ),
      ],
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final LoadItem load;
  const _ShipmentCard({required this.load});

  String _statusLabel(String s) {
    switch (s) {
      case 'in_transit':
        return 'IN TRANSIT';
      case 'delayed':
        return 'DELAYED';
      case 'completed':
        return 'COMPLETED';
      default:
        return 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBg = load.isDelayed
        ? _errorContainer
        : _tertiaryContainer.withValues(alpha: 0.12);
    final statusFg = load.isDelayed ? _error : _tertiary;

    return Container(
      width: 270,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    load.displayId,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _secondary,
                    ),
                  ),
                  Text(
                    load.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(load.status),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: _secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  load.routeLabel,
                  style: const TextStyle(fontSize: 12, color: _secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 14, color: _secondary),
              const SizedBox(width: 6),
              Text(
                load.entryDate ?? 'Date TBD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      load.isDelayed ? FontWeight.w700 : FontWeight.w400,
                  color: load.isDelayed ? _error : _secondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Divider(height: 1, color: _surfaceContainer),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surfaceContainerHigh,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.local_shipping, size: 12, color: _secondary),
                ),
              ),
              Icon(
                load.isDelayed
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: load.isDelayed ? _error : _tertiary,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Active Load Detail ───────────────────────────────────────────────────────

class _ActiveLoadDetail extends StatelessWidget {
  final LoadItem load;
  const _ActiveLoadDetail({required this.load});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics_outlined,
                  color: _primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Active Load Detail: ${load.displayId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Live map
        _MapPlaceholder(),
        const SizedBox(height: 14),

        // Shipment timeline
        _TimelineCard(),
        const SizedBox(height: 12),

        // Load visibility + truck driver
        Row(
          children: [
            Expanded(child: _LoadVisibilityCard(load: load)),
            const SizedBox(width: 12),
            const Expanded(child: _TruckDriverCard()),
          ],
        ),
        const SizedBox(height: 12),

        // Schedule performance
        _ScheduleCard(),
        const SizedBox(height: 12),

        // Documents
        _DocumentsSection(),
        const SizedBox(height: 12),

        // Action buttons
        _ActionButtons(),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Map Placeholder ──────────────────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
          ),
        ),
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _MapGridPainter(),
            ),
            // GPS signal badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE GPS SIGNAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2E44),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Fullscreen button
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.70),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fullscreen_rounded,
                    size: 18, color: Color(0xFF1A2E44)),
              ),
            ),
            // Position label
            const Positioned(
              bottom: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT POSITION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'NH-44 Highway, Maharashtra',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Route line
    final routePaint = Paint()
      ..color = _primary.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.7)
      ..cubicTo(
        size.width * 0.3, size.height * 0.3,
        size.width * 0.6, size.height * 0.7,
        size.width * 0.85, size.height * 0.35,
      );
    canvas.drawPath(path, routePaint);
    // Truck icon dot
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.54),
      6,
      Paint()..color = _primary,
    );
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.54),
      10,
      Paint()
        ..color = _primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Timeline Card ────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = ['CREATED', 'ASSIGNED', 'DISPATCHED', 'IN TRANSIT', 'REACHED'];
    // 0-2 done, 3 active, 4 pending
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SHIPMENT LIFECYCLE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: _secondary,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background progress track
                  Positioned(
                    top: 11,
                    left: 12,
                    right: 12,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _secondaryFixed.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Orange fill — 60% (through "In Transit")
                  Positioned(
                    top: 11,
                    left: 12,
                    child: Container(
                      height: 4,
                      width: (w - 24) * 0.60,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Nodes row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(steps.length, (i) {
                      final done = i < 3;
                      final active = i == 3;
                      final pending = i == 4;
                      return Opacity(
                        opacity: pending ? 0.35 : 1.0,
                        child: Column(
                          children: [
                            Transform.scale(
                              scale: active ? 1.22 : 1.0,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (done || active) ? _primary : _secondary,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color: _primary.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  active
                                      ? Icons.local_shipping_rounded
                                      : done
                                          ? Icons.check_rounded
                                          : null,
                                  size: active ? 12 : 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              steps[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: active ? _primary : _onSurface,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Load Visibility Card ─────────────────────────────────────────────────────

class _LoadVisibilityCard extends StatelessWidget {
  final LoadItem load;
  const _LoadVisibilityCard({required this.load});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.inventory_2_outlined, size: 18, color: _secondary),
              SizedBox(width: 8),
              Text(
                'Load Visibility',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'MATERIAL',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: _secondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            (load.materialType?.isNotEmpty == true)
                ? load.materialType!
                : 'Not specified',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _onSurface,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          const Text(
            'TRUCKS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: _secondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${load.truckCount} requested',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Truck & Driver Card ──────────────────────────────────────────────────────

class _TruckDriverCard extends StatelessWidget {
  const _TruckDriverCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, size: 18, color: _secondary),
              SizedBox(width: 8),
              Text(
                'Truck & Driver',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surfaceContainer,
                ),
                child: const Icon(Icons.person_outline,
                    size: 20, color: _secondary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _onSurface,
                      ),
                    ),
                    Text(
                      'RJ14-GB-9821',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _secondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _tertiaryContainer.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_rounded,
                color: _tertiary, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Performance Card ────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Schedule Performance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CRITICAL DELAY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Table header
          const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('EVENT',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _secondary,
                        letterSpacing: 0.8)),
              ),
              Expanded(
                flex: 3,
                child: Text('PLANNED',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _secondary,
                        letterSpacing: 0.8)),
              ),
              Expanded(
                flex: 3,
                child: Text('ACTUAL',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _secondary,
                        letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _scheduleRow('Dispatch', '08:00 AM', '07:55 AM', false),
          const Divider(height: 16, color: _surfaceContainerLow),
          _scheduleRow('Mid-Point', '12:00 PM', '02:30 PM', true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _errorContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: _error),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reason: Heavy Traffic & Highway Construction at NH-44 Toll.',
                    style: TextStyle(
                      fontSize: 11,
                      color: _error,
                      height: 1.4,
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

  Widget _scheduleRow(
      String event, String planned, String actual, bool delayed) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(event,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _onSurface)),
        ),
        Expanded(
          flex: 3,
          child: Text(planned,
              style:
                  const TextStyle(fontSize: 12, color: _secondary)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            actual,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: delayed ? _error : _tertiary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Documents Section ────────────────────────────────────────────────────────

class _DocumentsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Required Documents',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _DocChip(
                    icon: Icons.description_outlined,
                    label: 'POD',
                    status: 'Verified',
                    statusColor: _tertiary),
                const SizedBox(width: 10),
                _DocChip(
                    icon: Icons.receipt_long_outlined,
                    label: 'E-Way Bill',
                    status: 'Active',
                    statusColor: _tertiary),
                const SizedBox(width: 10),
                _DocChip(
                    icon: Icons.photo_camera_outlined,
                    label: 'Load Photo',
                    status: '2 Files',
                    statusColor: _secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final Color statusColor;

  const _DocChip({
    required this.icon,
    required this.label,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _surfaceContainerHigh),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _primary, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            status,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _actionBtn('Escalate', Icons.sos_rounded, _primary, Colors.white, filled: true)),
            const SizedBox(width: 10),
            Expanded(
              child: _actionBtn('Modify', Icons.edit_outlined, _secondaryContainer, _onSurface, filled: true),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.mail_outline_rounded, size: 16),
            label: const Text('Contact Dispatch Office'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color bg,
    Color fg, {
    required bool filled,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: filled ? 3 : 0,
          shadowColor: bg.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Placeholder tabs ─────────────────────────────────────────────────────────

class _LoadsTab extends ConsumerWidget {
  final VoidCallback onCreateLoad;
  const _LoadsTab({required this.onCreateLoad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadsAsync = ref.watch(_loadsProvider);

    return loadsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _primary)),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _error, size: 48),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreateLoad,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Post New Load'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      data: (loads) {
        if (loads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_rounded,
                      size: 48, color: _primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Manage Loads',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _onSurface),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Post a new load requirement\nor view existing ones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: _secondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onCreateLoad,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Post New Load'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCreateLoad,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Post New Load'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: loads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _LoadListTile(load: loads[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoadListTile extends StatelessWidget {
  final LoadItem load;
  const _LoadListTile({required this.load});

  Color _statusColor(String status) {
    switch (status) {
      case 'in_transit':
        return _tertiary;
      case 'delayed':
        return _error;
      case 'completed':
        return _secondary;
      default:
        return _primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(load.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: _primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      load.displayId,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _onSurface),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        load.status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  load.name,
                  style: const TextStyle(fontSize: 12, color: _secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  load.routeLabel,
                  style: const TextStyle(fontSize: 11, color: _secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${load.truckCount} truck${load.truckCount != 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primary),
              ),
              if (load.entryDate != null)
                Text(
                  load.entryDate!,
                  style: const TextStyle(fontSize: 10, color: _secondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingTab extends StatelessWidget {
  const _TrackingTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_outlined, size: 64, color: _primary),
          const SizedBox(height: 16),
          const Text(
            'Live Tracking',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _onSurface),
          ),
          const SizedBox(height: 8),
          const Text(
            'Real-time GPS tracking coming soon.',
            style: TextStyle(fontSize: 14, color: _secondary),
          ),
        ],
      ),
    );
  }
}

class _DocsTab extends StatelessWidget {
  const _DocsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 64, color: _primary),
          const SizedBox(height: 16),
          const Text(
            'Documents',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _onSurface),
          ),
          const SizedBox(height: 8),
          const Text(
            'Document management coming soon.',
            style: TextStyle(fontSize: 14, color: _secondary),
          ),
        ],
      ),
    );
  }
}
