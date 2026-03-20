import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// ── Colour tokens ─────────────────────────────────────────────────────────────
const _primary = Color(0xFF001e40);
const _bg = Color(0xFFF7F9FB);
const _surfaceLowest = Color(0xFFFFFFFF);
const _surfaceContainer = Color(0xFFECEEF0);
const _surfaceContainerLow = Color(0xFFF2F4F6);
const _surfaceContainerHigh = Color(0xFFE6E8EA);
const _onSurface = Color(0xFF191C1E);
const _onSurfaceVariant = Color(0xFF43474F);
const _outlineVariant = Color(0xFFC3C6D1);
const _outline = Color(0xFF737780);
const _secondaryContainer = Color(0xFFD5E3FC);
const _onSecondaryContainer = Color(0xFF57657A);
const _tertiaryContainer = Color(0xFF592300);
const _onTertiaryContainer = Color(0xFFD8885C);

// ── Mock data ─────────────────────────────────────────────────────────────────

enum _TripStatus { inTransit, pendingDetails, completed }

class _Trip {
  final String id;
  final String origin;
  final String originSub;
  final String destination;
  final String destinationSub;
  final String material;
  final _TripStatus status;

  const _Trip({
    required this.id,
    required this.origin,
    this.originSub = '',
    required this.destination,
    this.destinationSub = '',
    required this.material,
    required this.status,
  });
}

const _featured = _Trip(
  id: 'RR-90422',
  origin: 'Nagpur Hub',
  originSub: 'Terminal 4, Bay A',
  destination: 'Pune Port',
  destinationSub: 'Section 13 Logistics Park',
  material: 'Industrial Steel Components',
  status: _TripStatus.inTransit,
);

const _upcomingTrips = [
  _Trip(
    id: 'RR-88219',
    origin: 'Mumbai Port',
    destination: 'Delhi Depot',
    material: 'Electronics (Type C)',
    status: _TripStatus.pendingDetails,
  ),
  _Trip(
    id: 'RR-88301',
    origin: 'Chennai Hub',
    destination: 'Bangalore',
    material: 'Perishable Goods',
    status: _TripStatus.inTransit,
  ),
  _Trip(
    id: 'RR-88002',
    origin: 'Nagpur',
    destination: 'Hyderabad',
    material: 'Medical Supplies',
    status: _TripStatus.completed,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final initials = _initials(user?.fullName ?? 'JD');

    return Scaffold(
      backgroundColor: _bg,
      appBar: _AppBar(initials: initials),
      floatingActionButton: _Fab(onTap: () => context.pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            _Header(),
            const SizedBox(height: 24),

            // ── Featured trip ─────────────────────────────────────
            _FeaturedTripCard(trip: _featured),
            const SizedBox(height: 16),

            // ── Stats row ─────────────────────────────────────────
            _StatsRow(),
            const SizedBox(height: 28),

            // ── Upcoming schedule ─────────────────────────────────
            const Text(
              'Upcoming Schedule',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _primary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            ..._upcomingTrips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TripRow(trip: t),
                )),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'JD';
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final String initials;
  const _AppBar({required this.initials});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _primary, size: 22),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'RR Logistics',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: _primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF003366),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header section ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LOGISTICS OVERVIEW',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: _onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Trips',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: _primary,
            letterSpacing: -1.0,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 16),
        // Search bar
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: _surfaceLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _outlineVariant.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search_rounded, color: _outline, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Shipment ID, Route...',
                    hintStyle: TextStyle(
                        fontSize: 14,
                        color: _outline.withOpacity(0.6)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Featured trip card ────────────────────────────────────────────────────────

class _FeaturedTripCard extends StatelessWidget {
  final _Trip trip;
  const _FeaturedTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip ID + status badge
          Row(
            children: [
              Text(
                'TRIP ID: ${trip.id}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: _onSurfaceVariant,
                ),
              ),
              const Spacer(),
              _StatusBadge(status: trip.status),
            ],
          ),
          const SizedBox(height: 20),

          // Route visual
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line + dots
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: _primary),
                  ),
                  SizedBox(
                    width: 2,
                    height: 52,
                    child: CustomPaint(painter: _DashedLinePainter()),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _outline, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Location labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.origin,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ),
                        if (trip.originSub.isNotEmpty)
                          Text(
                            trip.originSub,
                            style: const TextStyle(
                                fontSize: 12, color: _outline),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.destination,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ),
                        if (trip.destinationSub.isNotEmpty)
                          Text(
                            trip.destinationSub,
                            style: const TextStyle(
                                fontSize: 12, color: _outline),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Material + View Manifest button
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: _outlineVariant.withOpacity(0.3), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MATERIAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: _onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        trip.material,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    elevation: 0,
                  ),
                  child: const Text('View Manifest'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_shipping_rounded,
            value: '12',
            label: 'ACTIVE FLEET',
            dark: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule_rounded,
            value: '04',
            label: 'PENDING DETAILS',
            dark: true,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool dark;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? _primary : _surfaceContainer;
    final fg = dark ? Colors.white : _primary;
    final subFg = dark ? Colors.white70 : _onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: dark
            ? [
                BoxShadow(
                  color: _primary.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: dark ? Colors.white70 : _primary, size: 26),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: fg,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: subFg,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trip row ──────────────────────────────────────────────────────────────────

class _TripRow extends StatelessWidget {
  final _Trip trip;
  const _TripRow({required this.trip});

  @override
  Widget build(BuildContext context) {
    final isCompleted = trip.status == _TripStatus.completed;

    return Opacity(
      opacity: isCompleted ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Trip ID
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRIP ID',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _onSurfaceVariant,
                      ),
                    ),
                    Text(
                      trip.id,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Route
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ROUTE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: _onSurfaceVariant,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                          children: [
                            TextSpan(text: trip.origin),
                            const TextSpan(
                              text: ' → ',
                              style: TextStyle(
                                  color: _outline,
                                  fontWeight: FontWeight.w400),
                            ),
                            TextSpan(text: trip.destination),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: _outline, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MATERIAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _onSurfaceVariant,
                      ),
                    ),
                    Text(
                      trip.material,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _StatusBadge(status: trip.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final _TripStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      _TripStatus.inTransit => (
          'IN TRANSIT',
          _secondaryContainer,
          _onSecondaryContainer
        ),
      _TripStatus.pendingDetails => (
          'PENDING',
          _tertiaryContainer.withOpacity(0.12),
          _onTertiaryContainer
        ),
      _TripStatus.completed => (
          'COMPLETED',
          _surfaceContainer,
          _outline
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: fg,
        ),
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

// ── Dashed line painter ───────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashH = 4.0;
    const space = 4.0;
    final paint = Paint()
      ..color = _outlineVariant
      ..strokeWidth = 2;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dashH),
        paint,
      );
      y += dashH + space;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
