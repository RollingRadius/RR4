import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/rr_session_provider.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/rr_sync_screen.dart';
import 'package:fleet_management/providers/vehicle_provider.dart';
import 'package:fleet_management/providers/driver_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/providers/available_loads_provider.dart';
import 'package:fleet_management/data/models/load_requirement_model.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/presentation/widgets/ongoing_trip_card.dart';
import 'package:fleet_management/presentation/screens/fleet_owner/trip_stages_screen.dart';
import 'package:fleet_management/presentation/screens/trips/create_trip_screen.dart';
import 'package:fleet_management/presentation/screens/shared/truck_tracking_screen.dart';
import 'package:fleet_management/presentation/screens/fleet/fleet_hub_screen.dart';
import 'package:fleet_management/presentation/screens/worker_requests/worker_requests_screen.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/lp_workers_screen.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/providers/notification_provider.dart';
import 'package:fleet_management/data/models/notification_model.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Typography ───────────────────────────────────────────────────────────────
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

// ─── Colour tokens ────────────────────────────────────────────────────────────
const _primary = Color(0xFFFF6B00);
const _background = Color(0xFFF8F9FB);
const _surfaceLowest = Color(0xFFFFFFFF);
const _surfaceContainer = Color(0xFFECEEF0);
const _surfaceContainerLow = Color(0xFFF2F4F6);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _tertiary = Color(0xFF006B5E);
const _tertiaryContainer = Color(0xFF4AA898);
const _error = Color(0xFFBA1A1A);
const _errorContainer = Color(0xFFFFDAD6);
const _secondaryContainer = Color(0xFFD7E4EC);

// ─── Main screen ──────────────────────────────────────────────────────────────

class LogisticPartnerDashboard extends ConsumerStatefulWidget {
  const LogisticPartnerDashboard({super.key});

  @override
  ConsumerState<LogisticPartnerDashboard> createState() =>
      _LogisticPartnerDashboardState();
}

class _LogisticPartnerDashboardState
    extends ConsumerState<LogisticPartnerDashboard> {
  int _navIndex = 0;
  Timer? _pollTimer;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Background refresh every 30 s
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing,pending');
        ref.read(availableLoadsProvider.notifier).silentRefresh();
      }
    });
    // Initial data load — runs after first frame so ref/auth are ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllData());
  }

  /// Load all dashboard data. Called on init and whenever Dashboard tab
  /// comes into focus (e.g. switching back from Loads tab).
  void _loadAllData() {
    if (!mounted) return;
    ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing,pending');
    ref.read(vehicleProvider.notifier).loadVehicles();
    ref.read(availableLoadsProvider.notifier).loadAvailableLoads();
  }

  /// Switch tabs — refreshes fleet data whenever user navigates to Dashboard.
  Future<void> _switchNav(int index) async {
    if (index == 0 && _navIndex != 0) {
      ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing,pending');
    }
    if (index == 3 && _navIndex != 3) {
      // Load completed trips fresh each time Records tab is opened
      ref.read(completedTripsProvider.notifier).loadTrips(statusFilter: 'completed');
    }
    // Loads tab requires an active RR session
    if (index == 1 && _navIndex != 1) {
      final session = await ensureRrSession(context, ref);
      if (session == null || !mounted) return; // user cancelled — stay on current tab
    }
    setState(() => _navIndex = index);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When the LP receives a cancellation notification, immediately remove
    // the cancelled trip from Fleet Status without waiting for the 30s poll.
    ref.listen<NotificationsState>(notificationsProvider, (prev, next) {
      if (prev == null || next.items.length <= (prev.items.length)) return;
      final newest = next.items.first;
      if (newest.type == 'trip_cancelled' && newest.tripId != null) {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing,pending');
      } else if (newest.type == 'load_cancelled') {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing,pending');
      }
    });

    final user = ref.watch(authProvider).user;
    final pendingLoadsCount = ref.watch(availableLoadsProvider).loads.length;

    final pages = [
      _DashboardTab(onViewLoads: () => _switchNav(1)),
      const _AvailableLoadsTab(),
      const _ProfileTab(),
      const _RecordsTab(),
      const FleetHubScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _background,
      drawer: _AppDrawer(
        user: user,
        role: 'Logistic Partner',
        navIndex: _navIndex,
        onNavTap: (i) {
          _scaffoldKey.currentState?.closeDrawer();
          _switchNav(i);
        },
      ),
      body: Column(
        children: [
          _TopBar(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
          Expanded(
            child: IndexedStack(index: _navIndex, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _navIndex,
        onTap: _switchNav,
        pendingLoadsCount: pendingLoadsCount,
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : 'FO';
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final VoidCallback onMenuTap;
  const _TopBar({required this.onMenuTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);
    final unread = notifState.items
        .where((n) => !n.isRead && (n.type == 'worker_request' || n.type == 'trip_complete' || n.type == 'trip_cancelled' || n.type == 'load_cancelled'))
        .length;
    final syncReadyCount = ref.watch(rrSyncProvider.select((s) => s.readyCount));

    return SafeArea(
      bottom: false,
      child: Container(
        color: _background,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: onMenuTap,
              child: const Icon(Icons.menu, color: _secondary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '',
                style: _manrope(
                  size: 18,
                  weight: FontWeight.w900,
                  color: _primary,
                ).copyWith(letterSpacing: 1.0),
              ),
            ),
            GestureDetector(
              onTap: () => showRrSyncSheet(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.sync_rounded, color: _secondary, size: 24),
                  if (syncReadyCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          syncReadyCount > 99 ? '99+' : '$syncReadyCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => _showNotificationsSheet(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: _secondary, size: 24),
                  if (unread > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _NotificationsSheet(),
      ),
    );
  }
}

// ─── Notifications Bottom Sheet ───────────────────────────────────────────────

class _NotificationsSheet extends ConsumerStatefulWidget {
  const _NotificationsSheet();

  @override
  ConsumerState<_NotificationsSheet> createState() =>
      _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<_NotificationsSheet> {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationsProvider).items;
    final workerNotifs = items
        .where((n) => n.type == 'worker_request' || n.type == 'trip_complete' || n.type == 'trip_cancelled' || n.type == 'load_cancelled')
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _surfaceContainer,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Text('Notifications',
                      style: _manrope(size: 17, weight: FontWeight.w700)),
                  const Spacer(),
                  if (workerNotifs.any((n) => !n.isRead))
                    GestureDetector(
                      onTap: () => ref
                          .read(notificationsProvider.notifier)
                          .markAllRead(),
                      child: Text('Mark all read',
                          style: _inter(
                              size: 13,
                              weight: FontWeight.w600,
                              color: _primary)),
                    ),
                  if (workerNotifs.isNotEmpty) ...[
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(notificationsProvider.notifier)
                            .clearAll();
                        Navigator.pop(context);
                      },
                      child: Text('Clear all',
                          style: _inter(
                              size: 13,
                              weight: FontWeight.w600,
                              color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFECEEF0)),
            Expanded(
              child: workerNotifs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 48, color: _secondary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text('No notifications',
                              style: _inter(size: 14, color: _secondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: workerNotifs.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: Color(0xFFECEEF0)),
                      itemBuilder: (ctx, i) {
                        final n = workerNotifs[i];
                        return _NotifTile(
                          notif: n,
                          onDismiss: () => ref
                              .read(notificationsProvider.notifier)
                              .deleteOne(n.id),
                          onTap: () {
                            ref
                                .read(notificationsProvider.notifier)
                                .markRead(n.id);
                            Navigator.pop(context);
                            context.push(AppConstants.routeWorkerRequests);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _NotifTile(
      {required this.notif, required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFFFDAD6),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFBA1A1A), size: 22),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color:
              notif.isRead ? Colors.transparent : _primary.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _notifIconBg(notif.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(_notifIcon(notif.type),
                    color: _notifIconColor(notif.type), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif.title,
                              style: _manrope(
                                  size: 13,
                                  weight: notif.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w700)),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onDismiss,
                          child: Icon(Icons.close,
                              size: 16,
                              color: _secondary.withOpacity(0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notif.body,
                        style: _inter(size: 13, color: _secondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (notif.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(_formatTime(notif.createdAt!),
                          style: _inter(size: 11, color: _secondary)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'trip_cancelled':
      case 'load_cancelled':
        return Icons.cancel_outlined;
      case 'trip_complete':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.group_add_rounded;
    }
  }

  Color _notifIconColor(String type) {
    switch (type) {
      case 'trip_cancelled':
      case 'load_cancelled':
        return const Color(0xFFBA1A1A);
      case 'trip_complete':
        return const Color(0xFF2E7D32);
      default:
        return _primary;
    }
  }

  Color _notifIconBg(String type) {
    switch (type) {
      case 'trip_cancelled':
      case 'load_cancelled':
        return const Color(0xFFFFDAD6);
      case 'trip_complete':
        return const Color(0xFFE8F5E9);
      default:
        return _primary.withOpacity(0.12);
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int pendingLoadsCount;
  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
    this.pendingLoadsCount = 0,
  });

  // (icon, label, navIndex)
  static const _allItems = [
    (Icons.dashboard_rounded,        'DASHBOARD', 0),
    (Icons.search_rounded,           'LOADS',     1),
    (Icons.local_shipping_outlined,  'FLEET',     4),
    (Icons.folder_copy_outlined,     'RECORDS',   3),
    (Icons.person_outline,           'PROFILE',   2),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceLowest.withValues(alpha: 0.82),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.6), width: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _allItems.map((item) {
                  final (icon, label, navIdx) = item;
                  final active = navIdx == selectedIndex;
                  return GestureDetector(
                    onTap: () => onTap(navIdx),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: active
                          ? const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8)
                          : const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: active ? _primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(icon,
                                  color: active ? Colors.white : _secondary,
                                  size: 22),
                              // Badge on LOADS tab
                              if (navIdx == 1 && pendingLoadsCount > 0)
                                Positioned(
                                  right: -6,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pendingLoadsCount > 99
                                          ? '99+'
                                          : '$pendingLoadsCount',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            style: _inter(
                              size: 9,
                              weight: FontWeight.w700,
                              color: active ? Colors.white : _secondary,
                            ).copyWith(letterSpacing: 0.6),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  final VoidCallback onViewLoads;
  const _DashboardTab({required this.onViewLoads});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(tripProvider);
    final loadsState = ref.watch(availableLoadsProvider);
    final user = ref.watch(authProvider).user;
    final firstName = user?.fullName.split(' ').first ?? 'Logistic Partner';

    final ongoingTrips = tripState.activeTrips;
    final pendingLoads = loadsState.loads;

    return RefreshIndicator(
      color: _primary,
      onRefresh: () async {
        await ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing,pending');
        await ref.read(availableLoadsProvider.notifier).loadAvailableLoads();
      },
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Welcome back, $firstName',
            style: _manrope(size: 22, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text('Logistic Partner Panel',
              style: _inter(size: 13, color: _secondary)),
          const SizedBox(height: 16),

          // ── Pending loads alert banner ───────────────────────────────
          if (pendingLoads.isNotEmpty)
            _PendingLoadsBanner(
              count: pendingLoads.length,
              loads: pendingLoads.take(2).toList(),
              onViewAll: onViewLoads,
            ),
          if (pendingLoads.isNotEmpty) const SizedBox(height: 16),

          // Search New Loads
          _SearchLoadsButton(onTap: onViewLoads),
          const SizedBox(height: 24),

          // ── Fleet Status — ongoing trips with Locate button ──────────
          _FleetStatusHeader(
            tripCount: ongoingTrips.length,
            isLive: !tripState.isLoading,
          ),
          const SizedBox(height: 12),
          if (tripState.isLoading && ongoingTrips.isEmpty)
            _TripLoadingShimmer()
          else if (tripState.error != null && ongoingTrips.isEmpty)
            _TripsError(
              message: tripState.error!,
              onRetry: () => ref
                  .read(tripProvider.notifier)
                  .loadTrips(statusFilter: 'ongoing,pending'),
            )
          else if (ongoingTrips.isEmpty)
            _EmptyTrips()
          else
            ...ongoingTrips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: OngoingTripCard(
                  trip: t,
                  onComplete: () =>
                      ref.read(tripProvider.notifier).completeTrip(t.id),
                ),
              ),
            ),
          const SizedBox(height: 24),

          _RecentActivity(),
        ],
      ),
    ),
    );
  }
}

// ─── Pending Loads Alert Banner ───────────────────────────────────────────────

class _PendingLoadsBanner extends StatelessWidget {
  final int count;
  final List<LoadRequirementModel> loads;
  final VoidCallback onViewAll;
  const _PendingLoadsBanner({
    required this.count,
    required this.loads,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFF6B00), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_shipping_outlined,
                color: Color(0xFFFF6B00), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count new load ${count == 1 ? 'requirement' : 'requirements'} available',
                style: _inter(
                    size: 13,
                    weight: FontWeight.w600,
                    color: const Color(0xFF7A3200)),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFFFF6B00), size: 14),
          ],
        ),
      ),
    );
  }
}

// ─── Search New Loads Button (primary CTA) ────────────────────────────────────

class _SearchLoadsButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _SearchLoadsButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/fleet-manager/available-loads'),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFE55C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search New Loads',
                    style: _manrope(
                        size: 16,
                        weight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Browse available load requirements',
                    style: _inter(
                        size: 12, color: Colors.white.withValues(alpha: 0.80)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Fleet Status Header ──────────────────────────────────────────────────────

class _FleetStatusHeader extends ConsumerWidget {
  final int tripCount;
  final bool isLive;
  const _FleetStatusHeader({required this.tripCount, required this.isLive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastUpdated = ref.watch(tripProvider).lastUpdated;
    final updatedStr = lastUpdated != null
        ? _fmt(lastUpdated)
        : null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fleet Status',
                  style: _manrope(size: 17, weight: FontWeight.w800)),
              Text(
                tripCount == 0
                    ? 'No active trips'
                    : '$tripCount active trip${tripCount == 1 ? '' : 's'}'
                        '${updatedStr != null ? ' · $updatedStr' : ''}',
                style: _inter(size: 12),
              ),
            ],
          ),
        ),
        // New Trip button
        Builder(builder: (context) => GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateTripScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 14, color: _primary),
                const SizedBox(width: 4),
                Text('New Trip',
                    style: _inter(size: 11, weight: FontWeight.w700, color: _primary)),
              ],
            ),
          ),
        )),
        const SizedBox(width: 8),
        if (isLive)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF22C55E)),
                ),
                const SizedBox(width: 5),
                Text('LIVE',
                    style: _inter(
                            size: 9,
                            weight: FontWeight.w800,
                            color: Color(0xFF2E7D32))
                        .copyWith(letterSpacing: 0.8)),
              ],
            ),
          ),
      ],
    );
  }
}

String _fmt(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return 'updated $h:$m';
}

// ─── Empty trips state ────────────────────────────────────────────────────────

class _EmptyTrips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _surfaceContainer, width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_rounded, color: _secondary, size: 40),
            const SizedBox(height: 8),
            Text('No active trips',
                style: _inter(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _secondary)),
            const SizedBox(height: 4),
            Text('Create a trip to track it here in real time',
                style: _inter(size: 12)),
            const SizedBox(height: 14),
            Builder(builder: (context) => FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateTripScreen()),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text('Create Trip',
                  style: _manrope(size: 13, weight: FontWeight.w700, color: Colors.white)),
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Trips error state ────────────────────────────────────────────────────────

class _TripsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _TripsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _errorContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _error.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: _error, size: 36),
          const SizedBox(height: 8),
          Text('Could not load fleet status',
              style: _inter(size: 13, weight: FontWeight.w600, color: _error)),
          const SizedBox(height: 4),
          Text(message,
              textAlign: TextAlign.center,
              style: _inter(size: 12, color: _secondary)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Retry',
                  style: _inter(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading shimmer ──────────────────────────────────────────────────────────

class _TripLoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: _surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Recent Activity ──────────────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const activities = [
      (Icons.check_circle_outline_rounded, _tertiary,
          'Vehicle MH-12-AB-1234 completed trip', '2h ago'),
      (Icons.warning_amber_rounded, _error,
          'Maintenance due for RJ14-GB-9821', '4h ago'),
      (Icons.local_shipping_rounded, _primary,
          'New load matched for your fleet', '6h ago'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity',
            style: _manrope(size: 17, weight: FontWeight.w800)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _surfaceLowest,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8),
            ],
          ),
          child: Column(
            children: List.generate(activities.length, (i) {
              final (icon, color, title, time) = activities[i];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(title,
                              style: _inter(
                                  size: 13,
                                  weight: FontWeight.w500,
                                  color: _onSurface)),
                        ),
                        Text(time,
                            style:
                                _inter(size: 11, color: _secondary)),
                      ],
                    ),
                  ),
                  if (i < activities.length - 1)
                    const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFECEEF0)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Available Loads Tab ──────────────────────────────────────────────────────

class _AvailableLoadsTab extends ConsumerStatefulWidget {
  const _AvailableLoadsTab();

  @override
  ConsumerState<_AvailableLoadsTab> createState() => _AvailableLoadsTabState();
}

class _AvailableLoadsTabState extends ConsumerState<_AvailableLoadsTab> {
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial load is triggered by the dashboard's auth listener
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(availableLoadsProvider.notifier).loadAvailableLoads(
          pickup: _pickupCtrl.text.trim(),
          drop: _dropCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(availableLoadsProvider);

    return Column(
      children: [
        // ── Search bar ─────────────────────────────────────────────────
        Container(
          color: _background,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search Loads',
                  style: _manrope(size: 20, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Browse pending requirements from load owners',
                  style: _inter(size: 12, color: _secondary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SearchField(
                      controller: _pickupCtrl,
                      hint: 'Pickup city…',
                      icon: Icons.trip_origin_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SearchField(
                      controller: _dropCtrl,
                      hint: 'Drop city…',
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _search,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Results ────────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _primary))
              : state.error != null
                  ? _LoadsError(message: state.error!)
                  : state.loads.isEmpty
                      ? _LoadsEmpty()
                      : RefreshIndicator(
                          color: _primary,
                          onRefresh: () => ref
                              .read(availableLoadsProvider.notifier)
                              .loadAvailableLoads(
                                pickup: _pickupCtrl.text.trim(),
                                drop: _dropCtrl.text.trim(),
                              ),
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: state.loads.length,
                            itemBuilder: (_, i) => _AvailableLoadCard(
                              load: state.loads[i],
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _SearchField(
      {required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: _inter(size: 13, color: const Color(0xFF191C1E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _inter(size: 13),
        prefixIcon: Icon(icon, size: 16, color: _secondary),
        filled: true,
        fillColor: _surfaceLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _surfaceContainer),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _surfaceContainer),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Available Load Card ───────────────────────────────────────────────────────

class _AvailableLoadCard extends ConsumerWidget {
  final LoadRequirementModel load;
  const _AvailableLoadCard({required this.load});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFulfilling = ref.watch(availableLoadsProvider).isFulfilling;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ref ID + company name
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            load.refId,
                            style: _manrope(
                                size: 13,
                                weight: FontWeight.w800,
                                color: const Color(0xFF001e40)),
                          ),
                          if (load.companyName != null)
                            Text(
                              load.companyName!,
                              style: _inter(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: _secondary),
                            ),
                          if (load.companyCity != null ||
                              load.companyState != null)
                            Text(
                              [
                                if (load.companyCity != null) load.companyCity!,
                                if (load.companyState != null)
                                  load.companyState!,
                              ].join(', '),
                              style: _inter(size: 11, color: _secondary),
                            ),
                        ],
                      ),
                    ),
                    _LoadStatusChip(status: load.status),
                  ],
                ),
                const SizedBox(height: 14),

                // Route
                _RouteRow(
                    pickup: load.pickupLocation ?? '—',
                    drop: load.unloadLocation ?? '—'),
                const SizedBox(height: 14),

                // Trucks needed — highlighted row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _primary.withValues(alpha: 0.20), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping_outlined,
                          size: 15, color: _primary),
                      const SizedBox(width: 7),
                      Text(
                        'Trucks Needed: ',
                        style: _inter(
                            size: 12,
                            weight: FontWeight.w500,
                            color: const Color(0xFF7A3200)),
                      ),
                      Text(
                        '${load.truckCount}',
                        style: _manrope(
                            size: 14,
                            weight: FontWeight.w800,
                            color: _primary),
                      ),
                      Text(
                        ' truck${load.truckCount == 1 ? '' : 's'}',
                        style: _inter(
                            size: 12,
                            weight: FontWeight.w600,
                            color: const Color(0xFF7A3200)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Specs chips
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    if (load.materialType != null)
                      _SpecChip(
                          icon: Icons.inventory_2_outlined,
                          label: load.materialType!),
                    if (load.capacity != null)
                      _SpecChip(
                          icon: Icons.scale_outlined,
                          label: load.capacity!),
                    if (load.axelType != null)
                      _SpecChip(
                          icon: Icons.settings_outlined,
                          label: load.axelType!),
                    if (load.bodyType != null)
                      _SpecChip(
                          icon: Icons.category_outlined,
                          label: load.bodyType!),
                    if (load.entryDate != null)
                      _SpecChip(
                          icon: Icons.calendar_today_outlined,
                          label: load.entryDate!),
                  ],
                ),
              ],
            ),
          ),

          // Divider + action buttons
          Divider(
              height: 1,
              color: _surfaceContainer.withValues(alpha: 0.7),
              indent: 16,
              endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                // ── Copy & WhatsApp share row ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _copyDetails(context, load),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF001E40).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF001E40)
                                    .withValues(alpha: 0.18)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.copy_rounded,
                                  size: 14, color: Color(0xFF001E40)),
                              const SizedBox(width: 6),
                              Text(
                                'Copy Details',
                                style: _manrope(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF001E40)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _shareOnWhatsApp(context, load),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF25D366)
                                    .withValues(alpha: 0.40)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF25D366),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_rounded,
                                    size: 9, color: Colors.white),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'WhatsApp',
                                style: _manrope(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF128C7E)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Primary action (Track / Fulfill) ──────────────────────
                load.status == 'assigned'
                    ? SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TruckTrackingScreen(
                                trip: TripModel(
                                  id: load.id,
                                  tripNumber: load.refId,
                                  origin: load.pickupLocation ?? '',
                                  destination: load.unloadLocation ?? '',
                                  loadItem: load.materialType ?? 'Cargo',
                                  status: 'ongoing',
                                  organizationId: load.companyId,
                                ),
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D47A1)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF0D47A1)
                                      .withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.local_shipping_rounded,
                                    color: Color(0xFF0D47A1), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Track Truck',
                                  style: _manrope(
                                      size: 14,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFF0D47A1)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: isFulfilling
                              ? null
                              : () => _showFulfillSheet(context, ref, load),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B00), Color(0xFFE55C00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: _primary.withValues(alpha: 0.30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Fulfill This Load',
                                  style: _manrope(
                                      size: 14,
                                      weight: FontWeight.w700,
                                      color: Colors.white),
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

  // ── Message builder ──────────────────────────────────────────────────────────

  String _buildMessage(LoadRequirementModel load) {
    final lines = <String>[
      '*Load Requirements*',
      'Ref: ${load.refId}',
      if (load.pickupLocation != null) '📍 Pickup: ${load.pickupLocation}',
      if (load.unloadLocation != null) '🏁 Drop: ${load.unloadLocation}',
      if (load.entryDate != null) '📅 Date: ${load.entryDate}',
      'Trucks Needed: ${load.truckCount}',
      if (load.materialType != null) 'Material: ${load.materialType}',
      if (load.capacity != null) 'Capacity: ${load.capacity}',
      if (load.bodyType != null) 'Body Type: ${load.bodyType}',
      if (load.axelType != null) 'Axel Type: ${load.axelType}',
      if (load.floorType != null) 'Floor Type: ${load.floorType}',
      if (load.companyName != null) 'Company: ${load.companyName}',
      if (load.companyCity != null || load.companyState != null)
        '📌 Location: ${[
          if (load.companyCity != null) load.companyCity!,
          if (load.companyState != null) load.companyState!,
        ].join(', ')}',
      if (load.companyPhone != null) '📞 Contact: ${load.companyPhone}',
    ];
    return lines.join('\n');
  }

  void _copyDetails(BuildContext context, LoadRequirementModel load) {
    Clipboard.setData(ClipboardData(text: _buildMessage(load)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Load details copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareOnWhatsApp(
      BuildContext context, LoadRequirementModel load) async {
    final encoded = Uri.encodeComponent(_buildMessage(load));
    final url = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showFulfillSheet(
      BuildContext context, WidgetRef ref, LoadRequirementModel load) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FulfillSheet(load: load),
    );
  }
}

// ── Route row ─────────────────────────────────────────────────────────────────

class _RouteRow extends StatelessWidget {
  final String pickup, drop;
  const _RouteRow({required this.pickup, required this.drop});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: _primary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(pickup,
              style: _manrope(
                  size: 13, weight: FontWeight.w700,
                  color: const Color(0xFF001e40)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded, size: 14, color: _secondary),
        ),
        Expanded(
          child: Text(drop,
              style: _manrope(
                  size: 13, weight: FontWeight.w700,
                  color: const Color(0xFF001e40)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

// ── Spec chip ─────────────────────────────────────────────────────────────────

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _secondary),
          const SizedBox(width: 5),
          Text(label,
              style:
                  _inter(size: 11, weight: FontWeight.w600, color: _secondary)),
        ],
      ),
    );
  }
}

// ── Load status chip ──────────────────────────────────────────────────────────

class _LoadStatusChip extends StatelessWidget {
  final String status;
  const _LoadStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'assigned' => (
          'ASSIGNED',
          const Color(0xFFD5E3FC),
          const Color(0xFF0D47A1)
        ),
      'fulfilled' => ('DONE', const Color(0xFFECEEF0), _secondary),
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

// ── Fulfill bottom sheet ──────────────────────────────────────────────────────

class _FulfillSheet extends ConsumerStatefulWidget {
  final LoadRequirementModel load;
  const _FulfillSheet({required this.load});

  @override
  ConsumerState<_FulfillSheet> createState() => _FulfillSheetState();
}

class _FulfillSheetState extends ConsumerState<_FulfillSheet> {
  String? _selectedVehicleId;
  String? _selectedDriverId;
  String? _selectedTransporterId;
  String? _selectedTransporterName;
  String? _selectedConsignorId;
  String? _selectedConsignorName;
  String? _selectedConsigneeId;
  String? _selectedConsigneeName;
  String? _selectedConsigneeType; // kept for legacy; value is 'rr_company'
  String? _selectedRrOpsId;
  String? _selectedRrOpsName;
  String? _selectedRrOpsRrId;  // rr_company_id of the selected ops worker
  final _amountController = TextEditingController();
  final _consignorController = TextEditingController();
  final _consigneeController = TextEditingController();
  final _transporterController = TextEditingController();
  final _rrOpsController = TextEditingController();
  List<Map<String, dynamic>> _consignorResults = [];
  List<Map<String, dynamic>> _consigneeResults = [];
  List<Map<String, dynamic>> _transporterResults = [];
  List<Map<String, dynamic>> _rrOpsResults = [];
  bool _consignorSearchLoading = false;
  bool _consigneeSearchLoading = false;
  bool _transporterSearchLoading = false;
  bool _rrOpsSearchLoading = false;
  Timer? _consignorDebounce;
  Timer? _consigneeDebounce;
  Timer? _transporterDebounce;
  Timer? _rrOpsDebounce;
  bool _isLoading = false;
  String? _consignorError;
  String? _consigneeError;
  String? _transporterError;
  String? _rrOpsError;
  String? _amountError;
  String? _rrError;

  // ── RR Sync fields ──────────────────────────────────────────────────────────
  final _pickupCityCtrl  = TextEditingController();
  String? _pickupCityId;
  List<Map<String, dynamic>> _pickupCityResults = [];
  bool _pickupCityLoading = false;
  Timer? _pickupCityDebounce;

  final _dropCityCtrl  = TextEditingController();
  String? _dropCityId;
  List<Map<String, dynamic>> _dropCityResults = [];
  bool _dropCityLoading = false;
  Timer? _dropCityDebounce;

  final _rrMaterialCtrl = TextEditingController();
  String? _materialRrId;
  List<Map<String, dynamic>> _materialResults = [];
  bool _materialLoading = false;
  Timer? _materialDebounce;

  final _weightCtrl       = TextEditingController();
  String _weightUnit      = 'TONS';
  final _invoiceValueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load fleet data so dropdowns are populated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vehicleProvider.notifier).loadVehicles();
      ref.read(driverProvider.notifier).loadDrivers();
      // Pre-populate city / material fields from the load requirement
      final load = widget.load;
      if (load.pickupLocation != null && load.pickupLocation!.isNotEmpty) {
        _pickupCityCtrl.text = load.pickupLocation!;
        _searchCity(load.pickupLocation!, isPickup: true);
      }
      if (load.unloadLocation != null && load.unloadLocation!.isNotEmpty) {
        _dropCityCtrl.text = load.unloadLocation!;
        _searchCity(load.unloadLocation!, isPickup: false);
      }
      if (load.materialType != null && load.materialType!.isNotEmpty) {
        _rrMaterialCtrl.text = load.materialType!;
        _searchMaterial(load.materialType!);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _consignorController.dispose();
    _consigneeController.dispose();
    _transporterController.dispose();
    _rrOpsController.dispose();
    _consignorDebounce?.cancel();
    _consigneeDebounce?.cancel();
    _transporterDebounce?.cancel();
    _rrOpsDebounce?.cancel();
    _pickupCityCtrl.dispose();
    _dropCityCtrl.dispose();
    _rrMaterialCtrl.dispose();
    _weightCtrl.dispose();
    _invoiceValueCtrl.dispose();
    _pickupCityDebounce?.cancel();
    _dropCityDebounce?.cancel();
    _materialDebounce?.cancel();
    super.dispose();
  }

  Future<void> _searchCity(String q, {required bool isPickup}) async {
    if (q.length < 2) return;
    if (isPickup) setState(() => _pickupCityLoading = true);
    else          setState(() => _dropCityLoading   = true);
    try {
      final dio = ref.read(apiServiceProvider).dio;
      final resp = await dio.get('/api/rr/cities', queryParameters: {'q': q});
      final items = (resp.data['items'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        if (isPickup) { _pickupCityResults = items; _pickupCityLoading = false; }
        else          { _dropCityResults   = items; _dropCityLoading   = false; }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (isPickup) _pickupCityLoading = false;
        else          _dropCityLoading   = false;
      });
    }
  }

  Future<void> _searchMaterial(String q) async {
    setState(() => _materialLoading = true);
    try {
      final dio = ref.read(apiServiceProvider).dio;
      final resp = await dio.get('/api/rr/materials', queryParameters: {'q': q});
      final items = (resp.data['items'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() { _materialResults = items; _materialLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _materialLoading = false);
    }
  }

  Future<void> _searchConsignors(String q) async {
    if (q.length < 2) { setState(() => _consignorResults = []); return; }
    setState(() => _consignorSearchLoading = true);
    try {
      final rrToken = ref.read(rrSessionProvider)?.token ?? '';
      final resp = await ref.read(apiServiceProvider).dio.get(
        '/api/rr/consignees', queryParameters: {'q': q, 'rr_token': rrToken});
      final list = (resp.data['consignees'] as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _consignorResults = list; _consignorSearchLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _consignorResults = []; _consignorSearchLoading = false; });
    }
  }

  Future<void> _searchConsignees(String q) async {
    if (q.length < 2) { setState(() => _consigneeResults = []); return; }
    setState(() => _consigneeSearchLoading = true);
    try {
      final rrToken = ref.read(rrSessionProvider)?.token ?? '';
      final resp = await ref.read(apiServiceProvider).dio.get(
        '/api/rr/consignees', queryParameters: {'q': q, 'rr_token': rrToken});
      final list = (resp.data['consignees'] as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _consigneeResults = list; _consigneeSearchLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _consigneeResults = []; _consigneeSearchLoading = false; });
    }
  }

  Future<void> _searchTransporters(String q) async {
    if (q.length < 2) {
      setState(() => _transporterResults = []);
      return;
    }
    setState(() => _transporterSearchLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.dio.get(
        '/api/transporters/search',
        queryParameters: {'q': q, 'limit': 10},
      );
      final list = (resp.data['transporters'] as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _transporterResults = list; _transporterSearchLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _transporterResults = []; _transporterSearchLoading = false; });
    }
  }

  Future<void> _searchRrOps(String q) async {
    setState(() => _rrOpsSearchLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.dio.get(
        '/api/rr/ops-workers',
        queryParameters: q.isNotEmpty ? {'q': q} : null,
      );
      final list = (resp.data['workers'] as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _rrOpsResults = list; _rrOpsSearchLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _rrOpsResults = []; _rrOpsSearchLoading = false; });
    }
  }

  Future<void> _confirm() async {
    if (_isLoading) return;

    // Validate required fields
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    final weightText = _weightCtrl.text.trim();
    final weightVal = double.tryParse(weightText);

    String? snrErr;
    String? cErr;
    String? tErr;
    String? opsErr;
    String? aErr;
    String? rErr;

    if (_selectedConsignorId == null) snrErr = 'Please select a consignor (sender)';
    if (_selectedConsigneeId == null) cErr = 'Please select a consignee (load receiver)';
    if (_selectedTransporterId == null) tErr = 'Please select a transporter';
    if (_selectedRrOpsId == null) opsErr = 'Please select an RR Ops worker';
    if (amountText.isEmpty) {
      aErr = 'Please enter the trip amount';
    } else if (amount == null || amount <= 0) {
      aErr = 'Please enter a valid amount greater than 0';
    }
    if (_pickupCityId == null) {
      rErr = 'Select a pickup city from the dropdown';
    } else if (_dropCityId == null) {
      rErr = 'Select a drop city from the dropdown';
    } else if (_materialRrId == null) {
      rErr = 'Select a material from the dropdown';
    } else if (weightText.isEmpty || weightVal == null) {
      rErr = 'Enter a valid weight';
    }

    if (snrErr != null || cErr != null || tErr != null || opsErr != null || aErr != null || rErr != null) {
      setState(() { _consignorError = snrErr; _consigneeError = cErr; _transporterError = tErr; _rrOpsError = opsErr; _amountError = aErr; _rrError = rErr; });
      return;
    }

    setState(() { _isLoading = true; _consignorError = null; _consigneeError = null; _transporterError = null; _rrOpsError = null; _amountError = null; _rrError = null; });

    final api = ref.read(apiServiceProvider);

    try {
      final invoiceVal = double.tryParse(_invoiceValueCtrl.text.trim());
      final rrSession = ref.read(rrSessionProvider);
      final resp = await api.dio.post(
        '/api/loads/${widget.load.id}/fulfill',
        data: {
          if (_selectedVehicleId != null) 'vehicle_id': _selectedVehicleId,
          if (_selectedDriverId != null) 'driver_id': _selectedDriverId,
          if (amount != null) 'trip_amount': amount,
          if (_selectedConsignorId != null) 'consignor_rr_company_id': _selectedConsignorId,
          if (_selectedConsigneeId != null) 'consignee_rr_company_id': _selectedConsigneeId,
          if (_selectedRrOpsId != null) 'rr_ops_user_id': _selectedRrOpsId,
          if (_selectedTransporterId != null) 'transporter_user_id': _selectedTransporterId,
          'origin_rr_city_id': _pickupCityId,
          'destination_rr_city_id': _dropCityId,
          'material_rr_id': _materialRrId,
          'weight_value': weightVal,
          'weight_unit': _weightUnit,
          if (invoiceVal != null) 'invoice_value': invoiceVal,
          if (rrSession != null && rrSession.isValid) 'rr_token': rrSession.token,
        },
      );

      final tripData = resp.data['trip'] as Map<String, dynamic>;
      final trip = TripModel.fromJson(tripData);

      ref.read(tripProvider.notifier).patchTrip(trip);

      if (!mounted) return;
      final trips = ref.read(tripProvider.notifier);
      final nav = Navigator.of(context);
      nav.pop();
      nav.push(
        MaterialPageRoute(builder: (_) => TripStagesScreen(trip: trip)),
      ).then((_) {
        trips.loadTrips(statusFilter: 'ongoing,pending');
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = e.response?.data?['detail'] as String? ??
          'Failed to fulfill load. Please try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleProvider).vehicles;
    final drivers  = ref.watch(driverProvider).drivers;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _surfaceContainer,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              Text('Fulfill Load Requirement',
                  style: _manrope(size: 18, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${widget.load.refId} · ${widget.load.pickupLocation ?? '—'} → ${widget.load.unloadLocation ?? '—'}',
                  style: _inter(size: 12, color: _secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 24),

              // Load info
              _InfoRow(
                icon: Icons.local_shipping_rounded,
                label: 'Trucks Needed',
                value: '${widget.load.truckCount}',
              ),
              if (widget.load.materialType != null)
                _InfoRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Material',
                  value: widget.load.materialType!,
                ),
              if (widget.load.capacity != null)
                _InfoRow(
                  icon: Icons.scale_outlined,
                  label: 'Capacity',
                  value: widget.load.capacity!,
                ),
              const SizedBox(height: 20),

              // ── Consignor (Sender / Shipper) ─────────────────────────────
              Row(children: [
                Text('Consignor',
                    style: _inter(size: 12, weight: FontWeight.w700, color: _secondary)),
                Text(' *', style: _inter(size: 12, weight: FontWeight.w700, color: Colors.red)),
              ]),
              const SizedBox(height: 8),
              if (_selectedConsignorId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business_outlined, size: 18, color: _primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedConsignorName ?? 'Consignor selected',
                          style: _inter(size: 13, weight: FontWeight.w600, color: _primary),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedConsignorId   = null;
                          _selectedConsignorName = null;
                          _consignorResults      = [];
                          _consignorController.clear();
                        }),
                        child: const Icon(Icons.close, size: 18, color: _primary),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _consignorController,
                  decoration: InputDecoration(
                    hintText: 'Search sender company',
                    hintStyle: _inter(size: 13, color: _secondary),
                    prefixIcon: _consignorSearchLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : const Icon(Icons.business_outlined, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    filled: true,
                    fillColor: _surfaceContainerLow,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _surfaceContainer)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _surfaceContainer)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primary, width: 1.5)),
                  ),
                  onTap: null,
                  onChanged: (val) {
                    _consignorDebounce?.cancel();
                    _consignorDebounce = Timer(
                      const Duration(milliseconds: 400),
                      () => _searchConsignors(val.trim()),
                    );
                  },
                ),
                if (_consignorResults.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _surfaceContainer),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: _consignorResults.map((c) {
                        final name = c['name'] as String? ?? '—';
                        return InkWell(
                          onTap: () => setState(() {
                            _selectedConsignorId   = c['rr_company_id'] as String?;
                            _selectedConsignorName = name;
                            _consignorResults      = [];
                            _consignorController.clear();
                            _consignorError        = null;
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.business_outlined, size: 16, color: _primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(name,
                                      style: _inter(size: 13, weight: FontWeight.w600,
                                          color: const Color(0xFF191C1E))),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
              if (_consignorError != null) ...[
                const SizedBox(height: 4),
                Text(_consignorError!, style: _inter(size: 11, color: _error)),
              ],
              const SizedBox(height: 16),

              // ── Consignee (Load Receiver) ────────────────────────────────
              Row(children: [
                Text('Consignee',
                    style: _inter(size: 12, weight: FontWeight.w700, color: _secondary)),
                Text(' *', style: _inter(size: 12, weight: FontWeight.w700, color: Colors.red)),
              ]),
              const SizedBox(height: 8),
              if (_selectedConsigneeId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00796B).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.move_to_inbox_outlined, size: 18,
                          color: Color(0xFF00796B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedConsigneeName ?? 'Consignee selected',
                          style: _inter(size: 13, weight: FontWeight.w600,
                              color: const Color(0xFF00796B)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedConsigneeId   = null;
                          _selectedConsigneeName = null;
                          _selectedConsigneeType = null;
                          _consigneeResults      = [];
                          _consigneeController.clear();
                        }),
                        child: const Icon(Icons.close, size: 18,
                            color: Color(0xFF00796B)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _consigneeController,
                  decoration: InputDecoration(
                    hintText: 'Search load receiver',
                    hintStyle: _inter(size: 13, color: _secondary),
                    prefixIcon: _consigneeSearchLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : const Icon(Icons.move_to_inbox_outlined, size: 18),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    filled: true,
                    fillColor: _surfaceContainerLow,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _surfaceContainer)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _surfaceContainer)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF00796B), width: 1.5)),
                  ),
                  onTap: null,
                  onChanged: (val) {
                    _consigneeDebounce?.cancel();
                    _consigneeDebounce = Timer(
                      const Duration(milliseconds: 400),
                      () => _searchConsignees(val.trim()),
                    );
                  },
                ),
                if (_consigneeResults.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _surfaceContainer),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _consigneeResults.map((c) {
                        final name = c['name'] as String? ?? '—';
                        return InkWell(
                          onTap: () => setState(() {
                            _selectedConsigneeId   = c['rr_company_id'] as String?;
                            _selectedConsigneeName = name;
                            _selectedConsigneeType = 'rr_company';
                            _consigneeResults      = [];
                            _consigneeController.clear();
                            _consigneeError        = null;
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.business_outlined,
                                  size: 16,
                                  color: Color(0xFF00796B),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(name,
                                      style: _inter(
                                          size: 13,
                                          weight: FontWeight.w600,
                                          color: const Color(0xFF191C1E))),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
              if (_consigneeError != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.error_outline, size: 13, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(_consigneeError!,
                      style: _inter(size: 11, color: Colors.red)),
                ]),
              ],
              const SizedBox(height: 20),

              // ── RR Sync Details ─────────────────────────────────────────
              Row(children: [
                Container(width: 3, height: 14,
                    decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('RR Sync Details', style: _manrope(size: 13, weight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),

              // Pickup city
              Text('Pickup City', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillCityField(
                controller: _pickupCityCtrl,
                loading: _pickupCityLoading,
                confirmed: _pickupCityId != null,
                results: _pickupCityResults,
                onChanged: (q) {
                  setState(() { _pickupCityId = null; _pickupCityResults = []; });
                  _pickupCityDebounce?.cancel();
                  if (q.length >= 2) _pickupCityDebounce = Timer(
                    const Duration(milliseconds: 400),
                    () => _searchCity(q, isPickup: true),
                  );
                },
                onSelect: (city) => setState(() {
                  _pickupCityId = city['rr_city_id'] as String;
                  _pickupCityCtrl.text = city['name'] as String;
                  _pickupCityResults = [];
                }),
                onClear: () => setState(() {
                  _pickupCityId = null; _pickupCityCtrl.clear(); _pickupCityResults = [];
                }),
              ),
              const SizedBox(height: 12),

              // Drop city
              Text('Drop City', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillCityField(
                controller: _dropCityCtrl,
                loading: _dropCityLoading,
                confirmed: _dropCityId != null,
                results: _dropCityResults,
                onChanged: (q) {
                  setState(() { _dropCityId = null; _dropCityResults = []; });
                  _dropCityDebounce?.cancel();
                  if (q.length >= 2) _dropCityDebounce = Timer(
                    const Duration(milliseconds: 400),
                    () => _searchCity(q, isPickup: false),
                  );
                },
                onSelect: (city) => setState(() {
                  _dropCityId = city['rr_city_id'] as String;
                  _dropCityCtrl.text = city['name'] as String;
                  _dropCityResults = [];
                }),
                onClear: () => setState(() {
                  _dropCityId = null; _dropCityCtrl.clear(); _dropCityResults = [];
                }),
              ),
              const SizedBox(height: 12),

              // Material
              Text('Material', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillCityField(
                controller: _rrMaterialCtrl,
                loading: _materialLoading,
                confirmed: _materialRrId != null,
                results: _materialResults,
                onChanged: (q) {
                  setState(() { _materialRrId = null; _materialResults = []; });
                  _materialDebounce?.cancel();
                  _materialDebounce = Timer(
                    const Duration(milliseconds: 350),
                    () => _searchMaterial(q),
                  );
                },
                onSelect: (mat) => setState(() {
                  _materialRrId = mat['rr_material_id'] as String?;
                  _rrMaterialCtrl.text = mat['name'] as String;
                  _materialResults = [];
                }),
                onClear: () => setState(() {
                  _materialRrId = null; _rrMaterialCtrl.clear(); _materialResults = [];
                }),
              ),
              const SizedBox(height: 12),

              // Weight + unit
              Text('Weight', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: _FulfillTextField(
                  controller: _weightCtrl,
                  hint: 'e.g. 20',
                  inputType: const TextInputType.numberWithOptions(decimal: true),
                )),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: _surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _surfaceContainer),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _weightUnit,
                      style: _inter(size: 13, color: const Color(0xFF191C1E)),
                      icon: const Icon(Icons.expand_more_rounded, size: 18),
                      items: ['KG', 'TONS', 'QUINTAL'].map((u) =>
                          DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) { if (v != null) setState(() => _weightUnit = v); },
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Invoice value
              Text('Invoice Value (₹)', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(
                controller: _invoiceValueCtrl,
                hint: 'e.g. 150000',
                inputType: TextInputType.number,
              ),
              if (_rrError != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.error_outline, size: 13, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(child: Text(_rrError!, style: _inter(size: 11, color: Colors.red))),
                ]),
              ],
              const SizedBox(height: 20),

              // Vehicle selector
              Text('Assign Vehicle (optional)',
                  style: _inter(size: 12, weight: FontWeight.w700, color: _secondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _surfaceContainer),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVehicleId,
                    isExpanded: true,
                    hint: Text('Select vehicle',
                        style: _inter(size: 13, color: _secondary)),
                    style: _inter(
                        size: 13,
                        color: const Color(0xFF191C1E),
                        weight: FontWeight.w500),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('None', style: _inter(size: 13, color: _secondary)),
                      ),
                      ...vehicles.map((v) {
                        final reg = v['registration'] as String? ??
                            v['vehicle_number'] as String? ?? '—';
                        final make = v['make'] as String? ?? '';
                        final model = v['model'] as String? ?? '';
                        final label = [reg, if (make.isNotEmpty || model.isNotEmpty) '$make $model'.trim()]
                            .join('  ·  ');
                        return DropdownMenuItem<String>(
                          value: v['id'] as String?,
                          child: Text(label, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedVehicleId = val),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Driver selector
              Text('Assign Driver (optional)',
                  style: _inter(size: 12, weight: FontWeight.w700, color: _secondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _surfaceContainer),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDriverId,
                    isExpanded: true,
                    hint: Text('Select driver',
                        style: _inter(size: 13, color: _secondary)),
                    style: _inter(
                        size: 13,
                        color: const Color(0xFF191C1E),
                        weight: FontWeight.w500),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('None', style: _inter(size: 13, color: _secondary)),
                      ),
                      ...drivers.map((d) {
                        final label = '${d.fullName}  ·  ${d.phone}';
                        return DropdownMenuItem<String>(
                          value: d.driverId,
                          child: Text(label, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedDriverId = val),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── RR Ops ────────────────────────────────────────────────────
              Row(children: [
                Text('RR Ops',
                    style: _inter(size: 12, weight: FontWeight.w700, color: _secondary)),
                Text(' *', style: _inter(size: 12, weight: FontWeight.w700, color: Colors.red)),
              ]),
              const SizedBox(height: 8),
              if (_selectedRrOpsId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1B6CA8).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_alt, size: 18, color: Color(0xFF1B6CA8)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedRrOpsName ?? 'RR Ops selected',
                              style: _inter(size: 13, weight: FontWeight.w600,
                                  color: const Color(0xFF1B6CA8)),
                            ),
                            if (_selectedRrOpsRrId != null && _selectedRrOpsRrId!.isNotEmpty)
                              Text(
                                'RR ID: $_selectedRrOpsRrId',
                                style: _inter(size: 11, color: const Color(0xFF1B6CA8)),
                              )
                            else
                              Text(
                                'No RR ID set',
                                style: _inter(size: 11, color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedRrOpsId   = null;
                          _selectedRrOpsName = null;
                          _selectedRrOpsRrId = null;
                          _rrOpsResults      = [];
                          _rrOpsController.clear();
                        }),
                        child: const Icon(Icons.close, size: 18, color: Color(0xFF1B6CA8)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                GestureDetector(
                  onTap: () {
                    _searchRrOps('');
                  },
                  child: TextField(
                    controller: _rrOpsController,
                    decoration: InputDecoration(
                      hintText: 'Search RR Ops worker',
                      hintStyle: _inter(size: 13, color: _secondary),
                      prefixIcon: _rrOpsSearchLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.sync_alt, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      filled: true,
                      fillColor: _surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _surfaceContainer),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _surfaceContainer),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1B6CA8), width: 1.5),
                      ),
                    ),
                    onTap: () => _searchRrOps(''),
                    onChanged: (val) {
                      _rrOpsDebounce?.cancel();
                      _rrOpsDebounce = Timer(
                        const Duration(milliseconds: 400),
                        () => _searchRrOps(val.trim()),
                      );
                    },
                  ),
                ),
                if (_rrOpsResults.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _surfaceContainer),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _rrOpsResults.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text('No RR Operations workers found',
                                    style: _inter(size: 12, color: _secondary)),
                              ),
                            ]
                          : _rrOpsResults.map((w) {
                              final name  = w['full_name'] as String? ?? '—';
                              final phone = w['phone'] as String? ?? '';
                              return InkWell(
                                onTap: () => setState(() {
                                  _selectedRrOpsId    = w['user_id'] as String?;
                                  _selectedRrOpsName  = name;
                                  _selectedRrOpsRrId  = w['rr_company_id'] as String?;
                                  _rrOpsResults       = [];
                                  _rrOpsController.clear();
                                }),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.sync_alt, size: 16,
                                          color: Color(0xFF1B6CA8)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name,
                                                style: _inter(size: 13, weight: FontWeight.w600,
                                                    color: const Color(0xFF191C1E))),
                                            if (phone.isNotEmpty)
                                              Text(phone,
                                                  style: _inter(size: 11, color: _secondary)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                  ),
                ],
              ],
              if (_rrOpsError != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.error_outline, size: 13, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(_rrOpsError!, style: _inter(size: 11, color: Colors.red)),
                ]),
              ],
              const SizedBox(height: 20),

              // Transporter search
              Row(
                children: [
                  Text('Assign Transporter',
                      style: _inter(size: 12, weight: FontWeight.w700, color: _secondary)),
                  Text(' *', style: _inter(size: 12, weight: FontWeight.w700, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 8),
              if (_selectedTransporterId != null) ...[
                // Selected transporter chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedTransporterName ?? 'Transporter selected',
                          style: _inter(size: 13, weight: FontWeight.w600, color: const Color(0xFF2E7D32)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedTransporterId = null;
                          _selectedTransporterName = null;
                          _transporterResults = [];
                          _transporterController.clear();
                        }),
                        child: const Icon(Icons.close, size: 18, color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Search field
                TextField(
                  controller: _transporterController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone',
                    hintStyle: _inter(size: 13, color: _secondary),
                    prefixIcon: _transporterSearchLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    filled: true,
                    fillColor: _surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _surfaceContainer),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _surfaceContainer),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primary, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    _transporterDebounce?.cancel();
                    _transporterDebounce = Timer(
                      const Duration(milliseconds: 400),
                      () => _searchTransporters(val.trim()),
                    );
                  },
                ),
                if (_transporterResults.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _surfaceContainer),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _transporterResults.map((t) {
                        final name = t['full_name'] as String? ?? '—';
                        final phone = t['phone'] as String? ?? '';
                        final company = t['company_name'] as String? ?? '';
                        final city = t['city'] as String? ?? '';
                        final label = [company, city].where((s) => s.isNotEmpty).join(' · ');
                        return InkWell(
                          onTap: () => setState(() {
                            _selectedTransporterId = t['user_id'] as String?;
                            _selectedTransporterName = '$name${label.isNotEmpty ? ' ($label)' : ''}';
                            _transporterResults = [];
                            _transporterController.clear();
                            _transporterError = null;
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16, color: Color(0xFF6B7280)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: _inter(size: 13, weight: FontWeight.w600,
                                              color: const Color(0xFF191C1E))),
                                      if (phone.isNotEmpty || label.isNotEmpty)
                                        Text(
                                          [if (phone.isNotEmpty) phone, if (label.isNotEmpty) label].join(' · '),
                                          style: _inter(size: 11, color: _secondary),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
              if (_transporterError != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.error_outline, size: 13, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(_transporterError!, style: _inter(size: 11, color: Colors.red)),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // Trip Amount
              Row(
                children: [
                  Text('Trip Amount (₹)',
                      style: _inter(size: 12, weight: FontWeight.w700, color: _secondary)),
                  Text(' *', style: _inter(size: 12, weight: FontWeight.w700, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (_) {
                  if (_amountError != null) setState(() => _amountError = null);
                },
                decoration: InputDecoration(
                  hintText: 'Enter agreed trip amount',
                  hintStyle: _inter(size: 13, color: _secondary),
                  prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                  errorText: _amountError,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  filled: true,
                  fillColor: _surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _surfaceContainer),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _amountError != null ? Colors.red : _surfaceContainer,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _amountError != null ? Colors.red : _primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.manrope(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Confirm Fulfillment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fulfill sheet helpers ─────────────────────────────────────────────────────

/// Compact search field used inside the fulfill bottom sheet.
class _FulfillCityField extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final bool confirmed;
  final List<Map<String, dynamic>> results;
  final ValueChanged<String> onChanged;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback onClear;

  const _FulfillCityField({
    required this.controller,
    required this.loading,
    required this.confirmed,
    required this.results,
    required this.onChanged,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: confirmed
                  ? const Color(0xFF4CAF50).withOpacity(0.6)
                  : _surfaceContainer,
              width: confirmed ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            const SizedBox(width: 12),
            Icon(
              confirmed ? Icons.check_circle_rounded : Icons.search_rounded,
              size: 16,
              color: confirmed ? const Color(0xFF2E7D32) : _secondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: _inter(size: 13, color: const Color(0xFF191C1E)),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primary)),
              )
            else if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: _secondary),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
          ]),
        ),
        if (results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _surfaceContainer),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
            constraints: const BoxConstraints(maxHeight: 160),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: _surfaceContainer),
                itemBuilder: (_, i) => InkWell(
                  onTap: () => onSelect(results[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(results[i]['name'] as String? ?? '',
                        style: _inter(size: 13, color: const Color(0xFF191C1E))),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact plain text field used inside the fulfill bottom sheet.
class _FulfillTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType inputType;

  const _FulfillTextField({
    required this.controller,
    required this.hint,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: _inter(size: 13, color: const Color(0xFF191C1E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _inter(size: 13, color: _secondary),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        filled: true,
        fillColor: _surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _surfaceContainer),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _surfaceContainer),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        isDense: true,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _secondary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: _inter(
                  size: 13, weight: FontWeight.w600, color: _secondary)),
          Text(value,
              style: _inter(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFF191C1E))),
        ],
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _LoadsEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child:
                  const Icon(Icons.search_off_rounded, size: 44, color: _primary),
            ),
            const SizedBox(height: 16),
            Text('No loads available',
                style: _manrope(size: 18, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'No pending load requirements at the moment.\nCheck back later or adjust your search.',
              textAlign: TextAlign.center,
              style: _inter(size: 13, color: _secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadsError extends ConsumerWidget {
  final String message;
  const _LoadsError({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 44, color: _error),
            const SizedBox(height: 12),
            Text('Could not load', style: _manrope(size: 16)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: _inter(size: 13, color: _secondary)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ref
                  .read(availableLoadsProvider.notifier)
                  .loadAvailableLoads(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Retry',
                    style: _inter(
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Records Tab ─────────────────────────────────────────────────────────────

class _RecordsTab extends ConsumerWidget {
  const _RecordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(completedTripsProvider);
    final trips = state.trips.where((t) => t.isCompleted).toList()
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    return RefreshIndicator(
      color: _primary,
      onRefresh: () => ref
          .read(completedTripsProvider.notifier)
          .loadTrips(statusFilter: 'completed'),
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
                        Text('Trip Records',
                            style: _manrope(size: 20, weight: FontWeight.w800)),
                        Text('All completed trips',
                            style: _inter(size: 12, color: _secondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7F0D9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${trips.length} completed',
                      style: _inter(
                          size: 11,
                          weight: FontWeight.w700,
                          color: const Color(0xFF1B5E20)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.error != null && trips.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: Color(0xFFBA1A1A)),
                    const SizedBox(height: 12),
                    Text(state.error!,
                        style: _inter(size: 13),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref
                          .read(completedTripsProvider.notifier)
                          .loadTrips(statusFilter: 'completed'),
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
                    Icon(Icons.folder_copy_outlined,
                        size: 64,
                        color: _secondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('No completed trips yet',
                        style: _manrope(
                            size: 15,
                            weight: FontWeight.w700,
                            color: _secondary)),
                    const SizedBox(height: 6),
                    Text('Completed trips will appear here',
                        style: _inter(size: 13, color: _secondary)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: OngoingTripCard(trip: trips[i], readOnly: true),
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

// ─── App Drawer ───────────────────────────────────────────────────────────────

class _AppDrawer extends ConsumerWidget {
  final dynamic user;
  final String role;
  final int navIndex;
  final ValueChanged<int> onNavTap;

  const _AppDrawer({
    required this.user,
    required this.role,
    required this.navIndex,
    required this.onNavTap,
  });

  static const _navItems = [
    (Icons.dashboard_rounded,      'Dashboard',       0),
    (Icons.inventory_2_outlined,   'Available Loads', 1),
    (Icons.folder_copy_outlined,   'Records',         3),
    (Icons.person_outline_rounded, 'Profile',         2),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name    = user?.fullName ?? 'Logistic Partner';
    final company = user?.companyName ?? '';
    final username = user?.username ?? '';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 24, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A2E44), Color(0xFF243B55)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _initials(name),
                      style: _manrope(
                          size: 18,
                          weight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: _manrope(
                        size: 15,
                        weight: FontWeight.w700,
                        color: Colors.white)),
                if (username.isNotEmpty)
                  Text('@$username',
                      style: _inter(
                          size: 12, color: Colors.white60)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _primary.withValues(alpha: 0.5)),
                      ),
                      child: Text(role,
                          style: _inter(
                              size: 10,
                              weight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    if (company.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(company,
                            style: _inter(size: 11, color: Colors.white54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Navigation ──────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('NAVIGATION',
                      style: _inter(
                          size: 10,
                          weight: FontWeight.w700,
                          color: _secondary)),
                ),
                ..._navItems.map((item) {
                  final (icon, label, index) = item;
                  final isActive = navIndex == index;
                  return _DrawerNavTile(
                    icon: icon,
                    label: label,
                    isActive: isActive,
                    onTap: () => onNavTap(index),
                  );
                }),
                _DrawerRequestsTile(ref: ref),
                _DrawerWorkersTile(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFECEEF0)),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text('MORE',
                      style: _inter(
                          size: 10,
                          weight: FontWeight.w700,
                          color: _secondary)),
                ),
                _DrawerActionTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Help & Support coming soon.',
                            style: _inter(size: 13, color: Colors.white)),
                        backgroundColor: _secondary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.info_outline_rounded,
                  label: 'About RR Logistics',
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'RR Logistics',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2025 RR Logistics',
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Logout ──────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Color(0xFFECEEF0)),
          ),
          InkWell(
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded,
                      color: Color(0xFFBA1A1A), size: 20),
                  const SizedBox(width: 14),
                  Text('Log Out',
                      style: _inter(
                          size: 14,
                          weight: FontWeight.w600,
                          color: const Color(0xFFBA1A1A))),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ─── Requests Drawer Tile (with badge) ────────────────────────────────────────

class _DrawerRequestsTile extends StatelessWidget {
  final WidgetRef ref;
  const _DrawerRequestsTile({required this.ref});

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(pendingWorkerCountProvider);
    final count = countAsync.valueOrNull ?? 0;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.push(AppConstants.routeWorkerRequests);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.group_add_rounded, size: 20, color: _secondary),
                if (count > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Text('Requests',
                style: _inter(size: 14, weight: FontWeight.w400, color: _onSurface)),
            if (count > 0) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count pending',
                  style: _inter(size: 11, weight: FontWeight.w600, color: _primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? _primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isActive ? _primary : _secondary),
            const SizedBox(width: 14),
            Text(label,
                style: _inter(
                    size: 14,
                    weight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? _primary : _onSurface)),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: _primary, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _secondary),
            const SizedBox(width: 14),
            Text(label,
                style: _inter(
                    size: 14,
                    weight: FontWeight.w400,
                    color: _onSurface)),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFF1A2E44),
            child: Text(
              _initials(user?.fullName ?? 'FO'),
              style: _manrope(
                  size: 28, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? '—',
              style: _manrope(size: 20, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(user?.email ?? '—',
              style: _inter(size: 14, color: _secondary)),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Logistic Partner',
                style: _inter(
                    size: 12,
                    weight: FontWeight.w700,
                    color: _primary)),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: _secondary),
            title: Text('Settings',
                style: _inter(
                    size: 15,
                    weight: FontWeight.w600,
                    color: _onSurface)),
            onTap: () => context.push('/fleet-manager/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: _error),
            title: Text('Logout',
                style: _inter(
                    size: 15,
                    weight: FontWeight.w600,
                    color: _error)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

// ─── Workers Drawer Tile ──────────────────────────────────────────────────────

class _DrawerWorkersTile extends StatelessWidget {
  const _DrawerWorkersTile();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LpWorkersScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.leaderboard_rounded, size: 20, color: _secondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Workers',
                style: _inter(size: 14, weight: FontWeight.w600, color: _onSurface),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: _secondary),
          ],
        ),
      ),
    );
  }
}

