import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/providers/rr_session_provider.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/presentation/widgets/rr_trip_card.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/presentation/screens/trips/create_trip_screen.dart';
import 'package:fleet_management/providers/trip_provider.dart' show completedTripsProvider;

// ─── Design tokens ────────────────────────────────────────────────────────────
const _rrBlue     = Color(0xFF1B6CA8);
const _rrBlueDark = Color(0xFF154E80);
const _bg         = Color(0xFFF0F5FB);
const _surface    = Color(0xFFFFFFFF);
const _onSurface  = Color(0xFF191C1E);
const _secondary  = Color(0xFF546067);
const _border     = Color(0xFFDCE8F5);
const _doneGreen  = Color(0xFF2E7D32);
const _doneBg     = Color(0xFFE8F5E9);
const _warnOrange = Color(0xFFE65100);
const _warnBg     = Color(0xFFFFF3E0);

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

// ─── Dashboard ────────────────────────────────────────────────────────────────

class LpRrOpsDashboard extends ConsumerStatefulWidget {
  const LpRrOpsDashboard({super.key});

  @override
  ConsumerState<LpRrOpsDashboard> createState() => _LpRrOpsDashboardState();
}

class _LpRrOpsDashboardState extends ConsumerState<LpRrOpsDashboard> {
  Timer? _pollTimer;
  int _navIndex = 0;

  void _switchNav(int i) {
    if (i == 0 && _navIndex != 0) _loadData();
    if (i == 1 && _navIndex != 1) {
      ref.read(completedTripsProvider.notifier).loadTrips(rrOnly: true);
    }
    setState(() => _navIndex = i);
  }

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _silentRefresh();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    if (!mounted) return;
    ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing,pending', rrWeb: true);
  }

  void _silentRefresh() {
    ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing,pending', rrWeb: true);
    ref.read(completedTripsProvider.notifier).loadTrips(rrOnly: true);
  }

  void _showRrTripPopup(String value) {
    ref.read(pendingRrTripNumberProvider.notifier).state = null;
    final isFailed = value.startsWith('__failed__:');
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => isFailed
          ? AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 32),
                ),
                const SizedBox(height: 16),
                Text('Trip Created', style: _manrope(size: 15, weight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('RR sync failed: ${value.substring('__failed__:'.length)}',
                    style: _inter(size: 13), textAlign: TextAlign.center),
              ]),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: _rrBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: Text('OK', style: _inter(size: 14, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            )
          : AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: _doneGreen, size: 32),
                ),
                const SizedBox(height: 16),
                Text('Trip Synced to RR Web',
                    style: _manrope(size: 15, weight: FontWeight.w800),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('RR Trip Number', style: _inter(size: 12)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Trip number copied', style: _inter(size: 13, color: Colors.white)),
                      backgroundColor: _doneGreen,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _rrBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(value, style: _manrope(size: 20, weight: FontWeight.w800, color: _rrBlue)),
                      const SizedBox(width: 10),
                      const Icon(Icons.copy_rounded, size: 16, color: _rrBlue),
                    ]),
                  ),
                ),
              ]),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: _rrBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: Text('Continue', style: _inter(size: 14, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(pendingRrTripNumberProvider, (_, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showRrTripPopup(next));
      }
    });

    final user      = ref.watch(authProvider).user;
    final tripState = ref.watch(tripProvider);
    final session   = ref.watch(rrSessionProvider);

    // Fleet status: backend (rr_web=true) already scopes this to trips not yet
    // fully synced (current_stage < 5 or rr_sync_status != 'pod_synced') — no
    // extra client-side filtering here, it used to wrongly drop trips as soon
    // as their loading slip synced.
    final rrTrips = tripState.trips;

    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: _RrOpsBottomNav(
        selectedIndex: _navIndex,
        onTap: _switchNav,
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          RefreshIndicator(
        color: _rrBlue,
        onRefresh: () async => _loadData(),
        child: CustomScrollView(
          slivers: [

            // ── Gradient app bar ─────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: _rrBlueDark,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (v) async {
                    if (v == 'logout') {
                      await ref.read(authProvider.notifier).logout();
                      if (mounted) context.go('/login');
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'logout', child: Text('Logout')),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_rrBlueDark, _rrBlue, Color(0xFF2980B9)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.sync_alt_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user?.fullName ?? 'RR Operations',
                              style: _manrope(
                                  size: 17,
                                  weight: FontWeight.w800,
                                  color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('RR OPS',
                                  style: _inter(
                                      size: 11,
                                      weight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── RR connection banner ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _RrConnectionBanner(
                  session: session,
                  onConnect: () async {
                    await ensureRrSession(context, ref);
                  },
                  onDisconnect: () =>
                      ref.read(rrSessionProvider.notifier).clear(),
                ),
              ),
            ),

            // ── Stats strip ──────────────────────────────────────────────────
            if (!tripState.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _StatsStrip(trips: rrTrips),
                ),
              ),

            // ── Section header ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Text('RR Web Trips',
                        style: _manrope(
                            size: 15, weight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    if (!tripState.isLoading && rrTrips.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _rrBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${rrTrips.length}',
                            style: _inter(
                                size: 12,
                                weight: FontWeight.w700,
                                color: _rrBlue)),
                      ),
                    const Spacer(),
                    if (tripState.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _rrBlue),
                      ),
                    if (!tripState.isLoading) ...[
                      const SizedBox(width: 8),
                      Builder(builder: (ctx) => GestureDetector(
                        onTap: () async {
                          final session = await ensureRrSession(ctx, ref);
                          if (session == null || !ctx.mounted) return;
                          Navigator.of(ctx).push(
                            MaterialPageRoute(builder: (_) => const CreateTripScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _rrBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _rrBlue.withValues(alpha: 0.25)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add_rounded, size: 14, color: _rrBlue),
                            const SizedBox(width: 4),
                            Text('New Trip',
                                style: _inter(size: 11, weight: FontWeight.w700, color: _rrBlue)),
                          ]),
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),

            // ── Trip list / empty / loading ──────────────────────────────────
            if (tripState.isLoading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: _rrBlue)),
              )
            else if (rrTrips.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList.separated(
                  itemCount: rrTrips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => RrTripCard(
                    trip: rrTrips[i],
                    onRefresh: _silentRefresh,
                  ),
                ),
              ),
          ],
        ),
          ),
          const _RrOpsRecordsTab(),
        ],
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _RrOpsBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _RrOpsBottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      selectedItemColor: _rrBlue,
      unselectedItemColor: _secondary,
      backgroundColor: _surface,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: _inter(size: 11, weight: FontWeight.w700, color: _rrBlue),
      unselectedLabelStyle: _inter(size: 11, color: _secondary),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded),
          label: 'Records',
        ),
      ],
    );
  }
}

// ─── Records Tab ─────────────────────────────────────────────────────────────

class _RrOpsRecordsTab extends ConsumerWidget {
  const _RrOpsRecordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(completedTripsProvider);
    final trips = [...state.trips]
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    return RefreshIndicator(
      color: _rrBlue,
      onRefresh: () => ref.read(completedTripsProvider.notifier).loadTrips(rrOnly: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RR Web Records',
                            style: _manrope(size: 20, weight: FontWeight.w800)),
                        Text('Synced trips', style: _inter(size: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7F0D9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${trips.length} synced',
                      style: _inter(size: 11, weight: FontWeight.w700, color: const Color(0xFF1B5E20)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (state.error != null && trips.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFD32F2F)),
                    const SizedBox(height: 12),
                    Text(state.error!, style: _inter(size: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.read(completedTripsProvider.notifier).loadTrips(rrOnly: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (trips.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_copy_outlined, size: 64, color: _secondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('No synced trips yet',
                        style: _manrope(size: 15, weight: FontWeight.w700, color: _secondary)),
                    const SizedBox(height: 6),
                    Text('Trips synced to RR web will appear here',
                        style: _inter(size: 13)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: RrTripCard(trip: trips[i]),
                  ),
                  childCount: trips.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── RR Connection Banner ─────────────────────────────────────────────────────

class _RrConnectionBanner extends StatelessWidget {
  final RrSession? session;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _RrConnectionBanner({
    required this.session,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final connected = session != null && session!.isValid;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: connected ? _doneBg : _warnBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: connected
              ? _doneGreen.withValues(alpha: 0.35)
              : _warnOrange.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: (connected ? _doneGreen : _warnOrange)
                .withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (connected ? _doneGreen : _warnOrange)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              connected
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              size: 18,
              color: connected ? _doneGreen : _warnOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'RR Web Connected' : 'RR Web Not Connected',
                  style: _manrope(
                    size: 13,
                    weight: FontWeight.w700,
                    color: connected ? _doneGreen : _warnOrange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  connected
                      ? 'You can upload loading slips'
                      : 'Connect to upload loading slips',
                  style: _inter(size: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: connected ? onDisconnect : onConnect,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: connected ? _doneGreen : _rrBlue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: (connected ? _doneGreen : _rrBlue)
                        .withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                connected ? 'Disconnect' : 'Connect',
                style: _inter(
                    size: 12,
                    weight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Strip ──────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final List<TripModel> trips;
  const _StatsStrip({required this.trips});

  @override
  Widget build(BuildContext context) {
    final total     = trips.length;
    final needsSlip = trips
        .where((t) => t.rrSyncStatus == 'trip_created')
        .length;
    final slipDone  = trips
        .where((t) => ['loading_slip_synced', 'bilty_synced', 'pod_synced']
            .contains(t.rrSyncStatus))
        .length;
    final failed    = trips
        .where((t) => t.rrSyncStatus == 'failed')
        .length;

    return Row(
      children: [
        _StatChip(label: 'Total', count: total, color: _rrBlue),
        const SizedBox(width: 8),
        _StatChip(label: 'Needs Slip', count: needsSlip, color: _warnOrange),
        const SizedBox(width: 8),
        _StatChip(label: 'Slip Done', count: slipDone, color: _doneGreen),
        if (failed > 0) ...[
          const SizedBox(width: 8),
          _StatChip(label: 'Failed', count: failed, color: Colors.red),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: _manrope(
                  size: 20, weight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: _inter(
                  size: 10, weight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _rrBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sync_alt_rounded,
                  size: 36, color: _rrBlue),
            ),
            const SizedBox(height: 20),
            Text('No RR Web trips yet',
                style: _manrope(
                    size: 17, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'No active RR Web trips yet.\nTap "+ New Trip" above to get started.',
              style: _inter(size: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
