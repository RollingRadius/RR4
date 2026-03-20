import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// ─── Colour tokens (Stitch design — orange primary) ───────────────────────────
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

// ─── Mock data models ─────────────────────────────────────────────────────────

class _ShipmentCard {
  final String id;
  final String name;
  final String route;
  final String eta;
  final String status; // 'in_transit' | 'delayed'
  final String driverInitials;
  const _ShipmentCard({
    required this.id,
    required this.name,
    required this.route,
    required this.eta,
    required this.status,
    required this.driverInitials,
  });
}

final _mockShipments = [
  const _ShipmentCard(
    id: '#L-9821',
    name: 'Steel Coils Direct',
    route: 'Nagpur Hub → Pune Port',
    eta: 'Today, 14:30',
    status: 'in_transit',
    driverInitials: 'JD',
  ),
  const _ShipmentCard(
    id: '#L-4412',
    name: 'Auto Components',
    route: 'Chennai → Bangalore',
    eta: '+2.5 hrs Delay',
    status: 'delayed',
    driverInitials: 'SK',
  ),
];

// ─── Main screen ─────────────────────────────────────────────────────────────

class LoadOwnerDashboardScreen extends ConsumerStatefulWidget {
  const LoadOwnerDashboardScreen({super.key});

  @override
  ConsumerState<LoadOwnerDashboardScreen> createState() =>
      _LoadOwnerDashboardScreenState();
}

class _LoadOwnerDashboardScreenState
    extends ConsumerState<LoadOwnerDashboardScreen> {
  int _navIndex = 0;

  // Pages rendered by the bottom nav
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _DashboardPage(),
      _LoadsPage(onGoToUpload: () => context.push('/load-owner/upload')),
      const _TrackingPage(),
      const _DocsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final initials = _initials(user?.fullName ?? 'JD');

    return Scaffold(
      backgroundColor: _background,
      body: Column(
        children: [
          // ── Top app bar ──────────────────────────────────────────────
          _TopBar(initials: initials),

          // ── Body ────────────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _navIndex,
              children: _pages,
            ),
          ),
        ],
      ),

      // ── Bottom nav ───────────────────────────────────────────────────
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

// ─── Top app bar ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String initials;
  const _TopBar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: _background,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.menu, color: _secondary),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'RR LOGISTICS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: _primary,
                ),
              ),
            ),
            const Icon(Icons.notifications_outlined, color: _secondary),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFD7E4EC),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

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
    return Container(
      decoration: BoxDecoration(
        color: _surfaceLowest.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final (icon, label) = _items[i];
              final active = i == selectedIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: active
                      ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                      : const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: active ? _primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
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
                          letterSpacing: 0.5,
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
    );
  }
}

// ─── Dashboard page ───────────────────────────────────────────────────────────

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI bento grid
          _KpiGrid(),
          const SizedBox(height: 24),

          // Shipment status list
          _ShipmentSection(),
          const SizedBox(height: 24),

          // Active load detail
          _ActiveLoadDetail(),
        ],
      ),
    );
  }
}

// ── KPI bento grid ────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: const [
        _KpiCard(
          label: 'TOTAL ACTIVE',
          value: '24',
          accentColor: _primary,
        ),
        _KpiCard(
          label: 'IN TRANSIT',
          value: '18',
          accentColor: _tertiaryContainer,
        ),
        _KpiCard(
          label: 'DELAYED',
          value: '4',
          accentColor: _error,
          showWarning: true,
        ),
        _KpiCard(
          label: 'COMPLETED',
          value: '12',
          accentColor: _secondaryFixed,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final bool showWarning;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.accentColor,
    this.showWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _secondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: _onSurface,
                  height: 1,
                ),
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

// ── Shipment status section ────────────────────────────────────────────────────

class _ShipmentSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Shipment Status',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _onSurface,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: _primary,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'View All',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _mockShipments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ShipmentItem(shipment: _mockShipments[i]),
          ),
        ),
      ],
    );
  }
}

class _ShipmentItem extends StatelessWidget {
  final _ShipmentCard shipment;
  const _ShipmentItem({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final isDelayed = shipment.status == 'delayed';
    final statusColor = isDelayed ? _error : _tertiary;
    final statusBg = isDelayed
        ? _errorContainer.withOpacity(0.5)
        : _tertiaryContainer.withOpacity(0.12);
    final statusLabel = isDelayed ? 'DELAYED' : 'IN TRANSIT';

    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shipment.id,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _secondary,
                    ),
                  ),
                  Text(
                    shipment.name,
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: _secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  shipment.route,
                  style: const TextStyle(fontSize: 12, color: _secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ETA
          Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 14, color: _secondary),
              const SizedBox(width: 6),
              Text(
                shipment.eta,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isDelayed ? FontWeight.w700 : FontWeight.w400,
                  color: isDelayed ? _error : _secondary,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: _surfaceContainerHigh,
                child: Text(
                  shipment.driverInitials,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                  ),
                ),
              ),
              Icon(
                isDelayed
                    ? Icons.warning_amber_rounded
                    : Icons.error_outline_rounded,
                color: _error,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Active load detail ────────────────────────────────────────────────────────

class _ActiveLoadDetail extends StatelessWidget {
  const _ActiveLoadDetail();

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
                color: _primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics_outlined,
                  color: _primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Active Load Detail: #L-9821',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Map placeholder
        _MapPlaceholder(),
        const SizedBox(height: 16),

        // Shipment timeline
        _TimelineCard(),
        const SizedBox(height: 12),

        // Load visibility + truck info
        Row(
          children: [
            const Expanded(child: _LoadVisibilityCard()),
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
        const SizedBox(height: 16),

        // Action buttons
        _ActionButtons(),
        const SizedBox(height: 8),
      ],
    );
  }
}

// Map placeholder (no external plugin needed)
class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
        ),
      ),
      child: Stack(
        children: [
          // Grid lines to simulate map
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
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 0.5),
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
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current position label
          Positioned(
            bottom: 12,
            left: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'CURRENT POSITION',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white60,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'NH-44 Highway, Maharashtra',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Truck icon in center
          const Center(
            child: Icon(Icons.local_shipping_rounded,
                color: _primary, size: 36),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Timeline
class _TimelineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Created', true, false),
      ('Assigned', true, false),
      ('Dispatched', true, false),
      ('In Transit', true, true), // current
      ('Reached', false, false),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              letterSpacing: 1.0,
              color: _secondary,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Background track
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Container(height: 6, color: _surfaceContainerHigh),
              ),
              // Active progress (60%)
              Positioned(
                top: 10,
                left: 0,
                child: FractionallySizedBox(
                  widthFactor: 0.60,
                  child: Container(height: 6, color: _primary),
                ),
              ),
              // Nodes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: steps.map((s) {
                  final (label, done, current) = s;
                  return Column(
                    children: [
                      Container(
                        width: current ? 28 : 22,
                        height: current ? 28 : 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? _primary : _secondary.withOpacity(0.3),
                          border: Border.all(
                              color: Colors.white, width: 3),
                          boxShadow: current
                              ? [
                                  BoxShadow(
                                    color: _primary.withOpacity(0.4),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: done
                            ? Icon(
                                current
                                    ? Icons.local_shipping_rounded
                                    : Icons.check,
                                color: Colors.white,
                                size: current ? 14 : 11,
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: current ? _primary : _onSurface,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Load visibility card
class _LoadVisibilityCard extends StatelessWidget {
  const _LoadVisibilityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.inventory_2_outlined, color: _secondary, size: 18),
              SizedBox(width: 8),
              Text(
                'Load Visibility',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'MATERIAL',
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700,
              color: _secondary, letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Steel Coils\n(Grade-A)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'QUANTITY',
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700,
              color: _secondary, letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '24/24 tons',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }
}

// Truck & driver card
class _TruckDriverCard extends StatelessWidget {
  const _TruckDriverCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, color: _secondary, size: 18),
              SizedBox(width: 8),
              Text(
                'Truck & Driver',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surfaceContainer,
                ),
                child: const Icon(Icons.person_outline,
                    color: _secondary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'RJ14-GB-9821',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _secondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.call, size: 14),
              label: const Text('Call'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _tertiary,
                side: BorderSide(
                    color: _tertiaryContainer.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Schedule performance card
class _ScheduleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                    fontSize: 14, fontWeight: FontWeight.w700),
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
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: _error,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _scheduleRow('EVENT', 'PLANNED', 'ACTUAL', isHeader: true),
          const Divider(height: 16),
          _scheduleRow('Dispatch', '08:00 AM', '07:55 AM',
              actualColor: _tertiary),
          const Divider(height: 16),
          _scheduleRow('Mid-Point', '12:00 PM', '02:30 PM',
              actualColor: _error),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _errorContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 14, color: _error),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reason: Heavy Traffic & Highway Construction at NH-44 Toll.',
                    style: TextStyle(fontSize: 11, color: _error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleRow(String event, String planned, String actual,
      {bool isHeader = false, Color? actualColor}) {
    final style = TextStyle(
      fontSize: isHeader ? 9 : 12,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
      color: isHeader ? _secondary : _onSurface,
      letterSpacing: isHeader ? 0.6 : 0,
    );
    return Row(
      children: [
        Expanded(child: Text(event, style: style)),
        Expanded(
          child: Text(
            planned,
            style: style.copyWith(color: isHeader ? _secondary : _secondary),
          ),
        ),
        Expanded(
          child: Text(
            actual,
            style: style.copyWith(
              color: actualColor ?? (isHeader ? _secondary : _onSurface),
              fontWeight: actualColor != null
                  ? FontWeight.w700
                  : style.fontWeight,
            ),
          ),
        ),
      ],
    );
  }
}

// Documents section
class _DocumentsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const docs = [
      (Icons.description_outlined, 'POD', 'Verified', _tertiary),
      (Icons.receipt_long_outlined, 'E-Way Bill', 'Active', _tertiary),
      (Icons.photo_camera_outlined, 'Load Photo', '2 Files', _secondary),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Required Documents',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final (icon, name, status, color) = docs[i];
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
                        name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Action buttons
class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                icon: Icons.sos_rounded,
                label: 'Escalate',
                color: _primary,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionBtn(
                icon: Icons.edit_outlined,
                label: 'Modify',
                color: _secondary,
                outlined: true,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.mail_outline, size: 18),
            label: const Text('Contact Dispatch Office'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary, width: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withOpacity(0.4)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Loads page (placeholder — links to Upload screen) ────────────────────────

class _LoadsPage extends StatelessWidget {
  final VoidCallback onGoToUpload;
  const _LoadsPage({required this.onGoToUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.local_shipping_rounded, size: 48, color: _primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Manage Loads',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: _onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Post a new load requirement\nor view existing ones.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _secondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onGoToUpload,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Post New Load'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
}

// ─── Tracking page ────────────────────────────────────────────────────────────

class _TrackingPage extends StatelessWidget {
  const _TrackingPage();

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
                fontSize: 20, fontWeight: FontWeight.w800, color: _onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time GPS tracking coming soon.',
            style: TextStyle(fontSize: 14, color: _secondary),
          ),
        ],
      ),
    );
  }
}

// ─── Docs page ────────────────────────────────────────────────────────────────

class _DocsPage extends StatelessWidget {
  const _DocsPage();

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
                fontSize: 20, fontWeight: FontWeight.w800, color: _onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'POD, e-way bills and load photos.',
            style: TextStyle(fontSize: 14, color: _secondary),
          ),
        ],
      ),
    );
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : 'LO';
}
