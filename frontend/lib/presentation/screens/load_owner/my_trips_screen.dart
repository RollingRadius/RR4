import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/providers/load_provider.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/data/models/load_requirement_model.dart';
import 'package:fleet_management/presentation/screens/trips/trip_detail_screen.dart';
import 'package:fleet_management/presentation/screens/trips/trip_locate_screen.dart';

// ── Colour tokens ─────────────────────────────────────────────────────────────
const _navy = Color(0xFF001e40);
const _orange = Color(0xFFFF6B00);
const _bg = Color(0xFFF7F9FB);
const _surface = Color(0xFFFFFFFF);
const _onSurface = Color(0xFF191C1E);
const _onSurfaceVariant = Color(0xFF43474F);
const _outlineVariant = Color(0xFFC3C6D1);
const _outline = Color(0xFF737780);
const _secondary = Color(0xFF546067);

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

// ── Screen ────────────────────────────────────────────────────────────────────

class MyTripsScreen extends ConsumerStatefulWidget {
  const MyTripsScreen({super.key});

  @override
  ConsumerState<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends ConsumerState<MyTripsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tripProvider.notifier).loadTrips();
      ref.read(loadProvider.notifier).loadLoads();
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(tripProvider.notifier).silentRefresh(),
      ref.read(loadProvider.notifier).silentRefresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final loadState = ref.watch(loadProvider);

    final sortedLoads = [...loadState.loads]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final isFirstLoad = (tripState.isLoading && tripState.trips.isEmpty) ||
        (loadState.isLoading && loadState.loads.isEmpty);
    final hasContent =
        loadState.loads.isNotEmpty || tripState.trips.isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _orange,
        onRefresh: _onRefresh,
        child: isFirstLoad
            ? const Center(child: CircularProgressIndicator(color: _orange))
            : !hasContent
                ? _EmptyState(error: loadState.error ?? tripState.error)
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Header + stats
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Header(),
                              const SizedBox(height: 20),
                              _StatsRow(
                                loads: loadState.loads.length,
                                ongoing: tripState.ongoingTrips.length,
                                completed: tripState.completedTrips.length,
                              ),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),

                      // ── Posted Loads section ────────────────────────
                      if (loadState.loads.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _SectionLabel(
                                'POSTED LOADS',
                                count: loadState.loads.length),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: _LoadCard(load: sortedLoads[i]),
                            ),
                            childCount: sortedLoads.length,
                          ),
                        ),
                        const SliverToBoxAdapter(
                            child: SizedBox(height: 8)),
                      ],

                      // ── Active fleet trips section ──────────────────
                      if (tripState.ongoingTrips.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _SectionLabel(
                                'ACTIVE TRIPS',
                                count: tripState.ongoingTrips.length),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: _TripCard(
                                  trip: tripState.ongoingTrips[i]),
                            ),
                            childCount: tripState.ongoingTrips.length,
                          ),
                        ),
                        const SliverToBoxAdapter(
                            child: SizedBox(height: 8)),
                      ],

                      // ── Completed trips section ─────────────────────
                      if (tripState.completedTrips.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _SectionLabel(
                                'COMPLETED TRIPS',
                                count: tripState.completedTrips.length),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: Opacity(
                                opacity: 0.65,
                                child: _TripCard(
                                    trip: tripState.completedTrips[i]),
                              ),
                            ),
                            childCount: tripState.completedTrips.length,
                          ),
                        ),
                      ],

                      // ── Cancelled trips section ─────────────────────
                      if (tripState.cancelledTrips.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _SectionLabel(
                                'CANCELLED TRIPS',
                                count: tripState.cancelledTrips.length,
                                danger: true),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: Opacity(
                                opacity: 0.55,
                                child: _TripCard(
                                    trip: tripState.cancelledTrips[i]),
                              ),
                            ),
                            childCount: tripState.cancelledTrips.length,
                          ),
                        ),
                      ],

                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
      ),
    );
  }
}


// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LOGISTICS OVERVIEW',
            style: _inter(
                    size: 10, weight: FontWeight.w700, color: _onSurfaceVariant)
                .copyWith(letterSpacing: 1.8)),
        const SizedBox(height: 4),
        Text('Trips',
            style: _manrope(
                size: 38, weight: FontWeight.w900, color: _navy)),
      ],
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int loads, ongoing, completed;
  const _StatsRow(
      {required this.loads, required this.ongoing, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
              icon: Icons.assignment_outlined,
              value: '$loads',
              label: 'POSTED',
              dark: true),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
              icon: Icons.local_shipping_rounded,
              value: '$ongoing',
              label: 'ACTIVE',
              dark: false),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
              icon: Icons.check_circle_outline_rounded,
              value: '$completed',
              label: 'DONE',
              dark: false),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final bool dark;

  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    final bg = dark ? _navy : const Color(0xFFECEEF0);
    final fg = dark ? Colors.white : _navy;
    final subFg = dark ? Colors.white70 : _onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: dark
            ? [
                BoxShadow(
                    color: _navy.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4))
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: dark ? Colors.white70 : _navy, size: 24),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: fg,
                  height: 1.0)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: subFg)),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final int count;
  final bool danger;
  const _SectionLabel(this.text, {required this.count, this.danger = false});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFBA1A1A);
    final labelColor = danger ? red : _onSurfaceVariant;
    final badgeBg = danger
        ? const Color(0xFFFFDAD6)
        : _navy.withValues(alpha: 0.10);
    final badgeFg = danger ? red : _navy;

    return Row(
      children: [
        if (danger) ...[
          const Icon(Icons.cancel_rounded, size: 13, color: red),
          const SizedBox(width: 5),
        ],
        Text(text,
            style: _inter(
                    size: 11,
                    weight: FontWeight.w700,
                    color: labelColor)
                .copyWith(letterSpacing: 1.4)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8)),
          child: Text('$count',
              style: _inter(
                  size: 10, weight: FontWeight.w700, color: badgeFg)),
        ),
      ],
    );
  }
}

// ── Load Card ─────────────────────────────────────────────────────────────────

class _LoadCard extends ConsumerStatefulWidget {
  final LoadRequirementModel load;
  const _LoadCard({required this.load});

  @override
  ConsumerState<_LoadCard> createState() => _LoadCardState();
}

class _LoadCardState extends ConsumerState<_LoadCard> {
  bool _cancelling = false;

  void _showDetails(BuildContext context) {
    final load = widget.load;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Load Details',
                    style: _manrope(
                        size: 17, weight: FontWeight.w800, color: _navy)),
                const Spacer(),
                _LoadStatusBadge(status: load.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(load.refId,
                style: _inter(
                    size: 12, weight: FontWeight.w600, color: _onSurfaceVariant)),
            const Divider(height: 24),
            _RouteVisual(
              origin: load.pickupLocation ?? '—',
              destination: load.unloadLocation ?? '—',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                if (load.materialType != null)
                  _MiniField(label: 'MATERIAL', value: load.materialType!),
                _MiniField(label: 'TRUCKS', value: '${load.truckCount}'),
                if (load.entryDate != null)
                  _MiniField(label: 'ENTRY DATE', value: load.entryDate!),
                if (load.capacity != null)
                  _MiniField(label: 'CAPACITY', value: load.capacity!),
                if (load.axelType != null)
                  _MiniField(label: 'AXEL TYPE', value: load.axelType!),
                if (load.bodyType != null)
                  _MiniField(label: 'BODY TYPE', value: load.bodyType!),
                _MiniField(label: 'POSTED ON', value: load.displayDate),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _track(BuildContext context) {
    final trips = ref.read(tripProvider).trips;
    final pickup = widget.load.pickupLocation;
    TripModel? match;
    if (pickup != null) {
      try {
        match = trips.firstWhere((t) =>
            t.origin.toLowerCase().contains(pickup.toLowerCase()) ||
            pickup.toLowerCase().contains(t.origin.toLowerCase()));
      } catch (_) {
        match = null;
      }
    }
    if (match != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TripLocateScreen(trip: match!, location: null),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No active trip assigned to this load yet.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _navy,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Load',
            style: _manrope(size: 16, weight: FontWeight.w700, color: _navy)),
        content: Text(
          'Are you sure you want to cancel ${widget.load.refId}? This cannot be undone.',
          style: _inter(size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep', style: _manrope(size: 13, color: _onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cancel Load',
                style: _manrope(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFFBA1A1A))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    final ok =
        await ref.read(loadProvider.notifier).cancelLoad(widget.load.id);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (ok) {
      // If the load had a linked trip, the backend also cancelled it.
      // Refresh tripProvider so the cancelled trip appears in the dashboard.
      ref.read(tripProvider.notifier).silentRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(loadProvider).error ?? 'Failed to cancel.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final load = widget.load;
    final isCancelled = load.status == 'cancelled';

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // ── Card body ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ref ID + status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LOAD REF',
                              style: _inter(
                                      size: 9,
                                      weight: FontWeight.w700,
                                      color: _onSurfaceVariant)
                                  .copyWith(letterSpacing: 1.2)),
                          Text(load.refId,
                              style: _manrope(
                                  size: 15,
                                  weight: FontWeight.w800,
                                  color: _navy)),
                        ],
                      ),
                    ),
                    _LoadStatusBadge(status: load.status),
                  ],
                ),
                const SizedBox(height: 16),
                _RouteVisual(
                  origin: load.pickupLocation ?? '—',
                  destination: load.unloadLocation ?? '—',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    if (load.materialType != null)
                      _MiniField(label: 'MATERIAL', value: load.materialType!),
                    _MiniField(label: 'TRUCKS', value: '${load.truckCount}'),
                    if (load.entryDate != null)
                      _MiniField(label: 'DATE', value: load.entryDate!),
                    if (load.capacity != null)
                      _MiniField(label: 'CAPACITY', value: load.capacity!),
                    if (load.axelType != null)
                      _MiniField(label: 'AXEL', value: load.axelType!),
                    if (load.bodyType != null)
                      _MiniField(label: 'BODY', value: load.bodyType!),
                  ],
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────
          Divider(
              height: 1,
              color: _outlineVariant.withValues(alpha: 0.5),
              indent: 18,
              endIndent: 18),

          // ── Action buttons ────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                // View Details
                Expanded(
                  child: InkWell(
                    onTap: () => _showDetails(context),
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: _onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('Details',
                              style: _inter(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: _onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
                VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: _outlineVariant.withValues(alpha: 0.5)),

                // Track
                Expanded(
                  child: InkWell(
                    onTap: () => _track(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 14, color: _orange),
                          const SizedBox(width: 4),
                          Text('Track',
                              style: _inter(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: _orange)),
                        ],
                      ),
                    ),
                  ),
                ),
                VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: _outlineVariant.withValues(alpha: 0.5)),

                // Cancel
                Expanded(
                  child: InkWell(
                    onTap: (isCancelled || _cancelling)
                        ? null
                        : () => _confirmCancel(context),
                    borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      child: _cancelling
                          ? const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFBA1A1A)),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel_outlined,
                                    size: 14,
                                    color: isCancelled
                                        ? _outlineVariant
                                        : const Color(0xFFBA1A1A)),
                                const SizedBox(width: 4),
                                Text('Cancel',
                                    style: _inter(
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: isCancelled
                                            ? _outlineVariant
                                            : const Color(0xFFBA1A1A))),
                              ],
                            ),
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

class _LoadStatusBadge extends StatelessWidget {
  final String status;
  const _LoadStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'active' => (
          'ACTIVE',
          const Color(0xFFD5E3FC),
          const Color(0xFF0D47A1)
        ),
      'completed' => ('DONE', const Color(0xFFECEEF0), _outline),
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

// ── Trip Card ─────────────────────────────────────────────────────────────────

class _TripCard extends ConsumerStatefulWidget {
  final TripModel trip;
  const _TripCard({required this.trip});

  @override
  ConsumerState<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends ConsumerState<_TripCard> {
  bool _cancelling = false;
  bool _locating = false;

  Future<void> _locate(BuildContext context) async {
    setState(() => _locating = true);
    final loc = await ref
        .read(tripProvider.notifier)
        .fetchTripLocation(widget.trip.id);
    if (!mounted) return;
    setState(() => _locating = false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TripLocateScreen(trip: widget.trip, location: loc),
    ));
  }

  Future<void> _confirmCancelAndDelete(BuildContext context) async {
    final trip = widget.trip;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDAD6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_rounded,
              color: Color(0xFFBA1A1A), size: 28),
        ),
        title: Text(
          'Cancel & Delete Trip',
          style: _manrope(size: 16, weight: FontWeight.w800, color: _navy),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trip ${trip.tripNumber} will be permanently cancelled and all its data will be deleted.',
              style: _inter(size: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: _inter(
                          size: 11,
                          weight: FontWeight.w600,
                          color: Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: Color(0xFFC3C6D1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Keep Trip',
                      style: _manrope(
                          size: 13,
                          weight: FontWeight.w700,
                          color: _navy)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA1A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text('Cancel Trip',
                      style: _manrope(
                          size: 13,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final ok = await ref
        .read(tripProvider.notifier)
        .cancelTrip(widget.trip.id);
    if (!mounted) return;
    setState(() => _cancelling = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(tripProvider).error ?? 'Failed to cancel trip.',
            style: _inter(size: 13, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final isCancelled = trip.isCancelled;
    final isCompleted = trip.isCompleted;
    final canCancel = !isCancelled && !isCompleted && !_cancelling;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // ── Main content (tap → detail) ───────────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TripDetailScreen(trip: trip, readOnly: true))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip ID + status
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
                                        color: _onSurfaceVariant)
                                    .copyWith(letterSpacing: 1.2)),
                            Text(trip.tripNumber,
                                style: _manrope(
                                    size: 15,
                                    weight: FontWeight.w800,
                                    color: _navy)),
                          ],
                        ),
                      ),
                      _StatusBadge(trip: trip),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Route with dashed connector
                  _RouteVisual(origin: trip.origin, destination: trip.destination),
                  const SizedBox(height: 16),

                  // Info grid: item, weight, bilty, amount
                  _InfoGrid(trip: trip),
                ],
              ),
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────
          Divider(
              height: 1,
              color: _outlineVariant.withValues(alpha: 0.5),
              indent: 18,
              endIndent: 18),

          // ── Footer row: View Details | Locate Trip | Cancel ───────────
          IntrinsicHeight(
            child: Row(
              children: [
                // View Details
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            TripDetailScreen(trip: trip, readOnly: true))),
                    borderRadius:
                        const BorderRadius.only(bottomLeft: Radius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 14, color: _navy),
                          const SizedBox(width: 4),
                          Text('Details',
                              style: _inter(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: _navy)),
                        ],
                      ),
                    ),
                  ),
                ),

                VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: _outlineVariant.withValues(alpha: 0.5)),

                // Locate Trip
                Expanded(
                  child: InkWell(
                    onTap: (trip.hasVehicle && !_locating)
                        ? () => _locate(context)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      child: _locating
                          ? const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _orange),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  trip.hasVehicle
                                      ? Icons.location_on_rounded
                                      : Icons.location_off_rounded,
                                  size: 14,
                                  color: trip.hasVehicle ? _orange : _outline,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  trip.hasVehicle ? 'Track' : 'No Vehicle',
                                  style: _inter(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color:
                                          trip.hasVehicle ? _orange : _outline),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: _outlineVariant.withValues(alpha: 0.5)),

                // Cancel Trip
                Expanded(
                  child: InkWell(
                    onTap: canCancel
                        ? () => _confirmCancelAndDelete(context)
                        : null,
                    borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      child: _cancelling
                          ? const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFBA1A1A)),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isCancelled
                                      ? Icons.cancel_rounded
                                      : isCompleted
                                          ? Icons.lock_outline_rounded
                                          : Icons.cancel_outlined,
                                  size: 14,
                                  color: (isCancelled || isCompleted)
                                      ? _outlineVariant
                                      : const Color(0xFFBA1A1A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCancelled
                                      ? 'Cancelled'
                                      : isCompleted
                                          ? 'Completed'
                                          : 'Cancel',
                                  style: _inter(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: (isCancelled || isCompleted)
                                          ? _outlineVariant
                                          : const Color(0xFFBA1A1A)),
                                ),
                              ],
                            ),
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


// ── Route visual ──────────────────────────────────────────────────────────────

class _RouteVisual extends StatelessWidget {
  final String origin, destination;
  const _RouteVisual({required this.origin, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dots + dashed line
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  const BoxDecoration(shape: BoxShape.circle, color: _orange),
            ),
            SizedBox(
              width: 2,
              height: 28,
              child: CustomPaint(
                  painter: _DashedLinePainter(color: _outlineVariant)),
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
                  style: _manrope(size: 13, weight: FontWeight.w700, color: _navy),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Text(destination,
                  style: _manrope(size: 13, weight: FontWeight.w700, color: _navy),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info grid ─────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final TripModel trip;
  const _InfoGrid({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
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
              highlight: true),
      ],
    );
  }
}

class _MiniField extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _MiniField(
      {required this.label,
      required this.value,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: _inter(
                    size: 9,
                    weight: FontWeight.w700,
                    color: _onSurfaceVariant)
                .copyWith(letterSpacing: 1.2)),
        const SizedBox(height: 2),
        Text(value,
            style: _manrope(
                size: 13,
                weight: FontWeight.w700,
                color: highlight
                    ? const Color(0xFF2E7D32)
                    : _navy)),
      ],
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final TripModel trip;
  const _StatusBadge({required this.trip});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _tripState(trip);
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

(String, Color, Color) _tripState(TripModel trip) {
  if (trip.isCancelled) return ('CANCELLED', const Color(0xFFFFDAD6), const Color(0xFFBA1A1A));
  if (trip.isCompleted) return ('COMPLETED', const Color(0xFFECEEF0), const Color(0xFF546067));
  if (trip.currentStage >= 4) return ('IN TRANSIT', const Color(0xFFD7F0D9), const Color(0xFF1B5E20));
  if (trip.currentStage >= 1) return ('ONGOING', const Color(0xFFFFE8D5), const Color(0xFFFF6B00));
  return ('PENDING', const Color(0xFFFFF3E0), const Color(0xFFE65100));
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? error;
  const _EmptyState({this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error != null
                  ? Icons.error_outline_rounded
                  : Icons.local_shipping_outlined,
              color: _outline,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              error != null ? 'Could not load trips' : 'No trips yet',
              style: _manrope(size: 16, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Trips assigned to your loads will appear here.',
              textAlign: TextAlign.center,
              style: _inter(size: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed line ───────────────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

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
