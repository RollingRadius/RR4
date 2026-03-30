import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/providers/notification_provider.dart';
import 'package:fleet_management/data/models/notification_model.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/presentation/widgets/ongoing_trip_card.dart';
import 'package:fleet_management/presentation/screens/shared/truck_tracking_screen.dart';
import 'package:fleet_management/presentation/screens/load_owner/shipment_details_screen.dart';
import 'package:fleet_management/presentation/screens/load_owner/upload_load_requirement_screen.dart';

// ─── Typography helpers (Stitch: Manrope headline, Inter body) ────────────────
TextStyle _manrope(
        {double size = 14,
        FontWeight weight = FontWeight.w600,
        Color color = const Color(0xFF191C1E)}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter(
        {double size = 13,
        FontWeight weight = FontWeight.w400,
        Color color = const Color(0xFF546067)}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

// ─── Colour tokens ────────────────────────────────────────────────────────────
const _primary = Color(0xFFFF6B00);
const _background = Color(0xFFF8F9FB);
const _surfaceLowest = Color(0xFFFFFFFF);
const _surfaceContainer = Color(0xFFECEEF0);
const _surfaceContainerLow = Color(0xFFF2F4F6);
const _surfaceContainerHigh = Color(0xFFE6E8EA);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _tertiary = Color(0xFF006B5E);
const _tertiaryContainer = Color(0xFF4AA898);
const _error = Color(0xFFBA1A1A);
const _errorContainer = Color(0xFFFFDAD6);
const _secondaryFixed = Color(0xFFBBC8D0);
const _secondaryContainer = Color(0xFFD7E4EC);

// ─── Load data model ──────────────────────────────────────────────────────────

class LoadItem {
  final String id;
  final String? pickupLocation;
  final String? unloadLocation;
  final String? materialType;
  final String? entryDate;
  final int truckCount;
  final String status;
  final String createdAt;

  const LoadItem({
    required this.id,
    this.pickupLocation,
    this.unloadLocation,
    this.materialType,
    this.entryDate,
    required this.truckCount,
    required this.status,
    required this.createdAt,
  });

  factory LoadItem.fromJson(Map<String, dynamic> json) => LoadItem(
        id: json['id'] as String,
        pickupLocation: json['pickup_location'] as String?,
        unloadLocation: json['unload_location'] as String?,
        materialType: json['material_type'] as String?,
        entryDate: json['entry_date'] as String?,
        truckCount: json['truck_count'] as int? ?? 1,
        status: json['status'] as String? ?? 'pending',
        createdAt: json['created_at'] as String? ?? '',
      );

  String get displayId {
    final clean = id.replaceAll('-', '');
    final short = clean.length >= 8
        ? clean.substring(0, 8).toUpperCase()
        : clean.toUpperCase();
    return '#L-$short';
  }

  String get routeLabel {
    final from =
        (pickupLocation?.isNotEmpty == true) ? pickupLocation! : 'Origin';
    final to =
        (unloadLocation?.isNotEmpty == true) ? unloadLocation! : 'Destination';
    return '$from → $to';
  }

  String get name =>
      (materialType?.isNotEmpty == true) ? materialType! : 'Load Requirement';

  bool get isDelayed => status == 'delayed';
  bool get isCompleted => status == 'completed';
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final _loadsProvider = FutureProvider.autoDispose<List<LoadItem>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/api/loads');
  final data = response.data as Map<String, dynamic>;
  final list = data['loads'] as List? ?? [];
  return list
      .map((e) => LoadItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Main screen ──────────────────────────────────────────────────────────────

class LoadOwnerDashboardScreen extends ConsumerStatefulWidget {
  const LoadOwnerDashboardScreen({super.key});

  @override
  ConsumerState<LoadOwnerDashboardScreen> createState() =>
      _LoadOwnerDashboardScreenState();
}

class _LoadOwnerDashboardScreenState
    extends ConsumerState<LoadOwnerDashboardScreen> {
  int _navIndex = 0;
  late final List<Widget> _pages;
  Timer? _pollTimer;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _goToLoads() => setState(() => _navIndex = 1);

  void _setNavIndex(int i) {
    if (i == 0 && _navIndex != 0) {
      // Refresh loads whenever returning to dashboard tab
      ref.invalidate(_loadsProvider);
    }
    setState(() => _navIndex = i);
  }

  Future<void> _openUpload() async {
    setState(() => _navIndex = 4);
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      _DashboardTab(onViewAllLoads: _goToLoads),
      _LoadsTab(onCreateLoad: _openUpload),
      const _TrackingTab(),
      const _DocsTab(),
      UploadLoadRequirementScreen(
        embedded: true,
        onDone: () {
          ref.invalidate(_loadsProvider);
          setState(() => _navIndex = 1);
        },
      ),
    ];
    Future.microtask(
        () => ref.read(tripProvider.notifier).loadTrips(statusFilter: 'ongoing'));
    // Real-time: silent background refresh every 30 s (no loading shimmer)
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing');
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    // Show a toast banner when a real-time notification arrives
    ref.listen<NotificationsState>(notificationsProvider, (prev, next) {
      if (prev == null) return;
      if (next.items.length > prev.items.length) {
        final newest = next.items.first;
        if (!newest.isRead) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(newest.title,
                          style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(newest.body,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: _primary,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _background,
      drawer: _AppDrawer(
        user: user,
        role: 'Load Owner',
        navIndex: _navIndex,
        onNavTap: (i) {
          _scaffoldKey.currentState?.closeDrawer();
          _setNavIndex(i);
        },
        onProfileTap: () {
          _scaffoldKey.currentState?.closeDrawer();
          _showProfileSheet(context);
        },
      ),
      body: Column(
        children: [
          _TopBar(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
          Expanded(
            child: IndexedStack(index: _navIndex, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        // Treat upload tab (4) as LOADS (1) being active in the nav bar
        selectedIndex: _navIndex == 4 ? 1 : _navIndex,
        onTap: (i) {
          if (i == 4) {
            _showProfileSheet(context);
          } else {
            _setNavIndex(i);
          }
        },
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: _primary),
              title: const Text('Settings',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                context.push('/load-owner/settings');
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: _primary),
              title: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : 'JD';
}

// ─── Top App Bar ──────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final VoidCallback onMenuTap;
  const _TopBar({required this.onMenuTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider.select((s) => s.unreadCount));

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
            const Spacer(),
            GestureDetector(
              onTap: () => _showNotificationsSheet(context, ref),
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
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
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

  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
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
  ConsumerState<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<_NotificationsSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(notificationsProvider.notifier).markAllRead());
  }

  Future<void> _confirmClearAll(BuildContext ctx, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear all notifications?',
            style: GoogleFonts.manrope(
                fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('This will permanently delete all notifications.',
            style: GoogleFonts.inter(fontSize: 13,
                color: const Color(0xFF546067))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(_).pop(false),
            child: Text('Cancel',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF546067))),
          ),
          TextButton(
            onPressed: () => Navigator.of(_).pop(true),
            child: Text('Clear All',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFBA1A1A))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(notificationsProvider.notifier).clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final items = state.items;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEEF0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                children: [
                  Text('Notifications',
                      style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF191C1E))),
                  const Spacer(),
                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _primary)),
                    ),
                  if (items.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClearAll(context, ref),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFBA1A1A),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Clear All',
                          style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFBA1A1A))),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFECEEF0)),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_none_rounded,
                              size: 48, color: Color(0xFF546067)),
                          const SizedBox(height: 12),
                          Text('No notifications yet',
                              style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF546067))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _NotifTile(
                        notif: items[i],
                        onDismiss: () => ref
                            .read(notificationsProvider.notifier)
                            .deleteOne(items[i].id),
                      ),
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
  final VoidCallback? onDismiss;
  const _NotifTile({required this.notif, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFBA1A1A), size: 22),
      ),
      onDismissed: (_) => onDismiss?.call(),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notif.isRead ? Colors.white : _primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notif.isRead
              ? const Color(0xFFECEEF0)
              : _primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: _primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.title,
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF191C1E))),
                const SizedBox(height: 4),
                Text(notif.body,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF546067))),
                if (notif.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notif.createdAt!),
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF546067)),
                  ),
                ],
              ],
            ),
          ),
          // Trailing column: unread dot + delete icon
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!notif.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: const BoxDecoration(
                      color: _primary, shape: BoxShape.circle),
                ),
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ), // end inner Container
    ); // end Dismissible
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

// ─── App Drawer ───────────────────────────────────────────────────────────────

class _AppDrawer extends ConsumerWidget {
  final dynamic user;
  final String role;
  final int navIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback? onProfileTap;

  const _AppDrawer({
    required this.user,
    required this.role,
    required this.navIndex,
    required this.onNavTap,
    this.onProfileTap,
  });

  static const _navItems = [
    (Icons.dashboard_rounded,      'Dashboard',  0),
    (Icons.inventory_2_outlined,   'My Loads',   1),
    (Icons.local_shipping_rounded, 'Tracking',   2),
    (Icons.description_outlined,   'Documents',  3),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name     = user?.fullName ?? 'Load Owner';
    final company  = user?.companyName ?? '';
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
                    color: _primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _initials(name),
                      style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                if (username.isNotEmpty)
                  Text('@$username',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white60)),
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
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    if (company.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(company,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.white54),
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
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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
                _DrawerNavTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isActive: false,
                  onTap: () => onProfileTap?.call(),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFECEEF0)),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text('MORE',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.white)),
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
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight:
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
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _onSurface)),
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

  static const _items = [
    (Icons.dashboard_rounded, 'DASHBOARD'),
    (Icons.local_shipping_rounded, 'LOADS'),
    (Icons.explore_outlined, 'TRACKING'),
    (Icons.description_outlined, 'DOCS'),
    (Icons.person_outline, 'PROFILE'),
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
                color: Colors.white.withValues(alpha: 0.6),
                width: 0.5,
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final (icon, label) = _items[i];
              final active = i == selectedIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: active
                      ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                      : const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: active ? _primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          color: active ? Colors.white : _secondary, size: 22),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: active ? Colors.white : _secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
  final VoidCallback onViewAllLoads;
  const _DashboardTab({required this.onViewAllLoads});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadsAsync = ref.watch(_loadsProvider);
    final tripState = ref.watch(tripProvider);
    final ongoingTrips = tripState.ongoingTrips;

    return loadsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _primary)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _error, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Failed to load data',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _onSurface),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(_loadsProvider),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary, foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (loads) {
        final total = loads.length;
        final inTransit =
            loads.where((l) => l.status == 'in_transit').length;
        final delayed = loads.where((l) => l.isDelayed).length;
        final completed = loads.where((l) => l.isCompleted).length;
        final topLoad = loads.isNotEmpty ? loads.first : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KpiGrid(
                  total: total,
                  inTransit: inTransit,
                  delayed: delayed,
                  completed: completed),
              const SizedBox(height: 24),
              // ── Shipment Status — with live trip cards ────────────────
              _ShipmentStatusWithTrips(
                loads: loads,
                trips: ongoingTrips,
                isLive: !tripState.isLoading,
                onViewAllLoads: onViewAllLoads,
              ),
              const SizedBox(height: 24),

              if (topLoad != null) _ActiveLoadDetail(load: topLoad),
              if (topLoad == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.local_shipping_outlined,
                            color: _secondary, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No loads posted yet',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _secondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Post your first load requirement\nto see activity here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: _secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const _WorkerRequestsSection(),
            ],
          ),
        );
      },
    );
  }
}

// ─── KPI Grid ─────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final int total;
  final int inTransit;
  final int delayed;
  final int completed;

  const _KpiGrid({
    required this.total,
    required this.inTransit,
    required this.delayed,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: [
        _KpiCard(label: 'TOTAL ACTIVE', value: '$total', accent: _primary),
        _KpiCard(label: 'IN TRANSIT', value: '$inTransit', accent: _tertiary),
        _KpiCard(
            label: 'DELAYED',
            value: '$delayed',
            accent: _error,
            showWarning: delayed > 0),
        _KpiCard(
            label: 'COMPLETED', value: '$completed', accent: _secondaryFixed),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final bool showWarning;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.accent,
    this.showWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: _inter(
              size: 9,
              weight: FontWeight.w700,
              color: _secondary,
            ).copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                value,
                style: _manrope(
                  size: 32,
                  weight: FontWeight.w800,
                  color: _onSurface,
                ).copyWith(height: 1.0),
              ),
              if (showWarning) ...[
                const SizedBox(width: 6),
                const Icon(Icons.warning_rounded, color: _error, size: 18),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shipment Status with live trip cards ────────────────────────────────────

class _ShipmentStatusWithTrips extends StatelessWidget {
  final List<LoadItem> loads;
  final List<dynamic> trips;  // List<TripModel>
  final bool isLive;
  final VoidCallback onViewAllLoads;

  const _ShipmentStatusWithTrips({
    required this.loads,
    required this.trips,
    required this.isLive,
    required this.onViewAllLoads,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shipment Status',
                style: _manrope(size: 17, weight: FontWeight.w800)),
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
        ),
        const SizedBox(height: 12),

        // ── Trip cards ───────────────────────────────────────────────────
        if (trips.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: _surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route_rounded,
                      color: _secondary, size: 40),
                  const SizedBox(height: 8),
                  Text('No active trips',
                      style: _inter(
                          size: 14,
                          weight: FontWeight.w600,
                          color: _secondary)),
                  const SizedBox(height: 4),
                  Text('Assigned trips will appear here',
                      style: _inter(size: 12)),
                ],
              ),
            ),
          )
        else
          ...trips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OngoingTripCard(trip: t, readOnly: true),
            ),
          ),

        // ── Posted loads (compact horizontal scroll below trips) ─────────
        if (loads.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Posted Loads',
                  style: _manrope(size: 14, weight: FontWeight.w700,
                      color: _secondary)),
              TextButton(
                onPressed: onViewAllLoads,
                style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    padding: EdgeInsets.zero),
                child: const Text('View All',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: loads.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _ShipmentCard(load: loads[i]),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Shipment Status Section (kept for reference / other uses) ───────────────

class _ShipmentSection extends StatelessWidget {
  final List<LoadItem> loads;
  const _ShipmentSection({required this.loads});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shipment Status',
              style: _manrope(size: 17, weight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: _primary,
                padding: EdgeInsets.zero,
              ),
              child: const Text('View All',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (loads.isEmpty)
          Container(
            height: 176,
            decoration: BoxDecoration(
              color: _surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_shipping_outlined,
                      color: _secondary, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'No active shipments',
                    style: TextStyle(
                        color: _secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: loads.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _ShipmentCard(load: loads[i]),
            ),
          ),
      ],
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final LoadItem load;
  const _ShipmentCard({required this.load});

  String _statusLabel(String s) {
    switch (s) {
      case 'in_transit':
        return 'IN TRANSIT';
      case 'delayed':
        return 'DELAYED';
      case 'completed':
        return 'COMPLETED';
      default:
        return 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBg = load.isDelayed
        ? _errorContainer
        : _tertiaryContainer.withValues(alpha: 0.12);
    final statusFg = load.isDelayed ? _error : _tertiary;

    return Container(
      width: 270,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    load.displayId,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _secondary,
                    ),
                  ),
                  Text(
                    load.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(load.status),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: _secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  load.routeLabel,
                  style: const TextStyle(fontSize: 12, color: _secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 14, color: _secondary),
              const SizedBox(width: 6),
              Text(
                load.entryDate ?? 'Date TBD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      load.isDelayed ? FontWeight.w700 : FontWeight.w400,
                  color: load.isDelayed ? _error : _secondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Divider(height: 1, color: _surfaceContainer),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surfaceContainerHigh,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.local_shipping, size: 12, color: _secondary),
                ),
              ),
              Icon(
                load.isDelayed
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: load.isDelayed ? _error : _tertiary,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Active Load Detail ───────────────────────────────────────────────────────

class _ActiveLoadDetail extends StatelessWidget {
  final LoadItem load;
  const _ActiveLoadDetail({required this.load});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics_outlined,
                  color: _primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Active Load Detail: ${load.displayId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Live map
        _MapPlaceholder(),
        const SizedBox(height: 14),

        // Shipment timeline
        _TimelineCard(),
        const SizedBox(height: 12),

        // Load visibility + truck driver
        Row(
          children: [
            Expanded(child: _LoadVisibilityCard(load: load)),
            const SizedBox(width: 12),
            const Expanded(child: _TruckDriverCard()),
          ],
        ),
        const SizedBox(height: 12),

        // Schedule performance
        _ScheduleCard(),
        const SizedBox(height: 12),

        // Documents
        _DocumentsSection(),
        const SizedBox(height: 12),

        // Action buttons
        _ActionButtons(),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Map Placeholder ──────────────────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
          ),
        ),
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _MapGridPainter(),
            ),
            // GPS signal badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE GPS SIGNAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2E44),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Fullscreen button
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.70),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fullscreen_rounded,
                    size: 18, color: Color(0xFF1A2E44)),
              ),
            ),
            // Position label
            const Positioned(
              bottom: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT POSITION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'NH-44 Highway, Maharashtra',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Route line
    final routePaint = Paint()
      ..color = _primary.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.7)
      ..cubicTo(
        size.width * 0.3, size.height * 0.3,
        size.width * 0.6, size.height * 0.7,
        size.width * 0.85, size.height * 0.35,
      );
    canvas.drawPath(path, routePaint);
    // Truck icon dot
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.54),
      6,
      Paint()..color = _primary,
    );
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.54),
      10,
      Paint()
        ..color = _primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Timeline Card ────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = ['CREATED', 'ASSIGNED', 'DISPATCHED', 'IN TRANSIT', 'REACHED'];
    // 0-2 done, 3 active, 4 pending
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SHIPMENT LIFECYCLE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: _secondary,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background progress track
                  Positioned(
                    top: 11,
                    left: 12,
                    right: 12,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _secondaryFixed.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Orange fill — 60% (through "In Transit")
                  Positioned(
                    top: 11,
                    left: 12,
                    child: Container(
                      height: 4,
                      width: (w - 24) * 0.60,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Nodes row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(steps.length, (i) {
                      final done = i < 3;
                      final active = i == 3;
                      final pending = i == 4;
                      return Opacity(
                        opacity: pending ? 0.35 : 1.0,
                        child: Column(
                          children: [
                            Transform.scale(
                              scale: active ? 1.22 : 1.0,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (done || active) ? _primary : _secondary,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color: _primary.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  active
                                      ? Icons.local_shipping_rounded
                                      : done
                                          ? Icons.check_rounded
                                          : null,
                                  size: active ? 12 : 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              steps[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: active ? _primary : _onSurface,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Load Visibility Card ─────────────────────────────────────────────────────

class _LoadVisibilityCard extends StatelessWidget {
  final LoadItem load;
  const _LoadVisibilityCard({required this.load});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.inventory_2_outlined, size: 18, color: _secondary),
              SizedBox(width: 8),
              Text(
                'Load Visibility',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'MATERIAL',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: _secondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            (load.materialType?.isNotEmpty == true)
                ? load.materialType!
                : 'Not specified',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _onSurface,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          const Text(
            'TRUCKS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: _secondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${load.truckCount} requested',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Truck & Driver Card ──────────────────────────────────────────────────────

class _TruckDriverCard extends StatelessWidget {
  const _TruckDriverCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, size: 18, color: _secondary),
              SizedBox(width: 8),
              Text(
                'Truck & Driver',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surfaceContainer,
                ),
                child: const Icon(Icons.person_outline,
                    size: 20, color: _secondary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _onSurface,
                      ),
                    ),
                    Text(
                      'RJ14-GB-9821',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _secondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _tertiaryContainer.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_rounded,
                color: _tertiary, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Performance Card ────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Schedule Performance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CRITICAL DELAY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Table header
          const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('EVENT',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _secondary,
                        letterSpacing: 0.8)),
              ),
              Expanded(
                flex: 3,
                child: Text('PLANNED',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _secondary,
                        letterSpacing: 0.8)),
              ),
              Expanded(
                flex: 3,
                child: Text('ACTUAL',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _secondary,
                        letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _scheduleRow('Dispatch', '08:00 AM', '07:55 AM', false),
          const Divider(height: 16, color: _surfaceContainerLow),
          _scheduleRow('Mid-Point', '12:00 PM', '02:30 PM', true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _errorContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: _error),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reason: Heavy Traffic & Highway Construction at NH-44 Toll.',
                    style: TextStyle(
                      fontSize: 11,
                      color: _error,
                      height: 1.4,
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

  Widget _scheduleRow(
      String event, String planned, String actual, bool delayed) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(event,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _onSurface)),
        ),
        Expanded(
          flex: 3,
          child: Text(planned,
              style:
                  const TextStyle(fontSize: 12, color: _secondary)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            actual,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: delayed ? _error : _tertiary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Documents Section ────────────────────────────────────────────────────────

class _DocumentsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Required Documents',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _DocChip(
                    icon: Icons.description_outlined,
                    label: 'POD',
                    status: 'Verified',
                    statusColor: _tertiary),
                const SizedBox(width: 10),
                _DocChip(
                    icon: Icons.receipt_long_outlined,
                    label: 'E-Way Bill',
                    status: 'Active',
                    statusColor: _tertiary),
                const SizedBox(width: 10),
                _DocChip(
                    icon: Icons.photo_camera_outlined,
                    label: 'Load Photo',
                    status: '2 Files',
                    statusColor: _secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final Color statusColor;

  const _DocChip({
    required this.icon,
    required this.label,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _surfaceContainerHigh),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _primary, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            status,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _actionBtn('Escalate', Icons.sos_rounded, _primary, Colors.white, filled: true)),
            const SizedBox(width: 10),
            Expanded(
              child: _actionBtn('Modify', Icons.edit_outlined, _secondaryContainer, _onSurface, filled: true),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.mail_outline_rounded, size: 16),
            label: const Text('Contact Dispatch Office'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color bg,
    Color fg, {
    required bool filled,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: filled ? 3 : 0,
          shadowColor: bg.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Placeholder tabs ─────────────────────────────────────────────────────────

class _LoadsTab extends ConsumerWidget {
  final Future<void> Function() onCreateLoad;
  const _LoadsTab({required this.onCreateLoad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadsAsync = ref.watch(_loadsProvider);

    return loadsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _primary)),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _error, size: 48),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreateLoad,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Post New Load'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      data: (loads) {
        if (loads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_rounded,
                      size: 48, color: _primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Manage Loads',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _onSurface),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Post a new load requirement\nor view existing ones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: _secondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onCreateLoad,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Post New Load'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCreateLoad,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Post New Load'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: loads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _LoadListTile(load: loads[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoadListTile extends StatelessWidget {
  final LoadItem load;
  const _LoadListTile({required this.load});

  Color _statusColor(String status) {
    switch (status) {
      case 'in_transit':
        return _tertiary;
      case 'delayed':
        return _error;
      case 'completed':
        return _secondary;
      default:
        return _primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(load.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: _primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      load.displayId,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _onSurface),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        load.status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  load.name,
                  style: const TextStyle(fontSize: 12, color: _secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  load.routeLabel,
                  style: const TextStyle(fontSize: 11, color: _secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${load.truckCount} truck${load.truckCount != 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primary),
              ),
              if (load.entryDate != null)
                Text(
                  load.entryDate!,
                  style: const TextStyle(fontSize: 10, color: _secondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingTab extends ConsumerWidget {
  const _TrackingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(tripProvider);
    final activeTrips = tripState.trips
        .where((t) => t.status == 'ongoing' || t.status == 'matched' || t.status == 'pending')
        .toList();

    if (tripState.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: _primary));
    }

    if (activeTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping_outlined, size: 64, color: _surfaceContainer),
            const SizedBox(height: 16),
            Text('No Active Trips',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _onSurface)),
            const SizedBox(height: 8),
            Text('Active trips will appear here once a logistic partner\nfulfills your load requirement.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _secondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: activeTrips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final trip = activeTrips[i];
        return _TrackingCard(trip: trip);
      },
    );
  }
}

class _TrackingCard extends ConsumerStatefulWidget {
  final TripModel trip;
  const _TrackingCard({required this.trip});

  @override
  ConsumerState<_TrackingCard> createState() => _TrackingCardState();
}

class _TrackingCardState extends ConsumerState<_TrackingCard> {
  bool _cancelling = false;

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Trip',
            style: GoogleFonts.manrope(
                fontSize: 16, fontWeight: FontWeight.w700, color: _onSurface)),
        content: Text(
          'Are you sure you want to cancel trip ${widget.trip.tripNumber}? This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: _secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep Trip',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600, color: _secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cancel Trip',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700, color: _error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/cancel');
      if (!mounted) return;
      ref.read(tripProvider.notifier).silentRefresh(statusFilter: 'ongoing');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip ${widget.trip.tripNumber} cancelled.',
              style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: _onSurface,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final msg =
          e.response?.data?['detail'] as String? ?? 'Failed to cancel trip.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: _error),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Container(
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceContainer),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(trip.tripNumber,
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _onSurface)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: _primary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text('IN TRANSIT',
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked_rounded,
                        size: 14, color: _tertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(trip.origin,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                      width: 2, height: 12, color: _surfaceContainer),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: _secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(trip.destination,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _secondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (trip.loadItem.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(trip.loadItem,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _secondary)),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: _surfaceContainer),
          // Three action buttons side by side
          IntrinsicHeight(
            child: Row(
              children: [
                // View Details
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShipmentDetailsScreen(trip: trip),
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: _secondary),
                          const SizedBox(width: 4),
                          Text('Details',
                              style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _secondary)),
                        ],
                      ),
                    ),
                  ),
                ),
                VerticalDivider(
                    width: 1, thickness: 1, color: _surfaceContainer),
                // Cancel Trip
                Expanded(
                  child: InkWell(
                    onTap: _cancelling ? null : _confirmCancel,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      child: _cancelling
                          ? const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _error),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cancel_outlined,
                                    size: 14, color: _error),
                                const SizedBox(width: 4),
                                Text('Cancel',
                                    style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _error)),
                              ],
                            ),
                    ),
                  ),
                ),
                VerticalDivider(
                    width: 1, thickness: 1, color: _surfaceContainer),
                // Track Truck
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TruckTrackingScreen(trip: trip),
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_shipping_rounded,
                              size: 14, color: _primary),
                          const SizedBox(width: 4),
                          Text('Track',
                              style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _primary)),
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

class _DocsTab extends StatelessWidget {
  const _DocsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 64, color: _primary),
          const SizedBox(height: 16),
          const Text(
            'Documents',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _onSurface),
          ),
          const SizedBox(height: 8),
          const Text(
            'Document management coming soon.',
            style: TextStyle(fontSize: 14, color: _secondary),
          ),
        ],
      ),
    );
  }
}

// ─── Worker Requests Section ──────────────────────────────────────────────────

class _WorkerRequestsSection extends ConsumerStatefulWidget {
  const _WorkerRequestsSection();

  @override
  ConsumerState<_WorkerRequestsSection> createState() =>
      _WorkerRequestsSectionState();
}

class _WorkerRequestsSectionState
    extends ConsumerState<_WorkerRequestsSection> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/organization/worker-requests');
      final data = response.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(data['requests'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(String userOrgId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/organization/worker-requests/$userOrgId/accept');
      _fetchRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Worker accepted successfully'),
          backgroundColor: Color(0xFF006B5E),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _error,
        ));
      }
    }
  }

  Future<void> _reject(String userOrgId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/organization/worker-requests/$userOrgId/reject');
      _fetchRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Request rejected'),
          backgroundColor: Color(0xFF546067),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _requests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Worker Requests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_requests.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._requests.map((req) {
          final userOrgId = req['user_organization_id'] as String;
          final name = req['full_name'] as String? ?? 'Unknown';
          final username = req['username'] as String? ?? '';
          final phone = req['phone'] as String? ?? '';
          final requestedRole =
              req['requested_role'] as Map<String, dynamic>?;
          final roleName = requestedRole?['name'] as String? ?? 'Worker';
          final initials = name
              .trim()
              .split(' ')
              .take(2)
              .map((p) => p[0])
              .join()
              .toUpperCase();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _primary.withOpacity(0.3), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _onSurface)),
                      Text('@$username',
                          style: const TextStyle(
                              fontSize: 12, color: _secondary)),
                      if (phone.isNotEmpty)
                        Text(phone,
                            style: const TextStyle(
                                fontSize: 12, color: _secondary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          roleName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    SizedBox(
                      width: 72,
                      child: ElevatedButton(
                        onPressed: () => _accept(userOrgId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006B5E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Accept',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 72,
                      child: OutlinedButton(
                        onPressed: () => _reject(userOrgId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _error,
                          side: const BorderSide(color: _error, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Reject',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
