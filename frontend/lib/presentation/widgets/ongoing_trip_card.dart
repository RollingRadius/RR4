/// Shared ongoing trip card widget — used by both fleet owner and load owner dashboards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/presentation/screens/trips/trip_detail_screen.dart';
import 'package:fleet_management/presentation/screens/trips/trip_locate_screen.dart';
import 'package:fleet_management/presentation/screens/fleet_owner/trip_stages_screen.dart';

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
  /// When true, hides all fleet management actions (load owner view).
  final bool readOnly;
  /// When true, restricts to worker-level actions only — hides LP-owner-only features.
  final bool workerMode;
  /// When provided, shows a "Complete Trip" button (LP owner dashboard only).
  final Future<bool> Function()? onComplete;
  const OngoingTripCard({super.key, required this.trip, this.readOnly = false, this.workerMode = false, this.onComplete});

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
                builder: (_) => TripDetailScreen(trip: trip, readOnly: readOnly))),
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
                      _StatusBadge(trip: trip),
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

          // ── Stage progress strip ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
            child: _StageStrip(trip: trip),
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
            child: Column(
              children: [
                Row(
                  children: [
                    // View Details
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => TripDetailScreen(trip: trip, readOnly: readOnly))),
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

                // Stage sliding panel — LP owner only
                if (!readOnly && !workerMode) ...[
                  const SizedBox(height: 8),
                  _StageSlidingPanel(
                    trip: trip,
                    onRefresh: () => ref
                        .read(tripProvider.notifier)
                        .loadTrips(statusFilter: 'ongoing,pending'),
                  ),
                ],

                // Go to Present Stage — fleet management only (hidden for load owners)
                if (!readOnly && trip.currentStage < 4) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => TripStagesScreen(trip: trip)))
                        .then((_) {
                      ref
                          .read(tripProvider.notifier)
                          .loadTrips(statusFilter: 'ongoing,pending');
                    }),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF001E40), Color(0xFF003070)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Go to Stage ${_visualStageLabel(trip)}  ·  ${_stageName(trip)}',
                            style: _inter(
                                size: 12,
                                weight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Complete Trip — LP owner dashboard only, hidden once completed/cancelled
                if (onComplete != null &&
                    trip.status != 'completed' &&
                    trip.status != 'cancelled') ...[
                  const SizedBox(height: 8),
                  _CompleteBtn(
                    onComplete: onComplete!,
                    enabled: trip.currentStage >= 5,
                  ),
                ],

                // Completed banner — shown on LP owner dashboard when trip is done
                if (onComplete != null && trip.status == 'completed') ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7F0D9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF1B5E20), size: 16),
                        const SizedBox(width: 6),
                        Text('Trip Completed',
                            style: _inter(
                                size: 12,
                                weight: FontWeight.w700,
                                color: const Color(0xFF1B5E20))),
                      ],
                    ),
                  ),
                ],
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

// ─── Complete trip button ─────────────────────────────────────────────────────

class _CompleteBtn extends StatefulWidget {
  final Future<bool> Function() onComplete;
  final bool enabled;
  const _CompleteBtn({required this.onComplete, this.enabled = true});

  @override
  State<_CompleteBtn> createState() => _CompleteBtnState();
}

class _CompleteBtnState extends State<_CompleteBtn> {
  bool _loading = false;

  Future<void> _confirm() async {
    if (!widget.enabled) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete Trip?'),
        content: const Text(
            'This will mark the trip as completed and notify the load owner. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    final ok = await widget.onComplete();
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trip marked as completed. Load owner notified.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && !_loading;
    final bgColors = widget.enabled
        ? [const Color(0xFF2E7D32), const Color(0xFF388E3C)]
        : [const Color(0xFFBDBDBD), const Color(0xFF9E9E9E)];
    return Tooltip(
      message: widget.enabled ? '' : 'Complete Trip is only available after Stage 5',
      child: GestureDetector(
        onTap: canTap ? _confirm : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bgColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
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
                    Icon(
                      widget.enabled
                          ? Icons.check_circle_outline_rounded
                          : Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text('Complete Trip',
                        style: _inter(
                            size: 12,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                  ],
          ),
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
  final TripModel trip;
  const _StatusBadge({required this.trip});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _tripState(trip);
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

/// Returns (label, background, foreground) for a trip based on the 5-state logic.
(String, Color, Color) _tripState(TripModel trip) {
  if (trip.isCancelled) {
    return ('CANCELLED', const Color(0xFFFFDAD6), const Color(0xFFBA1A1A));
  }
  if (trip.isCompleted) {
    return ('COMPLETED', const Color(0xFFECEEF0), const Color(0xFF546067));
  }
  if (trip.currentStage >= 4) {
    return ('IN TRANSIT', const Color(0xFFD7F0D9), const Color(0xFF1B5E20));
  }
  if (trip.currentStage >= 1) {
    return ('ONGOING', const Color(0xFFFFE8D5), const Color(0xFFFF6B00));
  }
  return ('PENDING', const Color(0xFFFFF3E0), const Color(0xFFE65100));
}

/// Maps a trip to a display label for the current stage (1–5).
String _visualStageLabel(TripModel trip) {
  if (trip.currentStage == 0) return '1';
  if (trip.currentStage == 1) return '2';
  if (trip.currentStage == 2) return '3';
  if (trip.currentStage == 3) return '4';
  return '5';
}

/// 0-based visual stage index used for the strip indicator.
int _visualStageIndex(TripModel trip) {
  if (trip.currentStage == 0) return 0;
  if (trip.currentStage == 1) return 1;
  if (trip.currentStage == 2) return 2;
  if (trip.currentStage == 3) return 3;
  return 4;
}

String _stageName(TripModel trip) {
  return switch (trip.currentStage) {
    0 => 'Truck Registration',
    1 => 'Compliance Check',
    2 => 'Factory Arrival',
    3 => 'Exit Check',
    4 => 'Diesel Receipt',
    _ => 'Unloading',
  };
}

// ─── Mini stage progress strip ────────────────────────────────────────────────

class _StageStrip extends StatefulWidget {
  final TripModel trip;
  const _StageStrip({required this.trip});

  static const _labels = ['Details', 'Compliance', 'Arrival', 'Exit', 'Unloading'];
  static const _green  = Color(0xFF2E7D32);

  @override
  State<_StageStrip> createState() => _StageStripState();
}

class _StageStripState extends State<_StageStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visualIdx = _visualStageIndex(widget.trip);
    const green = _StageStrip._green;

    return Row(
      children: List.generate(5, (i) {
        final isDone   = visualIdx > i;
        final isActive = visualIdx == i;
        final dotColor  = isDone ? green : isActive ? _primary : _outlineVariant;
        final textColor = isDone ? green : isActive ? _primary : _outline;

        final dot = Column(
          children: [
            isActive
                ? AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primary.withValues(alpha: 0.12),
                        border: Border.all(color: _primary, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.25 + _pulseAnim.value * 0.30),
                            blurRadius: 5 + _pulseAnim.value * 6,
                            spreadRadius: _pulseAnim.value * 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: _inter(size: 8, weight: FontWeight.w700, color: _primary),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? green.withValues(alpha: 0.12)
                          : _outlineVariant.withValues(alpha: 0.5),
                      border: Border.all(color: dotColor, width: isDone ? 1.5 : 1),
                      boxShadow: isDone
                          ? [BoxShadow(color: green.withValues(alpha: 0.40), blurRadius: 6, spreadRadius: 1)]
                          : [],
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded, size: 10, color: _StageStrip._green)
                          : Text(
                              '${i + 1}',
                              style: _inter(size: 8, weight: FontWeight.w700, color: textColor),
                            ),
                    ),
                  ),
            const SizedBox(height: 3),
            Text(
              _StageStrip._labels[i],
              style: _inter(size: 7, weight: FontWeight.w500, color: textColor),
            ),
          ],
        );

        if (i == 4) return dot;

        return Expanded(
          child: Row(
            children: [
              dot,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    height: isDone ? 2 : 1.5,
                    decoration: BoxDecoration(
                      color: isDone ? green : _outlineVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: isDone
                          ? [BoxShadow(color: green.withValues(alpha: 0.35), blurRadius: 4)]
                          : [],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Stage sliding panel ──────────────────────────────────────────────────────

class _StageSlidingPanel extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onRefresh;
  const _StageSlidingPanel({required this.trip, required this.onRefresh});

  static const _shortLabels = ['1', '2', '3', '4', '5'];
  static const _names = ['Details', 'Compliance', 'Arrival', 'Exit', 'Unloading'];
  static const _green = Color(0xFF2E7D32);

  /// Maps a visual stage index (0–5) to the relevant submitted-by username.
  String? _usernameForStage(int i) {
    switch (i) {
      case 0: return trip.s1SubmittedByUsername;
      case 1: return trip.s2SubmittedByUsername;
      case 2: return trip.s3SubmittedByUsername;
      case 3: return trip.s4SubmittedByUsername;
      case 4: return trip.s5SubmittedByUsername;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVisual = _visualStageIndex(trip);

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isDone    = currentVisual > i;
          final isActive  = currentVisual == i;
          final submitter = isDone ? _usernameForStage(i) : null;

          final bg = isDone
              ? _green.withValues(alpha: 0.08)
              : isActive
                  ? _primary.withValues(alpha: 0.08)
                  : const Color(0xFFF2F4F6);
          final borderColor = isDone
              ? _green
              : isActive
                  ? _primary
                  : _outlineVariant;
          final labelColor = isDone
              ? _green
              : isActive
                  ? _primary
                  : _outline;

          return GestureDetector(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (_) => TripStagesScreen(trip: trip, initialStage: i)))
                .then((_) => onRefresh()),
            child: Container(
              width: 78,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: borderColor, width: isDone || isActive ? 1.5 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? _green
                          : isActive
                              ? _primary
                              : _outlineVariant,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded,
                              size: 13, color: Colors.white)
                          : Text(
                              _shortLabels[i],
                              style: _inter(
                                  size: 9,
                                  weight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _names[i],
                    style: _inter(
                        size: 9, weight: FontWeight.w600, color: labelColor),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDone ? 'Done' : isActive ? 'Active' : 'Pending',
                    style: _inter(
                        size: 8, weight: FontWeight.w500, color: labelColor),
                  ),
                  if (submitter != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@$submitter',
                      style: _inter(
                          size: 7,
                          weight: FontWeight.w600,
                          color: _green),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
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
