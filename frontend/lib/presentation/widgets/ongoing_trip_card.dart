/// Shared ongoing trip card widget — used by both fleet owner and load owner dashboards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/presentation/screens/trips/trip_detail_screen.dart';
import 'package:fleet_management/presentation/screens/trips/trip_locate_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _primary = Color(0xFFFF6B00);
const _navy = Color(0xFF001E40);
const _surface = Color(0xFFFFFFFF);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _outlineVariant = Color(0xFFCDD0D5);
const _outline = Color(0xFF737780);

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

// ─── Ongoing trip card ────────────────────────────────────────────────────────

class OngoingTripCard extends ConsumerWidget {
  final TripModel trip;
  const OngoingTripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
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
        children: [
          // ── Tappable body → TripDetailScreen ──────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TripDetailScreen(trip: trip))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: trip number + status badge
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TRIP NUMBER',
                                style: _inter(
                                        size: 9,
                                        weight: FontWeight.w700,
                                        color: _secondary)
                                    .copyWith(letterSpacing: 1.2)),
                            Text(trip.tripNumber,
                                style: _manrope(
                                    size: 15,
                                    weight: FontWeight.w800,
                                    color: _primary)),
                          ],
                        ),
                      ),
                      _StatusBadge(status: trip.status),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Route: origin → destination with dashed connector
                  _RouteRow(
                      origin: trip.origin, destination: trip.destination),
                  const SizedBox(height: 14),

                  // Details: load item, weight, bilty number, trip amount
                  _DetailsRow(trip: trip),
                ],
              ),
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────
          Divider(
              height: 1,
              color: _outlineVariant.withValues(alpha: 0.5),
              indent: 18,
              endIndent: 18),

          // ── Action buttons ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                // View Details
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => TripDetailScreen(trip: trip))),
                    child: _ActionChip(
                      icon: Icons.receipt_long_outlined,
                      label: 'View Details',
                      color: _onSurface,
                      bg: const Color(0xFFF2F4F6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Locate Trip
                Expanded(
                  child: trip.hasVehicle
                      ? _LocateBtn(trip: trip)
                      : _ActionChip(
                          icon: Icons.location_off_rounded,
                          label: 'No Vehicle',
                          color: _outline,
                          bg: const Color(0xFFF2F4F6),
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

// ─── Locate button — fetches GPS then opens map ───────────────────────────────

class _LocateBtn extends ConsumerStatefulWidget {
  final TripModel trip;
  const _LocateBtn({required this.trip});

  @override
  ConsumerState<_LocateBtn> createState() => _LocateBtnState();
}

class _LocateBtnState extends ConsumerState<_LocateBtn> {
  bool _loading = false;

  Future<void> _go() async {
    setState(() => _loading = true);
    final loc = await ref
        .read(tripProvider.notifier)
        .fetchTripLocation(widget.trip.id);
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          TripLocateScreen(trip: widget.trip, location: loc),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _go,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFE55C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _loading
              ? [
                  const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                ]
              : [
                  const Icon(Icons.location_on_rounded,
                      color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text('Locate Trip',
                      style: _inter(
                          size: 12,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class OngoingTripsSectionHeader extends StatelessWidget {
  final int count;
  final VoidCallback? onViewAll;

  const OngoingTripsSectionHeader({
    super.key,
    required this.count,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ongoing Trips',
                  style: _manrope(size: 17, weight: FontWeight.w800)),
              Text('$count trip${count == 1 ? '' : 's'} in transit',
                  style: _inter(size: 12)),
            ],
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text('View all',
                style: _inter(
                    size: 13,
                    weight: FontWeight.w700,
                    color: _primary)),
          ),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _RouteRow extends StatelessWidget {
  final String origin, destination;
  const _RouteRow({required this.origin, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dots + dashed connector
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: _primary),
            ),
            SizedBox(
              width: 2,
              height: 22,
              child: CustomPaint(
                  painter: _DashedPainter(color: _outlineVariant)),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _outline, width: 2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(origin,
                  style: _manrope(size: 13, weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Text(destination,
                  style: _manrope(size: 13, weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsRow extends StatelessWidget {
  final TripModel trip;
  const _DetailsRow({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _MiniField(label: 'LOAD ITEM', value: trip.loadItem),
        if (trip.weight != null)
          _MiniField(label: 'WEIGHT', value: trip.weight!),
        if (trip.biltyNumber != null)
          _MiniField(label: 'BILTY NO.', value: trip.biltyNumber!),
        if (trip.invoiceNumber != null)
          _MiniField(label: 'INVOICE', value: trip.invoiceNumber!),
        if (trip.tripAmount != null)
          _MiniField(
            label: 'AMOUNT',
            value: '₹${trip.tripAmount!.toStringAsFixed(0)}',
            highlight: true,
          ),
      ],
    );
  }
}

class _MiniField extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _MiniField(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                _inter(size: 9, weight: FontWeight.w700, color: _secondary)
                    .copyWith(letterSpacing: 1.2)),
        const SizedBox(height: 2),
        Text(value,
            style: _manrope(
                size: 12,
                weight: FontWeight.w700,
                color: highlight
                    ? const Color(0xFF2E7D32)
                    : _onSurface)),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bg;
  const _ActionChip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: _inter(size: 12, weight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'ongoing' => (
          'IN TRANSIT',
          const Color(0xFFD7F0D9),
          const Color(0xFF1B5E20)
        ),
      'pending' =>
        ('PENDING', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      'completed' => ('DONE', const Color(0xFFECEEF0), _secondary),
      _ => ('CANCELLED', const Color(0xFFFFDAD6), const Color(0xFFBA1A1A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: _inter(size: 9, weight: FontWeight.w700, color: fg)
              .copyWith(letterSpacing: 0.6)),
    );
  }
}

class _DashedPainter extends CustomPainter {
  final Color color;
  const _DashedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 3.0, space = 3.0;
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
