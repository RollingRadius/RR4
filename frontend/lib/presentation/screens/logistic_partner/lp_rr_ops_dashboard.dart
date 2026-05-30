import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/presentation/widgets/ongoing_trip_card.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/rr_sync_screen.dart';

// ─── Typography helpers ────────────────────────────────────────────────────────
TextStyle _manrope({
  double size = 14,
  FontWeight weight = FontWeight.w600,
  Color color = const Color(0xFF191C1E),
}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = const Color(0xFF546067),
}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

const _primary = Color(0xFF1B6CA8);           // blue — different from LP orange
const _background = Color(0xFFF4F7FB);
const _surfaceLowest = Color(0xFFFFFFFF);
const _secondary = Color(0xFF546067);


// ─── Dashboard ────────────────────────────────────────────────────────────────

class LpRrOpsDashboard extends ConsumerStatefulWidget {
  const LpRrOpsDashboard({super.key});

  @override
  ConsumerState<LpRrOpsDashboard> createState() => _LpRrOpsDashboardState();
}

class _LpRrOpsDashboardState extends ConsumerState<LpRrOpsDashboard> {
  int _navIndex = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing,pending');
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    if (!mounted) return;
    ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing,pending');
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surfaceLowest,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sync_alt, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.fullName ?? 'RR Operations',
                    style: _manrope(size: 14)),
                Text('RR Operations', style: _inter(size: 11, color: _primary)),
              ],
            ),
          ],
        ),
        actions: [
          // Primary action — open RR sync sheet
          TextButton.icon(
            onPressed: () => showRrSyncSheet(context),
            icon: const Icon(Icons.sync, size: 18, color: _primary),
            label: Text('Sync', style: _manrope(size: 13, color: _primary)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: _secondary),
            onSelected: (v) async {
              if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (mounted) context.go('/login');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: _navIndex == 0 ? _ActiveTripsTab(onRefresh: _loadData) : _CompletedTripsTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          setState(() => _navIndex = i);
          if (i == 0) _loadData();
          if (i == 1) {
            ref.read(completedTripsProvider.notifier).loadTrips(statusFilter: 'completed');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Active',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Completed',
          ),
        ],
      ),
    );
  }
}


// ─── Active trips tab ─────────────────────────────────────────────────────────

class _ActiveTripsTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _ActiveTripsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(tripProvider);

    if (tripState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final trips = tripState.trips;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: trips.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No active trips',
                          style: _manrope(size: 16, color: const Color(0xFF546067))),
                      const SizedBox(height: 8),
                      Text('Trips assigned to your company will appear here',
                          style: _inter(size: 13),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => OngoingTripCard(trip: trips[i]),
            ),
    );
  }
}


// ─── Completed trips tab ──────────────────────────────────────────────────────

class _CompletedTripsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(completedTripsProvider);

    if (tripState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final trips = tripState.trips;

    return trips.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No completed trips',
                    style: _manrope(size: 16, color: const Color(0xFF546067))),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => OngoingTripCard(trip: trips[i]),
          );
  }
}
