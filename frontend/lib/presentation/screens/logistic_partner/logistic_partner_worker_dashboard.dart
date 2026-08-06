import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/providers/notification_provider.dart';
import 'package:fleet_management/data/models/notification_model.dart';
import 'package:fleet_management/presentation/widgets/rr_trip_card.dart';
import 'package:fleet_management/presentation/widgets/trip_search_field.dart';

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

// ─── Main screen ──────────────────────────────────────────────────────────────

class LogisticPartnerWorkerDashboard extends ConsumerStatefulWidget {
  const LogisticPartnerWorkerDashboard({super.key});

  @override
  ConsumerState<LogisticPartnerWorkerDashboard> createState() =>
      _LogisticPartnerWorkerDashboardState();
}

class _LogisticPartnerWorkerDashboardState
    extends ConsumerState<LogisticPartnerWorkerDashboard> {
  int _navIndex = 0;
  Timer? _pollTimer;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing,pending', rrWeb: true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    if (!mounted) return;
    ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing,pending', rrWeb: true);
  }

  void _switchNav(int index) {
    if (index == 0 && _navIndex != 0) {
      ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing,pending', rrWeb: true);
    }
    if (index == 1 && _navIndex != 1) {
      ref.read(completedTripsProvider.notifier).loadTrips(rrOnly: true);
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
    // When the LP worker receives a cancellation notification, immediately
    // remove the cancelled trip from Fleet Status without waiting for the 30s poll.
    ref.listen<NotificationsState>(notificationsProvider, (prev, next) {
      if (prev == null || next.items.length <= (prev.items.length)) return;
      final newest = next.items.first;
      if (newest.type == 'trip_cancelled' || newest.type == 'load_cancelled') {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing,pending');
      }
    });

    final user = ref.watch(authProvider).user;

    final pages = [
      const _WorkerHomeTab(),
      const _WorkerRecordsTab(),
      const _WorkerProfileTab(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _background,
      drawer: _WorkerDrawer(
        user: user,
        navIndex: _navIndex,
        onNavTap: (i) {
          _scaffoldKey.currentState?.closeDrawer();
          _switchNav(i);
        },
      ),
      body: Column(
        children: [
          _WorkerTopBar(
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
          Expanded(
            child: IndexedStack(index: _navIndex, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: _WorkerBottomNav(
        selectedIndex: _navIndex,
        onTap: _switchNav,
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : 'W';
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _WorkerTopBar extends ConsumerWidget {
  final VoidCallback onMenuTap;
  const _WorkerTopBar({required this.onMenuTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);
    final unread = notifState.items
        .where((n) => !n.isRead && (n.type == 'new_work' || n.type == 'trip_complete' || n.type == 'trip_cancelled' || n.type == 'load_cancelled'))
        .length;

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
                'RR LOGISTICS',
                style: _manrope(
                  size: 18,
                  weight: FontWeight.w900,
                  color: _primary,
                ).copyWith(letterSpacing: 1.0),
              ),
            ),
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
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
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
        child: const _WorkerNotificationsSheet(),
      ),
    );
  }
}

// ─── Notifications Bottom Sheet ───────────────────────────────────────────────

class _WorkerNotificationsSheet extends ConsumerStatefulWidget {
  const _WorkerNotificationsSheet();

  @override
  ConsumerState<_WorkerNotificationsSheet> createState() =>
      _WorkerNotificationsSheetState();
}

class _WorkerNotificationsSheetState
    extends ConsumerState<_WorkerNotificationsSheet> {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationsProvider).items;
    final newWorkNotifs = items
        .where((n) => n.type == 'new_work' || n.type == 'trip_complete' || n.type == 'trip_cancelled' || n.type == 'load_cancelled')
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
                  if (newWorkNotifs.any((n) => !n.isRead))
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
                  if (newWorkNotifs.isNotEmpty) ...[
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
              child: newWorkNotifs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 48,
                              color: _secondary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text('No notifications',
                              style: _inter(size: 14, color: _secondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: newWorkNotifs.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: Color(0xFFECEEF0)),
                      itemBuilder: (ctx, i) {
                        final n = newWorkNotifs[i];
                        return _WorkerNotifTile(
                          notif: n,
                          onDismiss: () => ref
                              .read(notificationsProvider.notifier)
                              .deleteOne(n.id),
                          onTap: () {
                            ref
                                .read(notificationsProvider.notifier)
                                .markRead(n.id);
                            Navigator.pop(context);
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

class _WorkerNotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _WorkerNotifTile(
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
        return Icons.local_shipping_outlined;
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
        return _tertiary;
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
        return _tertiary.withOpacity(0.12);
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

class _WorkerBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _WorkerBottomNav(
      {required this.selectedIndex, required this.onTap});

  static const _items = [
    (Icons.dashboard_rounded, 'DASHBOARD', 0),
    (Icons.history_rounded, 'RECORDS', 1),
    (Icons.person_outline, 'PROFILE', 2),
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
                children: _items.map((item) {
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
                          Icon(icon,
                              color: active ? Colors.white : _secondary,
                              size: 22),
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

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class _WorkerHomeTab extends ConsumerStatefulWidget {
  const _WorkerHomeTab();

  @override
  ConsumerState<_WorkerHomeTab> createState() => _WorkerHomeTabState();
}

class _WorkerHomeTabState extends ConsumerState<_WorkerHomeTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final user = ref.watch(authProvider).user;
    final firstName = user?.fullName.split(' ').first ?? 'Worker';
    // Fleet status: backend (rr_web=true) already scopes this to trips not yet
    // explicitly moved to Records (moved_to_records_at is null) — no extra
    // client-side filtering here. Finishing Stage 5 sync does NOT remove a
    // trip from this list; only the long-press "Move to Records" action does.
    final ongoingTrips = tripState.activeTrips;
    final filteredTrips = ongoingTrips
        .where((t) => matchesTripSearch(_query, t.tripNumber, t.rrTripNumber))
        .toList();

    return RefreshIndicator(
      color: _primary,
      onRefresh: () async {
        await ref
            .read(tripProvider.notifier)
            .loadTrips(statusFilter: 'ongoing,pending', rrWeb: true);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $firstName',
              style: _manrope(size: 22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text('Logistic Partner Worker',
                style: _inter(size: 13, color: _secondary)),
            const SizedBox(height: 24),

            // Fleet Status
            _WorkerFleetStatusHeader(
              tripCount: ongoingTrips.length,
              isLive: !tripState.isLoading,
            ),
            const SizedBox(height: 12),
            if (ongoingTrips.isNotEmpty) ...[
              TripSearchField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
            ],
            if (tripState.isLoading && ongoingTrips.isEmpty)
              _TripLoadingShimmer()
            else if (tripState.error != null && ongoingTrips.isEmpty)
              _TripsError(
                message: tripState.error!,
                onRetry: () => ref
                    .read(tripProvider.notifier)
                    .loadTrips(statusFilter: 'ongoing,pending', rrWeb: true),
              )
            else if (ongoingTrips.isEmpty)
              _EmptyTrips()
            else if (filteredTrips.isEmpty)
              _NoSearchMatches(query: _query)
            else
              ...filteredTrips.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: RrTripCard(
                    trip: t,
                    onRefresh: () => ref
                        .read(tripProvider.notifier)
                        .loadTrips(statusFilter: 'ongoing,pending', rrWeb: true),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Fleet Status Header ──────────────────────────────────────────────────────

class _WorkerFleetStatusHeader extends ConsumerWidget {
  final int tripCount;
  final bool isLive;
  const _WorkerFleetStatusHeader(
      {required this.tripCount, required this.isLive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastUpdated = ref.watch(tripProvider).lastUpdated;
    final updatedStr = lastUpdated != null ? _fmt(lastUpdated) : null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active Trips',
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
        if (isLive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                      shape: BoxShape.circle, color: Color(0xFF22C55E)),
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

// ─── Empty trips ──────────────────────────────────────────────────────────────

class _EmptyTrips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceContainer, width: 1.5),
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
            Text('You will be notified when a new trip is assigned',
                style: _inter(size: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── No search matches ────────────────────────────────────────────────────────

class _NoSearchMatches extends StatelessWidget {
  final String query;
  const _NoSearchMatches({required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceContainer, width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: _secondary, size: 40),
            const SizedBox(height: 8),
            Text('No trips match "$query"',
                style: _inter(size: 14, weight: FontWeight.w600, color: _secondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Trips error ──────────────────────────────────────────────────────────────

class _TripsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _TripsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _error.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: _error, size: 36),
          const SizedBox(height: 8),
          Text('Could not load trips',
              style:
                  _inter(size: 13, weight: FontWeight.w600, color: _error)),
          const SizedBox(height: 4),
          Text(message,
              textAlign: TextAlign.center,
              style: _inter(size: 12, color: _secondary)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _WorkerProfileTab extends ConsumerWidget {
  const _WorkerProfileTab();

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
            backgroundColor: _tertiary,
            child: Text(
              _initials(user?.fullName ?? 'W'),
              style: _manrope(
                  size: 28,
                  weight: FontWeight.w700,
                  color: Colors.white),
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
              color: _tertiary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Logistic Partner Worker',
                style: _inter(
                    size: 12,
                    weight: FontWeight.w700,
                    color: _tertiary)),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded, color: _secondary),
            title: Text('Help & Support',
                style: _inter(
                    size: 15,
                    weight: FontWeight.w600,
                    color: _onSurface)),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Help & Support coming soon.',
                    style: _inter(size: 13, color: Colors.white)),
                backgroundColor: _secondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
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

// ─── Records Tab ──────────────────────────────────────────────────────────────

class _WorkerRecordsTab extends ConsumerWidget {
  const _WorkerRecordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(completedTripsProvider);
    final trips = [...state.trips]
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    return RefreshIndicator(
      color: _primary,
      onRefresh: () => ref
          .read(completedTripsProvider.notifier)
          .loadTrips(rrOnly: true),
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
                        Text('Synced trips',
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
                      '${trips.length} synced',
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
              child: Center(child: CircularProgressIndicator()),
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
                          .loadTrips(rrOnly: true),
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
                    Text('No synced trips yet',
                        style: _manrope(
                            size: 15,
                            weight: FontWeight.w700,
                            color: _secondary)),
                    const SizedBox(height: 6),
                    Text('Trips synced to RR web will appear here',
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

// ─── App Drawer ───────────────────────────────────────────────────────────────

class _WorkerDrawer extends ConsumerWidget {
  final dynamic user;
  final int navIndex;
  final ValueChanged<int> onNavTap;

  const _WorkerDrawer({
    required this.user,
    required this.navIndex,
    required this.onNavTap,
  });

  static const _navItems = [
    (Icons.dashboard_rounded, 'Dashboard', 0),
    (Icons.history_rounded, 'Records', 1),
    (Icons.person_outline_rounded, 'Profile', 2),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user?.fullName ?? 'LP Worker';
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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _tertiary,
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
                      style: _inter(size: 12, color: Colors.white60)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _tertiary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _tertiaryContainer.withValues(alpha: 0.6)),
                      ),
                      child: Text('LP Worker',
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
                  return _WorkerDrawerNavTile(
                    icon: icon,
                    label: label,
                    isActive: isActive,
                    onTap: () => onNavTap(index),
                  );
                }),

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
                _WorkerDrawerActionTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Help & Support coming soon.',
                            style:
                                _inter(size: 13, color: Colors.white)),
                        backgroundColor: _secondary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
                _WorkerDrawerActionTile(
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
                _WorkerDrawerActionTile(
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

class _WorkerDrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _WorkerDrawerNavTile({
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
                size: 20, color: isActive ? _primary : _secondary),
            const SizedBox(width: 14),
            Text(label,
                style: _inter(
                    size: 14,
                    weight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
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

class _WorkerDrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WorkerDrawerActionTile({
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
