import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/providers/vehicle_provider.dart';
import 'package:fleet_management/providers/driver_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/providers/available_loads_provider.dart';
import 'package:fleet_management/data/models/load_requirement_model.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/presentation/widgets/rr_trip_card.dart';
import 'package:fleet_management/presentation/widgets/rr_connection_status.dart';
import 'package:fleet_management/providers/notification_provider.dart';
import 'package:fleet_management/data/models/notification_model.dart';
import 'package:fleet_management/presentation/widgets/available_loads_browser.dart';
import 'package:fleet_management/presentation/screens/fleet_owner/rr_trip_stages_screen.dart';
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
  StreamSubscription<NotificationModel>? _rrExpirySub;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Background refresh every 30 s
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing,pending', rrWeb: true);
        ref.read(availableLoadsProvider.notifier).silentRefresh();
      }
    });
    // Initial data load — runs after first frame so ref/auth are ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllData());

    // Live "RR session expiring soon" banner — the RrConnectionStatus badge
    // already shows this persistently, this catches it the moment it fires
    // while the dashboard is open, with a one-tap way to reconnect.
    _rrExpirySub = ref.read(notificationWsServiceProvider).stream.listen((n) {
      if (n.type != 'rr_session_expiring' || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(n.body, style: _inter(size: 13, color: Colors.white)),
        backgroundColor: const Color(0xFFB25E00),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Reconnect',
          textColor: Colors.white,
          onPressed: () => ensureRrSession(context, ref),
        ),
      ));
    });
  }

  void _showRrTripPopup(String value, String? tripId) {
    // Clear the provider immediately so it doesn't re-trigger
    ref.read(pendingRrTripNumberProvider.notifier).state = null;
    ref.read(pendingCreatedTripIdProvider.notifier).state = null;

    final isFailed = value.startsWith('__failed__:');

    // The trip-number popup closes on whichever comes first — the 3s timer or
    // the user tapping Continue/OK/the barrier — then the S1-required popup
    // follows immediately. showDialog's Future resolves on any of those, so
    // chaining off it (rather than the button's onPressed) covers all three.
    bool closed = false;
    final popupFuture = showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => isFailed
          ? AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 32),
                ),
                const SizedBox(height: 16),
                Text('Trip Created', style: _manrope(size: 15, weight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('RR sync failed: ${value.substring('__failed__:'.length)}',
                    style: _inter(size: 13, color: const Color(0xFF546067)),
                    textAlign: TextAlign.center),
              ]),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF6B00),
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 32),
                ),
                const SizedBox(height: 16),
                Text('Trip Synced to RR Web',
                    style: _manrope(size: 15, weight: FontWeight.w800),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('RR Trip Number', style: _inter(size: 12, color: const Color(0xFF546067))),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Trip number copied',
                            style: _inter(size: 13, color: Colors.white)),
                        backgroundColor: const Color(0xFF2E7D32),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(value,
                          style: _manrope(size: 20, weight: FontWeight.w800,
                              color: const Color(0xFFFF6B00))),
                      const SizedBox(width: 10),
                      const Icon(Icons.copy_rounded, size: 16,
                          color: Color(0xFFFF6B00)),
                    ]),
                  ),
                ),
              ]),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF6B00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: Text('Continue', style: _inter(size: 14, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
    ).then((_) {
      closed = true;
      if (mounted && tripId != null) _showS1RequiredPopup(tripId);
    });

    Timer(const Duration(seconds: 3), () {
      if (!closed && mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    });
  }

  void _showS1RequiredPopup(String tripId) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Field Executive — Stage 1', style: _manrope(size: 15, weight: FontWeight.w800)),
        content: Text(
          'Allow the Field Executive to fill Stage 1 (Truck Detail Registration) docs for this trip?\n\n'
          'You can change this later from the trip card.',
          style: _inter(size: 13, color: const Color(0xFF546067)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: Text('No', style: _inter(size: 14, weight: FontWeight.w600, color: const Color(0xFF546067))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF6B00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: Text('Yes', style: _inter(size: 14, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    ).then((allow) async {
      if (allow == false) {
        try {
          await ref.read(dioProvider).patch(
            '/api/trips/$tripId/s1-required',
            data: {'required': false},
          );
        } catch (_) {
          // Non-fatal — LP/RR-ops can retry via the toggle on the trip card.
        }
      }
    });
  }

  /// Load all dashboard data. Called on init and whenever Dashboard tab
  /// comes into focus (e.g. switching back from Loads tab).
  void _loadAllData() {
    if (!mounted) return;
    ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing,pending', rrWeb: true);
    ref.read(vehicleProvider.notifier).loadVehicles();
  }

  /// Switch tabs — refreshes fleet data whenever user navigates to Dashboard.
  Future<void> _switchNav(int index) async {
    if (index == 0 && _navIndex != 0) {
      ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing,pending', rrWeb: true);
    }
    if (index == 3 && _navIndex != 3) {
      // Load completed RR trips fresh each time Records tab is opened
      ref.read(completedTripsProvider.notifier).loadTrips(rrOnly: true);
    }
    setState(() => _navIndex = index);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _rrExpirySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show RR trip number popup whenever a new trip is created via CreateTripScreen
    ref.listen<String?>(pendingRrTripNumberProvider, (_, next) {
      if (next != null) {
        final tripId = ref.read(pendingCreatedTripIdProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) => _showRrTripPopup(next, tripId));
      }
    });

    // When the LP receives a cancellation notification, immediately remove
    // the cancelled trip from Fleet Status without waiting for the 30s poll.
    ref.listen<NotificationsState>(notificationsProvider, (prev, next) {
      if (prev == null || next.items.length <= (prev.items.length)) return;
      final newest = next.items.first;
      if (newest.type == 'trip_cancelled' && newest.tripId != null) {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing,pending', rrWeb: true);
      } else if (newest.type == 'load_cancelled') {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing,pending', rrWeb: true);
      }
    });

    final user = ref.watch(authProvider).user;

    final pages = [
      _DashboardTab(onSearchLoads: () => _switchNav(1)),
      const AvailableLoadsBrowser(),
      const _ProfileTab(),
      const _RecordsTab(),
      const _ComingSoonTab(label: 'Fleet Hub', icon: Icons.local_shipping_outlined),
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

// ─── Coming Soon Tab ──────────────────────────────────────────────────────────

class _ComingSoonTab extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ComingSoonTab({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: _primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Coming Soon',
                style: _inter(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: _manrope(
                    size: 20,
                    weight: FontWeight.w800,
                    color: const Color(0xFF191C1E))),
            const SizedBox(height: 8),
            Text(
              'This section is under development\nand will be available soon.',
              style: _inter(size: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selectedIndex, required this.onTap});

  // (icon, label, navIndex, comingSoon)
  static const _allItems = [
    (Icons.dashboard_rounded,        'DASHBOARD', 0, false),
    (Icons.search_rounded,           'LOADS',     1, false),
    (Icons.local_shipping_outlined,  'FLEET',     4, true),
    (Icons.folder_copy_outlined,     'RECORDS',   3, false),
    (Icons.person_outline,           'PROFILE',   2, false),
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
                  final (icon, label, navIdx, comingSoon) = item;
                  final active = navIdx == selectedIndex;
                  return Opacity(
                    opacity: comingSoon ? 0.45 : 1.0,
                    child: GestureDetector(
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
                              comingSoon ? 'SOON' : label,
                              style: _inter(
                                size: 9,
                                weight: FontWeight.w700,
                                color: active ? Colors.white : _secondary,
                              ).copyWith(letterSpacing: 0.6),
                            ),
                          ],
                        ),
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
  final VoidCallback onSearchLoads;
  const _DashboardTab({required this.onSearchLoads});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(tripProvider);
    final user = ref.watch(authProvider).user;
    final firstName = user?.fullName.split(' ').first ?? 'Logistic Partner';

    // Fleet status: backend (rr_web=true) already scopes this to trips not yet
    // explicitly moved to Records (moved_to_records_at is null) — no extra
    // client-side filtering here. Finishing Stage 5 sync does NOT remove a
    // trip from this list; only the long-press "Move to Records" action does.
    final ongoingTrips = tripState.activeTrips;

    return RefreshIndicator(
      color: _primary,
      onRefresh: () async {
        await ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing,pending', rrWeb: true);
      },
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Welcome back, $firstName',
                  style: _manrope(size: 22, weight: FontWeight.w800),
                ),
              ),
              const RrConnectionStatus(),
            ],
          ),
          const SizedBox(height: 2),
          Text('Logistic Partner Panel',
              style: _inter(size: 13, color: _secondary)),
          const SizedBox(height: 16),

          // Search New Loads
          _SearchLoadsComingSoon(onTap: onSearchLoads),
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
            // This list is already server-filtered to rr_web:true trips (see
            // loadTrips(statusFilter: 'ongoing,pending') above, which the
            // backend scopes to RR-web trips for this dashboard) — every trip
            // here is an RR-web trip by construction, so always use RrTripCard.
            // Previously this branched on `t.rrTripId != null`, which wrongly
            // fell back to the generic OngoingTripCard whenever RR's own
            // /create_trip failed partway (rr_trip_id stays null even though
            // rr_vehicle_id/rr_driver_id are set) — hiding RR branding/actions
            // on exactly the trips that most need them (failed bookings).
            ...ongoingTrips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: RrTripCard(
                  trip: t,
                  onRefresh: () {
                    ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing,pending');
                    ref.read(completedTripsProvider.notifier).loadTrips(rrOnly: true);
                  },
                ),
              ),
            ),
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

// ─── Search New Loads ─────────────────────────────────────────────────────────

class _SearchLoadsComingSoon extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchLoadsComingSoon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFE55C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
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
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
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
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateTripScreen()),
            );
          },
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateTripScreen()),
                );
              },
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
  final _amountController      = TextEditingController();
  final _transporterController = TextEditingController();
  List<Map<String, dynamic>> _transporterResults     = [];
  bool _transporterSearchLoading                     = false;
  Timer? _transporterDebounce;
  bool _isLoading = false;
  String? _transporterError;
  String? _consignorError;
  String? _consigneeError;
  String? _rrOpsError;
  String? _amountError;
  String? _rrError;

  // ── RR Parties ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _partners            = [];
  bool _partnersLoading                           = false;

  // Consignor
  Map<String, dynamic>? _consignorPartner;
  List<Map<String, dynamic>> _consignorCompanies  = [];
  bool _consignorCompaniesLoading                 = false;
  String? _selectedConsignorId;    // rr_company_id
  String? _selectedConsignorName;
  List<Map<String, dynamic>> _consignorAddresses  = [];

  // Consignee
  Map<String, dynamic>? _consigneePartner;
  List<Map<String, dynamic>> _consigneeCompanies  = [];
  bool _consigneeCompaniesLoading                 = false;
  String? _selectedConsigneeId;    // rr_company_id
  String? _selectedConsigneeName;
  List<Map<String, dynamic>> _consigneeAddresses  = [];

  // Ops worker (from RR company-workers)
  List<Map<String, dynamic>> _opsWorkers          = [];
  bool _opsWorkersLoading                         = false;
  String? _selectedRrOpsId;        // rr_user_id from RR (used as dropdown key)
  String? _selectedRrOpsLocalId;   // local_user_id (UUID) sent to fulfill endpoint
  String? _selectedRrOpsName;

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
  String _weightUnit      = 'TONNES';  // RR-native default
  List<String> _quantityUnits    = const ['TONNES', 'KILOGRAMS', 'LITRES', 'BOX', 'CUBIC METERS'];
  List<String> _vehicleBodyTypes = const [];
  String? _vehicleBodyType;
  final _invoiceValueCtrl = TextEditingController();

  // ── Consignor / Consignee info ───────────────────────────────────────────────
  final _consignorNameCtrl  = TextEditingController();
  final _consignorGstinCtrl = TextEditingController();
  final _consigneeNameCtrl  = TextEditingController();
  final _consigneeGstinCtrl = TextEditingController();

  // ── Pickup address ─────────────────────────────────────────────────────────
  final _pickupLine1Ctrl    = TextEditingController();
  final _pickupLine2Ctrl    = TextEditingController();
  final _pickupPinCtrl      = TextEditingController();
  bool  _pickupNoEntryZone  = false;

  // ── Unload address ─────────────────────────────────────────────────────────
  final _unloadLine1Ctrl    = TextEditingController();
  final _unloadLine2Ctrl    = TextEditingController();
  final _unloadPinCtrl      = TextEditingController();
  bool  _unloadNoEntryZone  = false;

  // ── Parcel info ────────────────────────────────────────────────────────────
  final _parcelDescCtrl     = TextEditingController();
  bool  _partLoad           = false;
  final _depotCodeCtrl      = TextEditingController();

  // ── Vehicle requirements ───────────────────────────────────────────────────
  String? _axleType;
  int?    _numberOfWheels;
  final _expectedFreightCtrl = TextEditingController();

  static const _axleTypes    = ['Single', 'Double', 'Triple', 'Multiple'];
  static const _wheelOptions = [4, 6, 8, 10, 12, 14, 16, 18, 22];

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
      _loadRrPartyData();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transporterController.dispose();
    _transporterDebounce?.cancel();
    _pickupCityCtrl.dispose();
    _dropCityCtrl.dispose();
    _rrMaterialCtrl.dispose();
    _weightCtrl.dispose();
    _invoiceValueCtrl.dispose();
    _pickupCityDebounce?.cancel();
    _dropCityDebounce?.cancel();
    _materialDebounce?.cancel();
    _consignorNameCtrl.dispose();
    _consignorGstinCtrl.dispose();
    _consigneeNameCtrl.dispose();
    _consigneeGstinCtrl.dispose();
    _pickupLine1Ctrl.dispose();
    _pickupLine2Ctrl.dispose();
    _pickupPinCtrl.dispose();
    _unloadLine1Ctrl.dispose();
    _unloadLine2Ctrl.dispose();
    _unloadPinCtrl.dispose();
    _parcelDescCtrl.dispose();
    _depotCodeCtrl.dispose();
    _expectedFreightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRrPartyData() async {
    final api = ref.read(apiServiceProvider).dio;

    // Enums only need RR4 auth — fire immediately, no RR session required.
    api.get('/api/rr/enums', queryParameters: {'name': 'QuantityUnit'})
        .then((r) {
          if (!mounted) return;
          final vals = (r.data['values'] as List? ?? []).cast<String>();
          if (vals.isNotEmpty) {
            setState(() {
              _quantityUnits = vals;
              if (!_quantityUnits.contains(_weightUnit)) _weightUnit = _quantityUnits.first;
            });
          }
        }).catchError((_) {});
    api.get('/api/rr/enums', queryParameters: {'name': 'VehicleBodyTypes'})
        .then((r) {
          if (!mounted) return;
          setState(() {
            _vehicleBodyTypes = (r.data['values'] as List? ?? []).cast<String>();
          });
        }).catchError((_) {});

    // Partners + workers use the org's own RR session — no personal login
    // needed unless it's genuinely expired. runRrAction reactively prompts
    // login only if the backend responds 409 (org has no valid session),
    // instead of pre-emptively checking here and missing the case where the
    // session expires between the check and the actual call. Sequential, not
    // parallel — running both through runRrAction concurrently risks two
    // login dialogs stacking if the org has no RR session at all. The first
    // call resolves the session (prompting once if needed); the second then
    // runs with that same now-valid session.
    setState(() { _partnersLoading = true; _opsWorkersLoading = true; });
    try {
      final r = await runRrAction(context, ref, () => api.get('/api/rr/preferred-partners'));
      if (mounted) setState(() {
        _partners = (r.data['partners'] as List? ?? []).cast<Map<String, dynamic>>();
        _partnersLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _partnersLoading = false);
    }
    try {
      final r = await runRrAction(context, ref, () => api.get('/api/rr/company-workers'));
      if (mounted) setState(() {
        _opsWorkers = (r.data['workers'] as List? ?? []).cast<Map<String, dynamic>>();
        _opsWorkersLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _opsWorkersLoading = false);
    }
  }

  Future<void> _loadCompanyLocations(String? companyId, {required bool isConsignor}) async {
    if (companyId == null || companyId.isEmpty) return;
    try {
      final resp = await runRrAction(context, ref, () => ref.read(apiServiceProvider).dio.get(
        '/api/rr/operation-locations',
        queryParameters: {'company_id': companyId},
      ));
      final locs = (resp.data['locations'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      if (isConsignor) setState(() => _consignorAddresses = locs);
      else             setState(() => _consigneeAddresses = locs);
    } catch (_) {}
  }

  Future<void> _loadPartnerCompanies(Map<String, dynamic> partner, {required bool isConsignor}) async {
    final rrUserId = partner['rr_user_id'] as String?;
    if (rrUserId == null) {
      final companyId = partner['rr_company_id'] as String?;
      final name = partner['name'] as String? ?? '';
      if (isConsignor) setState(() {
        _selectedConsignorId = companyId; _selectedConsignorName = name; _consignorCompanies = [];
        _consignorAddresses  = [];
      });
      else setState(() {
        _selectedConsigneeId = companyId; _selectedConsigneeName = name; _consigneeCompanies = [];
        _consigneeAddresses  = [];
      });
      _loadCompanyLocations(companyId, isConsignor: isConsignor);
      return;
    }
    if (isConsignor) setState(() => _consignorCompaniesLoading = true);
    else             setState(() => _consigneeCompaniesLoading = true);
    try {
      final resp = await runRrAction(context, ref, () => ref.read(apiServiceProvider).dio.get(
        '/api/rr/partner-companies',
        queryParameters: {'user_id': rrUserId},
      ));
      final companies = (resp.data['companies'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      if (isConsignor) setState(() { _consignorCompanies = companies; _consignorCompaniesLoading = false; });
      else             setState(() { _consigneeCompanies = companies; _consigneeCompaniesLoading = false; });
    } catch (_) {
      if (!mounted) return;
      if (isConsignor) setState(() => _consignorCompaniesLoading = false);
      else             setState(() => _consigneeCompaniesLoading = false);
    }
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
    if (_selectedRrOpsId != null && _selectedRrOpsLocalId == null) opsErr = 'Selected worker is not registered in RR4 — ask them to log in first';
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

    // Ensure valid RR session just before submit — token may have expired while form was filled
    final rrSession = await ensureRrSession(context, ref);
    if (!mounted) return;

    try {
      final invoiceVal = double.tryParse(_invoiceValueCtrl.text.trim());
      final ef = double.tryParse(_expectedFreightCtrl.text.trim());
      final consignorName  = _consignorNameCtrl.text.trim();
      final consignorGstin = _consignorGstinCtrl.text.trim();
      final consigneeName  = _consigneeNameCtrl.text.trim();
      final consigneeGstin = _consigneeGstinCtrl.text.trim();
      final pl1 = _pickupLine1Ctrl.text.trim();
      final pl2 = _pickupLine2Ctrl.text.trim();
      final pp  = _pickupPinCtrl.text.trim();
      final ul1 = _unloadLine1Ctrl.text.trim();
      final ul2 = _unloadLine2Ctrl.text.trim();
      final up  = _unloadPinCtrl.text.trim();
      final desc      = _parcelDescCtrl.text.trim();
      final depotCode = _depotCodeCtrl.text.trim();
      final resp = await api.dio.post(
        '/api/loads/${widget.load.id}/fulfill',
        data: {
          if (_selectedVehicleId != null) 'vehicle_id': _selectedVehicleId,
          if (_selectedDriverId != null) 'driver_id': _selectedDriverId,
          if (amount != null) 'trip_amount': amount,
          if (_selectedConsignorId != null) 'consignor_rr_company_id': _selectedConsignorId,
          if (_selectedConsigneeId != null) 'consignee_rr_company_id': _selectedConsigneeId,
          if (_selectedRrOpsLocalId != null) 'rr_ops_user_id': _selectedRrOpsLocalId,
          if (_selectedTransporterId != null) 'transporter_user_id': _selectedTransporterId,
          'origin_rr_city_id': _pickupCityId,
          'destination_rr_city_id': _dropCityId,
          'material_rr_id': _materialRrId,
          'weight_value': weightVal,
          'weight_unit': _weightUnit,
          if (invoiceVal != null) 'invoice_value': invoiceVal,
          if (_vehicleBodyType != null) 'vehicle_body_type': _vehicleBodyType,
          // Consignor / Consignee info
          if (consignorName.isNotEmpty)  'consignor_name':  consignorName,
          if (consignorGstin.isNotEmpty) 'consignor_gstin': consignorGstin,
          if (consigneeName.isNotEmpty)  'consignee_name':  consigneeName,
          if (consigneeGstin.isNotEmpty) 'consignee_gstin': consigneeGstin,
          // Pickup address
          if (pl1.isNotEmpty) 'pickup_address_line1': pl1,
          if (pl2.isNotEmpty) 'pickup_address_line2': pl2,
          if (pp.isNotEmpty)  'pickup_pin':           pp,
          'pickup_no_entry_zone': _pickupNoEntryZone,
          // Unload address
          if (ul1.isNotEmpty) 'unload_address_line1': ul1,
          if (ul2.isNotEmpty) 'unload_address_line2': ul2,
          if (up.isNotEmpty)  'unload_pin':           up,
          'unload_no_entry_zone': _unloadNoEntryZone,
          // Parcel info
          if (desc.isNotEmpty)      'parcel_description': desc,
          if (depotCode.isNotEmpty) 'depot_code':         depotCode,
          'part_load': _partLoad,
          // Vehicle requirements
          if (_axleType       != null) 'axle_type':        _axleType,
          if (_numberOfWheels != null) 'number_of_wheels': _numberOfWheels,
          if (ef != null)              'expected_freight':  ef,
          if (rrSession != null && rrSession.isValid) 'rr_token': rrSession.token,
        },
      );

      final tripData = resp.data['trip'] as Map<String, dynamic>;
      final trip = TripModel.fromJson(tripData);

      ref.read(tripProvider.notifier).patchTrip(trip);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final trips = ref.read(tripProvider.notifier);
      final nav = Navigator.of(context);
      nav.pop();
      nav.push(
        MaterialPageRoute(builder: (_) => RrTripStagesScreen(trip: trip)),
      ).then((_) {
        trips.loadTrips(statusFilter: 'ongoing,pending');
      });

      final rrNum = trip.rrTripNumber;
      if (rrNum != null && rrNum.isNotEmpty) {
        messenger.showSnackBar(SnackBar(
          content: Text('Synced to RR web — Trip $rrNum'),
          backgroundColor: const Color(0xFF006B5E),
          duration: const Duration(seconds: 4),
        ));
      } else if (trip.rrSyncStatus == 'failed') {
        messenger.showSnackBar(SnackBar(
          content: Text('Trip created. RR sync failed: ${trip.rrSyncError ?? 'unknown error'}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ));
      }
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
              if (_partnersLoading)
                const _PartyLoadingRow()
              else if (_selectedConsignorId != null)
                _PartySelectedChip(
                  icon: Icons.business_outlined,
                  name: _selectedConsignorName ?? 'Consignor selected',
                  color: _primary,
                  bg: const Color(0xFFFFF3E0),
                  onClear: () => setState(() {
                    _selectedConsignorId    = null;
                    _selectedConsignorName  = null;
                    _consignorPartner       = null;
                    _consignorCompanies     = [];
                  }),
                )
              else ...[
                _PartyDropdown<Map<String, dynamic>>(
                  hint: 'Select consignor partner (optional)',
                  icon: Icons.handshake_outlined,
                  value: _consignorPartner,
                  items: _partners,
                  label: (p) => p['name'] as String? ?? '—',
                  onChanged: (p) {
                    setState(() {
                      _consignorPartner   = p;
                      _consignorCompanies = [];
                      _selectedConsignorId   = null;
                      _selectedConsignorName = null;
                    });
                    if (p != null) _loadPartnerCompanies(p, isConsignor: true);
                  },
                ),
                const SizedBox(height: 8),
                if (_consignorCompaniesLoading)
                  const _PartyLoadingRow()
                else
                  _PartyDropdown<Map<String, dynamic>>(
                    hint: _consignorPartner == null
                        ? 'Select a partner above first'
                        : 'Select consignor company',
                    icon: Icons.business_outlined,
                    value: _consignorCompanies.cast<Map<String,dynamic>?>()
                        .firstWhere((c) => c?['rr_company_id'] == _selectedConsignorId, orElse: () => null),
                    items: _consignorPartner == null ? [] : _consignorCompanies,
                    label: (c) => c['name'] as String? ?? '—',
                    onChanged: _consignorPartner == null ? null : (c) {
                      final id = c?['rr_company_id'] as String?;
                      setState(() {
                        _selectedConsignorId   = id;
                        _selectedConsignorName = c?['name'] as String?;
                        _consignorError        = null;
                        _consignorAddresses    = [];
                      });
                      _loadCompanyLocations(id, isConsignor: true);
                    },
                  ),
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
              if (_partnersLoading)
                const _PartyLoadingRow()
              else if (_selectedConsigneeId != null)
                _PartySelectedChip(
                  icon: Icons.move_to_inbox_outlined,
                  name: _selectedConsigneeName ?? 'Consignee selected',
                  color: const Color(0xFF00796B),
                  bg: const Color(0xFFE0F2F1),
                  onClear: () => setState(() {
                    _selectedConsigneeId    = null;
                    _selectedConsigneeName  = null;
                    _consigneePartner       = null;
                    _consigneeCompanies     = [];
                  }),
                )
              else ...[
                _PartyDropdown<Map<String, dynamic>>(
                  hint: 'Select consignee partner (optional)',
                  icon: Icons.handshake_outlined,
                  value: _consigneePartner,
                  items: _partners,
                  label: (p) => p['name'] as String? ?? '—',
                  onChanged: (p) {
                    setState(() {
                      _consigneePartner   = p;
                      _consigneeCompanies = [];
                      _selectedConsigneeId   = null;
                      _selectedConsigneeName = null;
                      _consigneeAddresses    = (p?['postal_addresses'] as List? ?? []).cast<Map<String,dynamic>>();
                    });
                    if (p != null) _loadPartnerCompanies(p, isConsignor: false);
                  },
                ),
                const SizedBox(height: 8),
                if (_consigneeCompaniesLoading)
                  const _PartyLoadingRow()
                else
                  _PartyDropdown<Map<String, dynamic>>(
                    hint: _consigneePartner == null
                        ? 'Select a partner above first'
                        : 'Select consignee company',
                    icon: Icons.business_outlined,
                    value: _consigneeCompanies.cast<Map<String,dynamic>?>()
                        .firstWhere((c) => c?['rr_company_id'] == _selectedConsigneeId, orElse: () => null),
                    items: _consigneePartner == null ? [] : _consigneeCompanies,
                    label: (c) => c['name'] as String? ?? '—',
                    onChanged: _consigneePartner == null ? null : (c) {
                      final id = c?['rr_company_id'] as String?;
                      setState(() {
                        _selectedConsigneeId   = id;
                        _selectedConsigneeName = c?['name'] as String?;
                        _consigneeError        = null;
                        _consigneeAddresses    = [];
                      });
                      _loadCompanyLocations(id, isConsignor: false);
                    },
                  ),
              ],
              if (_consigneeError != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.error_outline, size: 13, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(_consigneeError!, style: _inter(size: 11, color: Colors.red)),
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
                      value: _quantityUnits.contains(_weightUnit) ? _weightUnit : _quantityUnits.first,
                      style: _inter(size: 13, color: const Color(0xFF191C1E)),
                      icon: const Icon(Icons.expand_more_rounded, size: 18),
                      items: _quantityUnits.map((u) =>
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
              const SizedBox(height: 12),

              // Vehicle body type
              Text('Vehicle Body Type', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _vehicleBodyTypes.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _surfaceContainer),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 8),
                        Text('Loading…', style: _inter(size: 13)),
                      ]),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _surfaceContainer),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _vehicleBodyType,
                          hint: Text('Select body type', style: _inter(size: 13)),
                          isExpanded: true,
                          style: _inter(size: 13, color: const Color(0xFF191C1E)),
                          icon: const Icon(Icons.expand_more_rounded, size: 18),
                          items: _vehicleBodyTypes.map((t) =>
                              DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _vehicleBodyType = v),
                        ),
                      ),
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

              // ── Consignor Info ─────────────────────────────────────────────
              _FulfillSectionHeader(label: 'Consignor Info'),
              const SizedBox(height: 10),
              Text('Name', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _consignorNameCtrl, hint: 'e.g. Tata Steel Ltd'),
              const SizedBox(height: 10),
              Text('GSTIN', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _consignorGstinCtrl, hint: 'e.g. 27AABCT3518Q1ZV'),
              const SizedBox(height: 20),

              // ── Consignee Info ─────────────────────────────────────────────
              _FulfillSectionHeader(label: 'Consignee Info'),
              const SizedBox(height: 10),
              Text('Name', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _consigneeNameCtrl, hint: 'e.g. JSW Steel Ltd'),
              const SizedBox(height: 10),
              Text('GSTIN', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _consigneeGstinCtrl, hint: 'e.g. 27AABCJ1234P1ZX'),
              const SizedBox(height: 20),

              // ── Pickup Address ─────────────────────────────────────────────
              _FulfillSectionHeader(label: 'Pickup Address'),
              const SizedBox(height: 10),
              Text('Address Line 1', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _pickupLine1Ctrl, hint: 'Street / area'),
              const SizedBox(height: 10),
              Text('Address Line 2', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _pickupLine2Ctrl, hint: 'Landmark / locality'),
              const SizedBox(height: 10),
              Text('PIN Code', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _pickupPinCtrl, hint: '6-digit PIN', inputType: TextInputType.number),
              const SizedBox(height: 8),
              _FulfillCheckboxRow(
                label: 'No Entry Zone',
                value: _pickupNoEntryZone,
                onChanged: (v) => setState(() => _pickupNoEntryZone = v ?? false),
              ),
              const SizedBox(height: 20),

              // ── Unload Address ─────────────────────────────────────────────
              _FulfillSectionHeader(label: 'Unload Address'),
              const SizedBox(height: 10),
              Text('Address Line 1', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _unloadLine1Ctrl, hint: 'Street / area'),
              const SizedBox(height: 10),
              Text('Address Line 2', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _unloadLine2Ctrl, hint: 'Landmark / locality'),
              const SizedBox(height: 10),
              Text('PIN Code', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _unloadPinCtrl, hint: '6-digit PIN', inputType: TextInputType.number),
              const SizedBox(height: 8),
              _FulfillCheckboxRow(
                label: 'No Entry Zone',
                value: _unloadNoEntryZone,
                onChanged: (v) => setState(() => _unloadNoEntryZone = v ?? false),
              ),
              const SizedBox(height: 20),

              // ── Parcel Info ────────────────────────────────────────────────
              _FulfillSectionHeader(label: 'Parcel Info'),
              const SizedBox(height: 10),
              Text('Description', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _parcelDescCtrl, hint: 'e.g. Steel coils'),
              const SizedBox(height: 10),
              Text('Depot Code', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(controller: _depotCodeCtrl, hint: 'e.g. KNP01'),
              const SizedBox(height: 8),
              _FulfillCheckboxRow(
                label: 'Part Load',
                value: _partLoad,
                onChanged: (v) => setState(() => _partLoad = v ?? false),
              ),
              const SizedBox(height: 20),

              // ── Vehicle Requirements ───────────────────────────────────────
              _FulfillSectionHeader(label: 'Vehicle Requirements'),
              const SizedBox(height: 10),
              Text('Axle Type', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _surfaceContainer),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _axleType,
                    isExpanded: true,
                    hint: Text('Select axle type', style: _inter(size: 13, color: _secondary)),
                    style: _inter(size: 13, color: const Color(0xFF191C1E)),
                    icon: const Icon(Icons.expand_more_rounded, size: 18),
                    items: _axleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _axleType = v),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text('Number of Wheels', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _surfaceContainer),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _numberOfWheels,
                    isExpanded: true,
                    hint: Text('Select wheel count', style: _inter(size: 13, color: _secondary)),
                    style: _inter(size: 13, color: const Color(0xFF191C1E)),
                    icon: const Icon(Icons.expand_more_rounded, size: 18),
                    items: _wheelOptions.map((w) => DropdownMenuItem<int>(
                      value: w, child: Text('$w wheels'),
                    )).toList(),
                    onChanged: (v) => setState(() => _numberOfWheels = v),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text('Expected Freight (₹)', style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
              const SizedBox(height: 6),
              _FulfillTextField(
                controller: _expectedFreightCtrl,
                hint: 'e.g. 45000',
                inputType: TextInputType.number,
              ),
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
              if (_opsWorkersLoading)
                const _PartyLoadingRow()
              else if (_opsWorkers.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _surfaceContainer),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 15, color: _secondary),
                    const SizedBox(width: 8),
                    Text('No RR Ops workers found for your company',
                        style: _inter(size: 12, color: _secondary)),
                  ]),
                )
              else
                _PartyDropdown<Map<String, dynamic>>(
                  hint: 'Select RR Ops worker',
                  icon: Icons.sync_alt,
                  value: _opsWorkers.cast<Map<String,dynamic>?>()
                      .firstWhere((w) => w?['rr_user_id'] == _selectedRrOpsId, orElse: () => null),
                  items: _opsWorkers,
                  label: (w) {
                    final name = w['name'] as String? ?? '—';
                    final phone = (w['phone'] as Map?)?['number'] as String? ?? '';
                    return phone.isNotEmpty ? '$name · $phone' : name;
                  },
                  onChanged: (w) => setState(() {
                    _selectedRrOpsId      = w?['rr_user_id'] as String?;
                    _selectedRrOpsLocalId = w?['local_user_id'] as String?;
                    _selectedRrOpsName    = w?['name'] as String?;
                    _rrOpsError           = null;
                  }),
                ),
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

// ── Party picker helpers ──────────────────────────────────────────────────────

class _PartyLoadingRow extends StatelessWidget {
  const _PartyLoadingRow();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _surfaceContainer),
        ),
        child: const Row(children: [
          SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Loading…', style: TextStyle(fontSize: 13, color: _secondary)),
        ]),
      );
}

class _PartySelectedChip extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color color;
  final Color bg;
  final VoidCallback onClear;
  const _PartySelectedChip({
    required this.icon, required this.name, required this.color,
    required this.bg, required this.onClear,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(name,
              style: _inter(size: 13, weight: FontWeight.w600, color: color))),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close, size: 18, color: color),
          ),
        ]),
      );
}

class _PartyDropdown<T> extends StatelessWidget {
  final String hint;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T?>? onChanged;   // nullable → null disables the dropdown
  const _PartyDropdown({
    required this.hint, required this.icon, required this.value,
    required this.items, required this.label, required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF2F4F6) : _surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _surfaceContainer),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            hint: Row(children: [
              Icon(icon, size: 16, color: _secondary),
              const SizedBox(width: 8),
              Text(hint, style: _inter(size: 13, color: _secondary)),
            ]),
            style: _inter(size: 13, color: const Color(0xFF191C1E)),
            icon: Icon(Icons.expand_more_rounded, size: 18,
                color: disabled ? _surfaceContainer : null),
            items: disabled ? null : items.map((item) => DropdownMenuItem<T>(
              value: item,
              child: Text(label(item), overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: onChanged,
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
class _FulfillSectionHeader extends StatelessWidget {
  final String label;
  const _FulfillSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 3, height: 14,
          decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: _manrope(size: 13, weight: FontWeight.w800)),
    ],
  );
}

class _FulfillCheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _FulfillCheckboxRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 20, height: 20,
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: _primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: BorderSide(color: _secondary),
        ),
      ),
      const SizedBox(width: 10),
      Text(label, style: _inter(size: 13, color: const Color(0xFF191C1E))),
    ],
  );
}

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
    final trips = state.trips
        .where((t) => t.rrTripId != null && t.rrTripId!.isNotEmpty)
        .toList()
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
                        Text('Completed RR Web trips',
                            style: _inter(size: 12, color: _secondary)),
                      ],
                    ),
                  ),
                  if (!state.isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3FC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${trips.length} trips',
                        style: _inter(
                            size: 11,
                            weight: FontWeight.w700,
                            color: const Color(0xFF1B6CA8)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: _primary),
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
                          .loadTrips(rrOnly: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (trips.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B6CA8).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sync_alt_rounded,
                            size: 32, color: Color(0xFF1B6CA8)),
                      ),
                      const SizedBox(height: 16),
                      Text('No RR Web records yet',
                          style: _manrope(
                              size: 15,
                              weight: FontWeight.w700,
                              color: _secondary)),
                      const SizedBox(height: 6),
                      Text('Completed RR Web trips will appear here',
                          style: _inter(size: 13, color: _secondary),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.separated(
                itemCount: trips.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => RrTripCard(
                  trip: trips[i],
                  onRefresh: () => ref
                      .read(completedTripsProvider.notifier)
                      .loadTrips(rrOnly: true),
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
                  child: Text('RR QUICK ADD',
                      style: _inter(
                          size: 10,
                          weight: FontWeight.w700,
                          color: _secondary)),
                ),
                _DrawerActionTile(
                  icon: Icons.local_shipping_outlined,
                  label: 'Add Vehicle',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/rr/add-vehicle');
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.apartment_outlined,
                  label: 'Add Company',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/rr/add-company');
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.person_add_alt_outlined,
                  label: 'Add Driver',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/rr/add-user');
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Vehicle Hire Requests',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/rr/vehicle-hire-requests');
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.storefront_outlined,
                  label: 'Hire Truck',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/rr/add-market-vehicle');
                  },
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
                'Employees',
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

