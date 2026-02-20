import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'dart:math' as math;

// ─── Mock data ────────────────────────────────────────────────────────────────

class _VehicleData {
  final String id;
  final String name;
  final String info;
  final String status;
  final double level;
  final bool isAlert;
  final IconData vehicleIcon;

  const _VehicleData({
    required this.id,
    required this.name,
    required this.info,
    required this.status,
    required this.level,
    this.isAlert = false,
    this.vehicleIcon = Icons.local_shipping_rounded,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── Data ──────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _vehicles = [
    _VehicleData(
      id: 'TRK-042',
      name: 'Truck-042',
      info: 'John Doe',
      status: 'active',
      level: 0.85,
      vehicleIcon: Icons.local_shipping_rounded,
    ),
    _VehicleData(
      id: 'VAN-018',
      name: 'Van-018',
      info: 'Service Center A',
      status: 'maintenance',
      level: 0.20,
      vehicleIcon: Icons.airport_shuttle_rounded,
    ),
    _VehicleData(
      id: 'SMI-009',
      name: 'Semi-009',
      info: 'I-95 Northbound',
      status: 'active',
      level: 0.62,
      vehicleIcon: Icons.fire_truck_rounded,
    ),
    _VehicleData(
      id: 'TRK-102',
      name: 'Truck-102',
      info: 'Engine Overheat',
      status: 'alert',
      level: 0.45,
      isAlert: true,
      vehicleIcon: Icons.local_shipping_rounded,
    ),
  ];

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _ctrl;

  late final Animation<double> _fadeHeader;
  late final Animation<Offset> _slideHeader;
  late final Animation<double> _fadeHero;
  late final Animation<Offset> _slideHero;
  late final Animation<double> _fadeStats;
  late final Animation<Offset> _slideStats;
  late final Animation<double> _fadeMap;
  late final Animation<Offset> _slideMap;
  late final Animation<double> _fadeVehicles;
  late final Animation<Offset> _slideVehicles;
  late final Animation<double> _fadeActivity;
  late final Animation<Offset> _slideActivity;

  // Ring gauge progress
  late final Animation<double> _ringProgress;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    Animation<double> _f(double s, double e) =>
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _ctrl, curve: Interval(s, e, curve: Curves.easeOut)),
        );
    Animation<Offset> _s(double s, double e) =>
        Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(
          CurvedAnimation(parent: _ctrl, curve: Interval(s, e, curve: Curves.easeOutCubic)),
        );

    _fadeHeader   = _f(0.00, 0.30); _slideHeader   = _s(0.00, 0.30);
    _fadeHero     = _f(0.10, 0.40); _slideHero     = _s(0.10, 0.40);
    _fadeStats    = _f(0.20, 0.50); _slideStats    = _s(0.20, 0.50);
    _fadeMap      = _f(0.30, 0.60); _slideMap      = _s(0.30, 0.60);
    _fadeVehicles = _f(0.40, 0.70); _slideVehicles = _s(0.40, 0.70);
    _fadeActivity = _f(0.55, 0.85); _slideActivity = _s(0.55, 0.85);

    _ringProgress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.10, 0.80, curve: Curves.easeOutCubic),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<_VehicleData> get _filtered {
    if (_searchQuery.isEmpty) return _vehicles;
    final q = _searchQuery.toLowerCase();
    return _vehicles
        .where((v) =>
            v.name.toLowerCase().contains(q) ||
            v.info.toLowerCase().contains(q) ||
            v.id.toLowerCase().contains(q))
        .toList();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _todayLabel() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final displayName = user?.fullName.split(' ').first ?? 'Manager';

    final total       = _vehicles.length;
    final active      = _vehicles.where((v) => v.status == 'active').length;
    final maintenance = _vehicles.where((v) => v.status == 'maintenance').length;
    final alerts      = _vehicles.where((v) => v.isAlert).length;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Sticky header ──────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 80,
                collapsedHeight: 80,
                automaticallyImplyLeading: false,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: const Color(0xFFF1F5F9)),
                ),
                flexibleSpace: SafeArea(
                  child: _AnimItem(
                    fade: _fadeHeader,
                    slide: _slideHeader,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEC5B13), Color(0xFFD14A0A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.local_shipping_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_greeting()}, $displayName',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  _todayLabel(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Notifications
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3ED),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primaryBlue.withOpacity(0.2),
                                  ),
                                ),
                                child: Icon(Icons.notifications_outlined,
                                    color: AppTheme.primaryBlue, size: 20),
                              ),
                              if (alerts > 0)
                                Positioned(
                                  top: -3,
                                  right: -3,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppTheme.statusError,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$alerts',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Content ────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Search
                    _buildSearchBar(),
                    const SizedBox(height: 16),

                    // Fleet health hero
                    _AnimItem(
                      fade: _fadeHero,
                      slide: _slideHero,
                      child: _buildHealthHero(active, total),
                    ),
                    const SizedBox(height: 14),

                    // 4 stat tiles
                    _AnimItem(
                      fade: _fadeStats,
                      slide: _slideStats,
                      child: _buildStatRow(total, active, maintenance, alerts),
                    ),
                    const SizedBox(height: 20),

                    // Mini map
                    _AnimItem(
                      fade: _fadeMap,
                      slide: _slideMap,
                      child: _buildMiniMap(context),
                    ),
                    const SizedBox(height: 20),

                    // Vehicle status
                    _AnimItem(
                      fade: _fadeVehicles,
                      slide: _slideVehicles,
                      child: _buildVehicleSection(context),
                    ),
                    const SizedBox(height: 20),

                    // Recent activity
                    _AnimItem(
                      fade: _fadeActivity,
                      slide: _slideActivity,
                      child: _buildRecentActivity(),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // FAB
          Positioned(
            right: 20,
            bottom: 88,
            child: FloatingActionButton(
              onPressed: () => context.push('/vehicles/add'),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search vehicle ID or driver...',
                hintStyle: const TextStyle(
                    fontSize: 14, color: AppTheme.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.textTertiary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear_rounded,
                            size: 16, color: AppTheme.textTertiary),
                      )
                    : null,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.bgPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded,
                size: 18, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Fleet health hero ──────────────────────────────────────────────────────

  Widget _buildHealthHero(int active, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC5B13), Color(0xFFBF4209)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: Colors.white, size: 13),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'FLEET HEALTH',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '87',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                const Text(
                  'out of 100',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _HeroBadge(
                      icon: Icons.check_circle_rounded,
                      text: '$active Active',
                      color: Colors.white.withOpacity(0.25),
                    ),
                    const SizedBox(width: 8),
                    _HeroBadge(
                      icon: Icons.local_shipping_rounded,
                      text: '$total Vehicles',
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right: animated ring
          AnimatedBuilder(
            animation: _ringProgress,
            builder: (_, __) => SizedBox(
              width: 108,
              height: 108,
              child: CustomPaint(
                painter: _HealthRingPainter(progress: _ringProgress.value * 0.87),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'GOOD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'STATUS',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
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

  // ── Stat row ───────────────────────────────────────────────────────────────

  Widget _buildStatRow(int total, int active, int maintenance, int alerts) {
    return Row(
      children: [
        _StatTile(value: '$total', label: 'Total',
            icon: Icons.inventory_2_rounded, color: AppTheme.textPrimary),
        const SizedBox(width: 8),
        _StatTile(value: '$active', label: 'Active',
            icon: Icons.play_circle_rounded, color: AppTheme.statusActive),
        const SizedBox(width: 8),
        _StatTile(value: '$maintenance', label: 'Service',
            icon: Icons.build_rounded, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        _StatTile(value: '$alerts', label: 'Alerts',
            icon: Icons.warning_rounded, color: AppTheme.statusError),
      ],
    );
  }

  // ── Mini live map ──────────────────────────────────────────────────────────

  Widget _buildMiniMap(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Map area
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _MiniMapPainter()),
                // Top overlay: label + live badge
                Positioned(
                  top: 12,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Live Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 4)
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.statusActive,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Vehicle pin legend
                Row(
                  children: [
                    _MapLegend(color: AppTheme.statusActive, label: '2 Active'),
                    const SizedBox(width: 12),
                    _MapLegend(color: AppTheme.primaryBlue, label: '1 Service'),
                    const SizedBox(width: 12),
                    _MapLegend(color: AppTheme.statusError, label: '1 Alert'),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/tracking/live'),
                  child: Row(
                    children: [
                      Text(
                        'Full Map',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: AppTheme.primaryBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Vehicle section ────────────────────────────────────────────────────────

  Widget _buildVehicleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vehicle Status',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/vehicles'),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppTheme.primaryBlue),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text(
              'No vehicles match your search',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          )
        else
          ...List.generate(_filtered.length, (i) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i < _filtered.length - 1 ? 10 : 0),
              child: _VehicleCard(
                vehicle: _filtered[i],
                barAnimation: CurvedAnimation(
                  parent: _ctrl,
                  curve: Interval(
                    0.40 + i * 0.06,
                    0.75 + i * 0.04,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                onTap: () {},
              ),
            );
          }),
      ],
    );
  }

  // ── Recent activity ────────────────────────────────────────────────────────

  Widget _buildRecentActivity() {
    const events = [
      (
        icon: Icons.play_arrow_rounded,
        color: Color(0xFF10B981),
        bg: Color(0xFFD1FAE5),
        title: 'Trip Started',
        sub: 'Truck-042 → I-95 North  •  2m ago',
      ),
      (
        icon: Icons.build_rounded,
        color: Color(0xFFEC5B13),
        bg: Color(0xFFFFE4D6),
        title: 'Maintenance Scheduled',
        sub: 'Van-018 → Service Center A  •  1h ago',
      ),
      (
        icon: Icons.person_add_rounded,
        color: Color(0xFF7C3AED),
        bg: Color(0xFFEDE9FE),
        title: 'Driver Assigned',
        sub: 'Marcus Thorne → Semi-009  •  3h ago',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(events.length, (i) {
              final e = events[i];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: e.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(e.icon, color: e.color, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  )),
                              const SizedBox(height: 2),
                              Text(e.sub,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < events.length - 1)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(left: 54),
                      color: const Color(0xFFF8F6F6),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AnimItem extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget child;

  const _AnimItem(
      {required this.fade, required this.slide, required this.child});

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _HeroBadge(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                height: 1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ─── Vehicle Card ─────────────────────────────────────────────────────────────

class _VehicleCard extends StatefulWidget {
  final _VehicleData vehicle;
  final Animation<double> barAnimation;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    required this.barAnimation,
    required this.onTap,
  });

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  (Color, Color, String) get _statusStyle {
    switch (widget.vehicle.status) {
      case 'active':
        return (AppTheme.statusActive, const Color(0xFFD1FAE5), 'Active');
      case 'maintenance':
        return (AppTheme.primaryBlue, const Color(0xFFFFE4D6), 'Service');
      case 'alert':
        return (AppTheme.statusError, const Color(0xFFFEE2E2), 'Alert');
      default:
        return (AppTheme.statusIdle, const Color(0xFFF1F0F0), 'Offline');
    }
  }

  Color get _vehicleIconColor {
    switch (widget.vehicle.status) {
      case 'active':    return AppTheme.primaryBlue;
      case 'maintenance': return const Color(0xFF7C3AED);
      case 'alert':     return AppTheme.statusError;
      default:          return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg, statusLabel) = _statusStyle;

    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) {
        _press.forward();
        widget.onTap();
      },
      onTapCancel: () => _press.forward(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: _press.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.vehicle.isAlert
                  ? AppTheme.statusError.withOpacity(0.25)
                  : const Color(0xFFF1F5F9),
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.vehicle.isAlert
                        ? AppTheme.statusError
                        : Colors.black)
                    .withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Vehicle type icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _vehicleIconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(widget.vehicle.vehicleIcon,
                        color: _vehicleIconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.vehicle.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.vehicle.id,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              widget.vehicle.isAlert
                                  ? Icons.warning_amber_rounded
                                  : widget.vehicle.status == 'active'
                                      ? Icons.person_outline_rounded
                                      : Icons.location_on_outlined,
                              size: 12,
                              color: widget.vehicle.isAlert
                                  ? AppTheme.statusError
                                  : AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                widget.vehicle.info,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.vehicle.isAlert
                                      ? AppTheme.statusError
                                      : AppTheme.textTertiary,
                                  fontWeight: widget.vehicle.isAlert
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge + level
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.gas_meter_outlined,
                              size: 12, color: statusColor),
                          const SizedBox(width: 3),
                          Text(
                            '${(widget.vehicle.level * 100).round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Animated progress bar
              AnimatedBuilder(
                animation: widget.barAnimation,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 5,
                    color: const Color(0xFFF1F5F9),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (widget.vehicle.level *
                                widget.barAnimation.value)
                            .clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withOpacity(0.6),
                                statusColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

class _HealthRingPainter extends CustomPainter {
  final double progress; // 0..1

  const _HealthRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.44;
    const sw = 7.0;

    canvas.drawCircle(c, r,
        Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HealthRingPainter old) => old.progress != progress;
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF2D3748),
    );

    // Road grid
    final roadPaint = Paint()
      ..color = const Color(0xFF4A5568)
      ..strokeWidth = 8;
    final thinRoad = Paint()
      ..color = const Color(0xFF3D4A5C)
      ..strokeWidth = 4;

    // Horizontal roads
    for (final y in [size.height * 0.28, size.height * 0.55, size.height * 0.78]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    // Vertical roads
    for (final x in [size.width * 0.22, size.width * 0.50, size.width * 0.75]) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    // Thin roads
    for (final y in [size.height * 0.42, size.height * 0.66]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thinRoad);
    }

    // City blocks
    final blockPaint = Paint()..color = const Color(0xFF3A4A5C);
    final blocks = [
      Rect.fromLTWH(8, 8, size.width * 0.18, size.height * 0.16),
      Rect.fromLTWH(size.width * 0.26, 8, size.width * 0.20, size.height * 0.16),
      Rect.fromLTWH(size.width * 0.54, 8, size.width * 0.18, size.height * 0.16),
      Rect.fromLTWH(8, size.height * 0.32, size.width * 0.10, size.height * 0.19),
      Rect.fromLTWH(size.width * 0.26, size.height * 0.32, size.width * 0.20, size.height * 0.19),
      Rect.fromLTWH(size.width * 0.54, size.height * 0.32, size.width * 0.18, size.height * 0.19),
      Rect.fromLTWH(8, size.height * 0.60, size.width * 0.10, size.height * 0.18),
      Rect.fromLTWH(size.width * 0.26, size.height * 0.60, size.width * 0.20, size.height * 0.14),
      Rect.fromLTWH(size.width * 0.54, size.height * 0.60, size.width * 0.18, size.height * 0.14),
    ];
    for (final b in blocks) {
      canvas.drawRRect(RRect.fromRectXY(b, 3, 3), blockPaint);
    }

    // Route line
    final routePaint = Paint()
      ..color = const Color(0xFFEC5B13).withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final routePath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.55)
      ..lineTo(size.width * 0.50, size.height * 0.55)
      ..lineTo(size.width * 0.50, size.height * 0.28);
    canvas.drawPath(routePath, routePaint);

    // Vehicle pins
    void _pin(double x, double y, Color color) {
      canvas.drawCircle(Offset(x, y), 7,
          Paint()..color = color.withOpacity(0.3));
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    _pin(size.width * 0.22, size.height * 0.55, const Color(0xFF10B981));
    _pin(size.width * 0.50, size.height * 0.28, const Color(0xFF10B981));
    _pin(size.width * 0.75, size.height * 0.55, const Color(0xFFEC5B13));
    _pin(size.width * 0.50, size.height * 0.55, const Color(0xFFEF4444));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
