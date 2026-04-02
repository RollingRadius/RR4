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
  const _SectionLabel(this.text, {required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text,
            style: _inter(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _onSurfaceVariant)
                .copyWith(letterSpacing: 1.4)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8)),
          child: Text('$count',
              style: _inter(
                  size: 10, weight: FontWeight.w700, color: _navy)),
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
    if (!ok) {
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

class _TripCard extends ConsumerWidget {
  final TripModel trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      _StatusBadge(status: trip.status),
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

          // ── Footer row: View Details | Locate Trip ────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                // View Details
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => TripDetailScreen(trip: trip, readOnly: true))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 14, color: _navy),
                          const SizedBox(width: 6),
                          Text('View Details',
                              style: _inter(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: _navy)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Locate Trip (only when vehicle assigned)
                if (trip.hasVehicle)
                  Expanded(
                    child: _LocateButton(trip: trip),
                  )
                else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_rounded,
                              size: 14, color: _outline),
                          const SizedBox(width: 6),
                          Text('No Vehicle',
                              style: _inter(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: _outline)),
                        ],
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

// ── Locate button (fetches GPS then opens map) ────────────────────────────────

class _LocateButton extends ConsumerStatefulWidget {
  final TripModel trip;
  const _LocateButton({required this.trip});

  @override
  ConsumerState<_LocateButton> createState() => _LocateButtonState();
}

class _LocateButtonState extends ConsumerState<_LocateButton> {
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF6B00), Color(0xFFE55C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: _orange.withValues(alpha: 0.30),
                blurRadius: 8,
                offset: const Offset(0, 3))
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
                      color: Colors.white, size: 14),
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
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'ongoing' => (
          'IN TRANSIT',
          const Color(0xFFD5E3FC),
          const Color(0xFF0D47A1)
        ),
      'pending' =>
        ('PENDING', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      'completed' => ('DONE', const Color(0xFFECEEF0), _outline),
      _ => ('CANCELLED', const Color(0xFFFFDAD6), const Color(0xFFBA1A1A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: _inter(
                  size: 9, weight: FontWeight.w700, color: fg)
              .copyWith(letterSpacing: 0.8)),
    );
  }
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
