import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/presentation/screens/trips/trip_locate_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _primary = Color(0xFFFF6B00);
const _bg = Color(0xFFF8F9FB);
const _surface = Color(0xFFFFFFFF);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _outlineVariant = Color(0xFFCDD0D5);

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

class TripDetailScreen extends ConsumerWidget {
  final TripModel trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: _bg,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: _onSurface, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.tripNumber,
                    style: _manrope(size: 15, weight: FontWeight.w800)),
                Text('Trip Details',
                    style: _inter(size: 11)),
              ],
            ),
            actions: [
              _StatusChip(status: trip.status),
              const SizedBox(width: 16),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Route card ──────────────────────────────────────────────
                  _RouteCard(trip: trip),
                  const SizedBox(height: 14),

                  // ── Locate Trip button ───────────────────────────────────────
                  if (trip.hasVehicle) ...[
                    _LocateTripButton(trip: trip),
                    const SizedBox(height: 14),
                  ],

                  // ── Cargo details ────────────────────────────────────────────
                  _SectionCard(
                    title: 'Cargo Details',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      _InfoRow(label: 'Load Item', value: trip.loadItem),
                      if (trip.weight != null)
                        _InfoRow(label: 'Weight', value: trip.weight!),
                      if (trip.biltyNumber != null)
                        _InfoRow(
                            label: 'Bilty Number', value: trip.biltyNumber!),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Financial details ─────────────────────────────────────────
                  _SectionCard(
                    title: 'Financial Details',
                    icon: Icons.receipt_long_outlined,
                    children: [
                      if (trip.tripAmount != null)
                        _InfoRow(
                          label: 'Trip Amount',
                          value:
                              '₹ ${trip.tripAmount!.toStringAsFixed(2)}',
                          valueStyle: _manrope(
                              size: 15,
                              weight: FontWeight.w800,
                              color: const Color(0xFF2E7D32)),
                        ),
                      if (trip.invoiceNumber != null)
                        _InfoRow(
                            label: 'Invoice Number',
                            value: trip.invoiceNumber!),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Logistics ────────────────────────────────────────────────
                  _SectionCard(
                    title: 'Logistics',
                    icon: Icons.local_shipping_outlined,
                    children: [
                      if (trip.vehiclePlate != null)
                        _InfoRow(
                            label: 'Vehicle',
                            value:
                                '${trip.vehiclePlate!}${trip.vehicleModel != null ? ' — ${trip.vehicleModel}' : ''}'),
                      if (trip.driverName != null)
                        _InfoRow(
                            label: 'Driver', value: trip.driverName!),
                      if (trip.startDate != null)
                        _InfoRow(
                            label: 'Start Date', value: trip.startDate!),
                      if (trip.endDate != null)
                        _InfoRow(
                            label: 'End Date', value: trip.endDate!),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Identifiers ──────────────────────────────────────────────
                  _SectionCard(
                    title: 'Identifiers',
                    icon: Icons.tag_rounded,
                    children: [
                      _InfoRow(label: 'Trip Number', value: trip.tripNumber),
                      if (trip.biltyNumber != null)
                        _InfoRow(
                            label: 'Bilty Number', value: trip.biltyNumber!),
                      _InfoRow(label: 'Status', value: trip.status.toUpperCase()),
                      if (trip.createdAt != null)
                        _InfoRow(
                          label: 'Created',
                          value: trip.createdAt!.split('T').first,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Route card ───────────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final TripModel trip;
  const _RouteCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ROUTE',
              style: _inter(size: 10, weight: FontWeight.w700,
                  color: _secondary)
                  .copyWith(letterSpacing: 1.4)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashed line
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
                    height: 48,
                    child: CustomPaint(
                        painter: _DashedLinePainter(color: _outlineVariant)),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _secondary, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.origin,
                        style: _manrope(
                            size: 16, weight: FontWeight.w800)),
                    if (trip.originSub != null)
                      Text(trip.originSub!,
                          style: _inter(size: 12)),
                    const SizedBox(height: 24),
                    Text(trip.destination,
                        style: _manrope(
                            size: 16, weight: FontWeight.w800)),
                    if (trip.destinationSub != null)
                      Text(trip.destinationSub!,
                          style: _inter(size: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Locate Trip button ───────────────────────────────────────────────────────

class _LocateTripButton extends ConsumerStatefulWidget {
  final TripModel trip;
  const _LocateTripButton({required this.trip});

  @override
  ConsumerState<_LocateTripButton> createState() => _LocateTripButtonState();
}

class _LocateTripButtonState extends ConsumerState<_LocateTripButton> {
  bool _loading = false;

  Future<void> _locate() async {
    setState(() => _loading = true);
    final loc = await ref
        .read(tripProvider.notifier)
        .fetchTripLocation(widget.trip.id);
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TripLocateScreen(trip: widget.trip, location: loc),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _locate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFE55C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.location_on_rounded,
                      color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Locate Trip',
                      style: _manrope(
                          size: 15,
                          weight: FontWeight.w800,
                          color: Colors.white)),
                  Text(
                    _loading ? 'Fetching GPS location…' : 'View vehicle on live map',
                    style: _inter(
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.80)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.map_rounded, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _primary),
              const SizedBox(width: 8),
              Text(title,
                  style: _manrope(
                      size: 13, weight: FontWeight.w700, color: _secondary)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _outlineVariant),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: _inter(size: 12, color: _secondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  _manrope(size: 13, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'ongoing' => (
          'ONGOING',
          const Color(0xFFD7F0D9),
          const Color(0xFF1B5E20)
        ),
      'pending' => (
          'PENDING',
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100)
        ),
      'completed' => ('DONE', const Color(0xFFECEEF0), _secondary),
      _ => ('CANCELLED', const Color(0xFFFFDAD6), const Color(0xFFBA1A1A)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: _inter(
              size: 10,
              weight: FontWeight.w700,
              color: fg)),
    );
  }
}

// ─── Dashed line ──────────────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 4.0, space = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y),
          Offset(size.width / 2, y + dash), paint);
      y += dash + space;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
