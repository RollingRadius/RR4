import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/data/models/load_requirement_model.dart';
import 'package:fleet_management/data/models/notification_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/notification_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────

const _orange   = Color(0xFFFF6B00);
const _orangeL  = Color(0xFFFFF3EB);
const _green    = Color(0xFF2E7D32);
const _greenL   = Color(0xFFE8F5E9);
const _amber    = Color(0xFFFF8F00);
const _amberL   = Color(0xFFFFF8E1);
const _grey1    = Color(0xFF1A1A2E);   // dark heading
const _grey2    = Color(0xFF4A5568);   // body text
const _grey3    = Color(0xFF9CA3AF);   // placeholder
const _bg       = Color(0xFFF5F6FA);
const _cardBg   = Colors.white;
const _divider  = Color(0xFFE8ECF0);

TextStyle _t(double size, FontWeight w, Color c) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: w, color: c);

// ─── Provider ─────────────────────────────────────────────────────────────────

final transporterTripsProvider =
    StateNotifierProvider.autoDispose<_TripsNotifier, _TripsState>(
  (ref) => _TripsNotifier(ref.watch(dioProvider)),
);

class _TripsState {
  final List<TripModel> trips;
  final bool loading;
  final String? error;
  const _TripsState({this.trips = const [], this.loading = false, this.error});

  _TripsState copyWith({List<TripModel>? trips, bool? loading, String? error}) =>
      _TripsState(
        trips:   trips   ?? this.trips,
        loading: loading ?? this.loading,
        error:   error,
      );

  // Trips without a slip yet — show in Dashboard fleet status
  List<TripModel> get active => trips.where((t) => t.s2LoadingSlipUrl == null).toList();
  // Trips with slip uploaded — show in Records
  List<TripModel> get done   => trips.where((t) => t.s2LoadingSlipUrl != null).toList();

  int get pendingCount => trips.where((t) => t.isAtLoadingSlipStage).length;
}

class _TripsNotifier extends StateNotifier<_TripsState> {
  final Dio _dio;
  _TripsNotifier(this._dio) : super(const _TripsState()) { _load(); }

  Future<void> _load() async {
    state = state.copyWith(loading: true);
    try {
      final resp = await _dio.get('/api/trips/transporter/assigned');
      final list = ((resp.data['trips'] as List?) ?? [])
          .map((j) => TripModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(trips: list, loading: false);
    } catch (e) {
      final msg = e is DioException
          ? (e.response?.data?['detail'] as String? ?? 'Failed to load trips')
          : e.toString();
      state = _TripsState(error: msg);
    }
  }

  Future<void> refresh() => _load();

  void patch(TripModel updated) => state = state.copyWith(
        trips: state.trips.map((t) => t.id == updated.id ? updated : t).toList(),
      );
}

// ─── Loads Provider ───────────────────────────────────────────────────────────

class _LoadsState {
  final List<LoadRequirementModel> loads;
  final bool loading;
  final String? error;
  const _LoadsState({this.loads = const [], this.loading = false, this.error});

  _LoadsState copyWith({List<LoadRequirementModel>? loads, bool? loading, String? error}) =>
      _LoadsState(loads: loads ?? this.loads, loading: loading ?? this.loading, error: error);
}

class _LoadsNotifier extends StateNotifier<_LoadsState> {
  final Dio _dio;
  _LoadsNotifier(this._dio) : super(const _LoadsState()) { _fetch(); }

  Future<void> _fetch({String? pickup, String? drop, String? material}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (pickup != null && pickup.isNotEmpty) params['pickup'] = pickup;
      if (drop != null && drop.isNotEmpty) params['drop'] = drop;
      if (material != null && material.isNotEmpty) params['material'] = material;
      final resp = await _dio.get('/api/loads/transporter/available', queryParameters: params);
      final list = ((resp.data['loads'] as List?) ?? [])
          .map((j) => LoadRequirementModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(loads: list, loading: false);
    } catch (e) {
      final msg = e is DioException
          ? (e.response?.data?['detail'] as String? ?? 'Failed to load')
          : e.toString();
      state = state.copyWith(error: msg, loading: false);
    }
  }

  Future<void> refresh({String? pickup, String? drop, String? material}) =>
      _fetch(pickup: pickup, drop: drop, material: material);
}

final _transporterLoadsProvider =
    StateNotifierProvider.autoDispose<_LoadsNotifier, _LoadsState>(
  (ref) => _LoadsNotifier(ref.watch(dioProvider)),
);

// ─── Root widget ──────────────────────────────────────────────────────────────

class TransporterDashboard extends ConsumerStatefulWidget {
  const TransporterDashboard({super.key});

  @override
  ConsumerState<TransporterDashboard> createState() => _TransporterDashboardState();
}

class _TransporterDashboardState extends ConsumerState<TransporterDashboard> {
  int _tab = 0;
  Timer? _pollTimer;
  StreamSubscription<RemoteMessage>? _fcmSub;

  @override
  void initState() {
    super.initState();
    // Poll every 30s as a fallback (catches cancellations when app is in background)
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(transporterTripsProvider.notifier).refresh();
    });
    // Immediate refresh when a trip_cancelled FCM message arrives in foreground
    _fcmSub = FirebaseMessaging.onMessage.listen((message) {
      if (message.data['type'] == 'trip_cancelled') {
        ref.read(transporterTripsProvider.notifier).refresh();
        ref.read(notificationsProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _fcmSub?.cancel();
    super.dispose();
  }

  void _onTabTap(int i) {
    // Refresh loads silently when switching to the Loads tab
    if (i == 2 && _tab != 2) {
      ref.read(_transporterLoadsProvider.notifier).refresh();
    }
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transporterTripsProvider);

    return Scaffold(
      backgroundColor: _bg,
      // No drawer — transporter has no sidebar
      drawer: null,
      body: IndexedStack(
        index: _tab,
        children: [
          _DashboardTab(state: state),
          _RecordsTab(state: state),
          const _LoadsTab(),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: _onTabTap,
        pendingCount: state.pendingCount,
      ),
    );
  }
}

// ─── Bottom navigation ────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  final int pendingCount;
  const _BottomNav({required this.current, required this.onTap, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(index: 0, current: current, icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded, label: 'Dashboard', onTap: onTap),
              _NavItem(index: 1, current: current, icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded, label: 'Records', onTap: onTap),
              _NavItem(index: 2, current: current, icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping_rounded, label: 'Loads', onTap: onTap),
              _NavItem(index: 3, current: current, icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded, label: 'Profile', onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index, current;
  final IconData icon, activeIcon;
  final String label;
  final ValueChanged<int> onTap;
  const _NavItem({
    required this.index, required this.current, required this.icon,
    required this.activeIcon, required this.label, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? activeIcon : icon,
                key: ValueKey(selected),
                color: selected ? _orange : _grey3,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: _t(10, selected ? FontWeight.w700 : FontWeight.w500,
                  selected ? _orange : _grey3),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  final _TripsState state;
  const _DashboardTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return SafeArea(
      child: RefreshIndicator(
        color: _orange,
        onRefresh: () => ref.read(transporterTripsProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            // ── Top bar ──────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _TopBar(user: user)),

            // ── Summary chips ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: [
                    _SummaryChip(
                      icon: Icons.local_shipping_rounded,
                      label: 'Assigned',
                      count: state.trips.length,
                      color: _orange,
                    ),
                    const SizedBox(width: 10),
                    _SummaryChip(
                      icon: Icons.upload_file_rounded,
                      label: 'Pending Upload',
                      count: state.pendingCount,
                      color: _amber,
                    ),
                    const SizedBox(width: 10),
                    _SummaryChip(
                      icon: Icons.check_circle_rounded,
                      label: 'Completed',
                      count: state.done.length,
                      color: _green,
                    ),
                  ],
                ),
              ),
            ),

            // ── States: loading / error / empty / list ────────────────────────
            if (state.loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _orange)),
              )

            else if (state.error != null)
              SliverFillRemaining(
                child: _ErrorState(
                  message: state.error!,
                  onRetry: () => ref.read(transporterTripsProvider.notifier).refresh(),
                ),
              )

            else if (state.active.isEmpty)
              SliverFillRemaining(child: _EmptyState())

            else ...[
              // ── Fleet Status header ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 3, height: 18,
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Fleet Status', style: _t(15, FontWeight.w700, _grey1)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _orangeL,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${state.active.length} trip${state.active.length == 1 ? '' : 's'}',
                          style: _t(10, FontWeight.w700, _orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Trip cards ────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _AssignedTripCard(trip: state.active[i]),
                    ),
                    childCount: state.active.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final dynamic user;
  const _TopBar({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = ((user?.fullName ?? 'T') as String)
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final unread = ref.watch(notificationsProvider).items
        .where((n) => !n.isRead && n.type == 'trip_cancelled')
        .length;

    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _orangeL,
                  shape: BoxShape.circle,
                  border: Border.all(color: _orange.withOpacity(0.3), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(initials, style: _t(15, FontWeight.w800, _orange)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello,', style: _t(12, FontWeight.w400, _grey3)),
                    Text(
                      user?.fullName ?? 'Transporter',
                      style: _t(16, FontWeight.w700, _grey1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Bell icon
              GestureDetector(
                onTap: () => _showNotificationsSheet(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined, color: _grey2, size: 26),
                    if (unread > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: _orange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
              const SizedBox(width: 12),
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _orangeL,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping_rounded, size: 12, color: _orange),
                    const SizedBox(width: 4),
                    Text('Transporter', style: _t(10, FontWeight.w700, _orange)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Container(height: 1, color: _divider),
        ],
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

// ─── Notifications sheet ──────────────────────────────────────────────────────

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider).items
        .where((n) => n.type == 'trip_cancelled')
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Text('Notifications', style: _t(17, FontWeight.w700, _grey1)),
                  const Spacer(),
                  if (items.any((n) => !n.isRead))
                    GestureDetector(
                      onTap: () => ref.read(notificationsProvider.notifier).markAllRead(),
                      child: Text('Mark all read',
                          style: _t(13, FontWeight.w600, _orange)),
                    ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () {
                        ref.read(notificationsProvider.notifier).clearAll();
                        Navigator.pop(context);
                      },
                      child: Text('Clear all',
                          style: _t(13, FontWeight.w600, Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
            Container(height: 1, color: _divider),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 48, color: _grey3),
                          const SizedBox(height: 12),
                          Text('No notifications', style: _t(14, FontWeight.w500, _grey3)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, indent: 20, endIndent: 20, color: _divider),
                      itemBuilder: (ctx, i) {
                        final n = items[i];
                        return _NotifTile(
                          notif: n,
                          onDismiss: () =>
                              ref.read(notificationsProvider.notifier).deleteOne(n.id),
                          onTap: () {
                            ref.read(notificationsProvider.notifier).markRead(n.id);
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

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _NotifTile({required this.notif, required this.onTap, required this.onDismiss});

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
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFBA1A1A), size: 22),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notif.isRead ? Colors.transparent : _orange.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _orangeL,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, color: _orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif.title,
                        style: _t(14, notif.isRead ? FontWeight.w500 : FontWeight.w700, _grey1)),
                    const SizedBox(height: 4),
                    Text(notif.body,
                        style: _t(12, FontWeight.w400, _grey2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (notif.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(notif.createdAt!),
                        style: _t(11, FontWeight.w400, _grey3),
                      ),
                    ],

                  ],
                ),
              ),
              if (!notif.isRead)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

// ─── Summary chip ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _SummaryChip({required this.icon, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _divider),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text('$count', style: _t(18, FontWeight.w800, color)),
            Text(label, style: _t(9, FontWeight.w500, _grey3), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Assigned Trip Card ───────────────────────────────────────────────────────

class _AssignedTripCard extends ConsumerStatefulWidget {
  final TripModel trip;
  const _AssignedTripCard({required this.trip});

  @override
  ConsumerState<_AssignedTripCard> createState() => _AssignedTripCardState();
}

class _AssignedTripCardState extends ConsumerState<_AssignedTripCard> {
  bool _uploading = false;
  String? _err;
  final _picker = ImagePicker();

  TripModel get _trip => widget.trip;

  Future<void> _uploadSlip() async {
    // Pick from gallery or camera — show choice
    final source = await _showSourceDialog();
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() { _uploading = true; _err = null; });

    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(
        '/api/trips/${_trip.id}/transporter-loading-slip',
        data: FormData.fromMap({
          'slip': MultipartFile.fromBytes(bytes, filename: picked.name),
        }),
      );
      final updated = TripModel.fromJson(
        (resp.data as Map<String, dynamic>)['trip'] as Map<String, dynamic>,
      );
      if (mounted) {
        ref.read(transporterTripsProvider.notifier).patch(updated);
        setState(() => _uploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text('Loading slip uploaded for ${_trip.tripNumber}',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
              backgroundColor: _green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      final msg = e is DioException
          ? (e.response?.data?['detail'] as String? ?? 'Upload failed')
          : e.toString();
      if (mounted) setState(() { _uploading = false; _err = msg; });
    }
  }

  Future<ImageSource?> _showSourceDialog() => showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: _cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: _divider, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Text('Upload Loading Slip', style: _t(15, FontWeight.w700, _grey1)),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _orangeL, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_rounded, color: _orange),
                ),
                title: Text('Choose from Gallery', style: _t(14, FontWeight.w600, _grey1)),
                subtitle: Text('Select an existing photo', style: _t(12, FontWeight.w400, _grey3)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _amberL, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_rounded, color: _amber),
                ),
                title: Text('Take a Photo', style: _t(14, FontWeight.w600, _grey1)),
                subtitle: Text('Use camera to capture slip', style: _t(12, FontWeight.w400, _grey3)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final canUpload  = _trip.isAtLoadingSlipStage;
    final waitStage  = !canUpload && _trip.s2LoadingSlipUrl == null && (_trip.currentStage ?? 0) < 2;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canUpload ? _orange.withOpacity(0.4) : _divider,
          width: canUpload ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: canUpload
                ? _orange.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Card body ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: trip number + status badge
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TRIP NUMBER',
                              style: _t(9, FontWeight.w600, _grey3)
                                  .copyWith(letterSpacing: 0.8)),
                          const SizedBox(height: 2),
                          Text(_trip.tripNumber,
                              style: _t(16, FontWeight.w800, _orange)),
                        ],
                      ),
                    ),
                    _StatusBadge(trip: _trip),
                  ],
                ),

                const SizedBox(height: 14),
                Container(height: 1, color: _divider),
                const SizedBox(height: 14),

                // Row 2: Route
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: _orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_trip.origin,
                          style: _t(13, FontWeight.w600, _grey1),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 2, bottom: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 1, height: 18,
                        margin: const EdgeInsets.only(left: 6),
                        color: _divider,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.flag_rounded, size: 14, color: _grey3),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_trip.destination,
                          style: _t(13, FontWeight.w600, _grey1),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row 3: Cargo + LP
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 13, color: _grey3),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _trip.weight != null
                                  ? '${_trip.loadItem} · ${_trip.weight}'
                                  : _trip.loadItem,
                              style: _t(12, FontWeight.w500, _grey2),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_trip.lpOrgName != null) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.business_rounded, size: 13, color: _grey3),
                          const SizedBox(width: 4),
                          Text(
                            _trip.lpOrgName!,
                            style: _t(11, FontWeight.w500, _grey3),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                // ── Error message ────────────────────────────────────────────
                if (_err != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 14, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_err!, style: _t(11, FontWeight.w500, Colors.red))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Action row ────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: canUpload ? _orangeL : (waitStage ? _amberL : _greenL),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: canUpload
                // UPLOAD BUTTON
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _uploading ? null : _uploadSlip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _orange.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: _uploading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(
                        _uploading ? 'Uploading…' : 'Upload Loading Slip',
                        style: _t(14, FontWeight.w700, Colors.white),
                      ),
                    ),
                  )
                : waitStage
                    // WAITING FOR STAGE 2
                    ? Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded, size: 16, color: _amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Waiting for compliance clearance by LP',
                              style: _t(12, FontWeight.w600, _amber),
                            ),
                          ),
                        ],
                      )
                    // DONE (shouldn't reach here — done trips shown in Records only)
                    : Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 16, color: _green),
                          const SizedBox(width: 8),
                          Text('Loading slip uploaded', style: _t(12, FontWeight.w600, _green)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final TripModel trip;
  const _StatusBadge({required this.trip});

  @override
  Widget build(BuildContext context) {
    if (trip.s2LoadingSlipUrl != null) {
      return _Badge('SLIP DONE', _green, _greenL);
    }
    if (trip.isAtLoadingSlipStage) {
      return _Badge('UPLOAD NOW', _orange, _orangeL);
    }
    return _Badge('AWAITING', _amber, _amberL);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _Badge(this.label, this.fg, this.bg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withOpacity(0.3)),
        ),
        child: Text(label, style: _t(9, FontWeight.w700, fg).copyWith(letterSpacing: 0.5)),
      );
}

// ─── Records Tab ──────────────────────────────────────────────────────────────

class _RecordsTab extends ConsumerWidget {
  final _TripsState state;
  const _RecordsTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = state.done;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: _cardBg,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Records', style: _t(22, FontWeight.w800, _grey1)),
                      Text(
                        '${done.length} loading slip${done.length == 1 ? '' : 's'} uploaded',
                        style: _t(13, FontWeight.w400, _grey3),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.receipt_long_rounded, color: _orange.withOpacity(0.5), size: 28),
              ],
            ),
          ),
          Container(height: 1, color: _divider),
          const SizedBox(height: 4),

          // List
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator(color: _orange))
                : done.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 72, color: _divider),
                            const SizedBox(height: 16),
                            Text('No records yet', style: _t(16, FontWeight.w600, _grey3)),
                            const SizedBox(height: 6),
                            Text('Uploaded slips will appear here',
                                style: _t(13, FontWeight.w400, _grey3)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: _orange,
                        onRefresh: () => ref.read(transporterTripsProvider.notifier).refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          itemCount: done.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RecordCard(trip: done[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final TripModel trip;
  const _RecordCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip number + badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TRIP', style: _t(9, FontWeight.w600, _grey3).copyWith(letterSpacing: 0.8)),
                    Text(trip.tripNumber, style: _t(15, FontWeight.w800, _grey1)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _greenL,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: _green),
                    const SizedBox(width: 4),
                    Text('SLIP UPLOADED', style: _t(9, FontWeight.w700, _green).copyWith(letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _divider),
          const SizedBox(height: 12),

          // Route
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 13, color: _orange),
              const SizedBox(width: 6),
              Expanded(child: Text(trip.origin, style: _t(13, FontWeight.w600, _grey1),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
            child: Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _grey3),
          ),
          Row(
            children: [
              const Icon(Icons.flag_rounded, size: 13, color: _grey3),
              const SizedBox(width: 6),
              Expanded(child: Text(trip.destination, style: _t(13, FontWeight.w600, _grey1),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 10),

          // Cargo + LP
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 13, color: _grey3),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trip.weight != null ? '${trip.loadItem} · ${trip.weight}' : trip.loadItem,
                  style: _t(12, FontWeight.w500, _grey2),
                ),
              ),
              if (trip.lpOrgName != null) ...[
                const Icon(Icons.business_rounded, size: 12, color: _grey3),
                const SizedBox(width: 4),
                Text(trip.lpOrgName!, style: _t(11, FontWeight.w500, _grey3)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Loads Tab ────────────────────────────────────────────────────────────────

class _LoadsTab extends ConsumerStatefulWidget {
  const _LoadsTab();

  @override
  ConsumerState<_LoadsTab> createState() => _LoadsTabState();
}

class _LoadsTabState extends ConsumerState<_LoadsTab> {
  final _pickupCtrl = TextEditingController();
  final _dropCtrl   = TextEditingController();
  Timer? _debounce;

  bool get _hasFilters =>
      _pickupCtrl.text.trim().isNotEmpty || _dropCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _debounce?.cancel();
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(_transporterLoadsProvider.notifier).refresh(
            pickup: _pickupCtrl.text.trim().isNotEmpty ? _pickupCtrl.text.trim() : null,
            drop:   _dropCtrl.text.trim().isNotEmpty   ? _dropCtrl.text.trim()   : null,
          );
      setState(() {});
    });
  }

  void _clearFilters() {
    _pickupCtrl.clear();
    _dropCtrl.clear();
    _debounce?.cancel();
    ref.read(_transporterLoadsProvider.notifier).refresh();
    setState(() {});
  }

  Widget _filterField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: controller.text.trim().isNotEmpty ? _orange : _divider,
          width: controller.text.trim().isNotEmpty ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => _onFilterChanged(),
        style: _t(13, FontWeight.w500, _grey1),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _t(13, FontWeight.w400, _grey3),
          prefixIcon: Icon(icon, color: controller.text.trim().isNotEmpty ? _orange : _grey3, size: 18),
          suffixIcon: controller.text.trim().isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    _onFilterChanged();
                  },
                  child: const Icon(Icons.close_rounded, color: _grey3, size: 16),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_transporterLoadsProvider);
    final isFiltered = _hasFilters;

    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            color: _cardBg,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Available Loads', style: _t(22, FontWeight.w800, _grey1)),
                    const Spacer(),
                    if (isFiltered)
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _orangeL,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Clear filters', style: _t(11, FontWeight.w700, _orange)),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () => ref.read(_transporterLoadsProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh_rounded, color: _orange, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Pickup filter
                _filterField(
                  controller: _pickupCtrl,
                  hint: 'Filter by pickup location…',
                  icon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 8),
                // Drop filter
                _filterField(
                  controller: _dropCtrl,
                  hint: 'Filter by drop location…',
                  icon: Icons.flag_rounded,
                ),
                // Active filter summary
                if (isFiltered) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 13, color: _orange),
                      const SizedBox(width: 4),
                      Text(
                        '${state.loads.length} result${state.loads.length == 1 ? '' : 's'} found',
                        style: _t(11, FontWeight.w600, _orange),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 2))
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: _grey3, size: 40),
                            const SizedBox(height: 12),
                            Text(state.error!, style: _t(13, FontWeight.w500, _grey3),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => ref.read(_transporterLoadsProvider.notifier).refresh(),
                              child: Text('Retry', style: _t(13, FontWeight.w700, _orange)),
                            ),
                          ],
                        ),
                      )
                    : state.loads.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.local_shipping_outlined, color: _grey3, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  isFiltered
                                      ? 'No loads match your search'
                                      : 'No loads available right now',
                                  style: _t(15, FontWeight.w600, _grey3),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isFiltered ? 'Try different locations' : 'Pull down to refresh',
                                  style: _t(12, FontWeight.w400, _grey3),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: _orange,
                            onRefresh: () => ref
                                .read(_transporterLoadsProvider.notifier)
                                .refresh(
                                  pickup: _pickupCtrl.text.trim().isNotEmpty ? _pickupCtrl.text.trim() : null,
                                  drop:   _dropCtrl.text.trim().isNotEmpty   ? _dropCtrl.text.trim()   : null,
                                ),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                              itemCount: state.loads.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _LoadCard(
                                  load: state.loads[i],
                                  onTap: () => _showDetail(context, state.loads[i]),
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, LoadRequirementModel load) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoadDetailSheet(load: load),
    );
  }
}

// ─── Load Card ────────────────────────────────────────────────────────────────

class _LoadCard extends StatelessWidget {
  final LoadRequirementModel load;
  final VoidCallback onTap;
  const _LoadCard({required this.load, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company + date
            Row(
              children: [
                Expanded(
                  child: Text(
                    load.companyName ?? 'Load Owner',
                    style: _t(13, FontWeight.w700, _grey1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(load.displayDate, style: _t(11, FontWeight.w500, _grey3)),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: _divider),
            const SizedBox(height: 10),
            // Route
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 13, color: _orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(load.pickupLocation ?? '—', style: _t(13, FontWeight.w600, _grey1),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
              child: Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _grey3),
            ),
            Row(
              children: [
                const Icon(Icons.flag_rounded, size: 13, color: _grey3),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(load.unloadLocation ?? '—', style: _t(13, FontWeight.w600, _grey1),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Material + trucks
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 13, color: _grey3),
                const SizedBox(width: 6),
                Text(load.materialType ?? '—', style: _t(12, FontWeight.w500, _grey2)),
                const Spacer(),
                const Icon(Icons.local_shipping_outlined, size: 13, color: _grey3),
                const SizedBox(width: 4),
                Text('${load.truckCount} truck${load.truckCount > 1 ? 's' : ''}',
                    style: _t(12, FontWeight.w500, _grey2)),
              ],
            ),
            if (load.capacity != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.scale_outlined, size: 13, color: _grey3),
                  const SizedBox(width: 6),
                  Text(load.capacity!, style: _t(12, FontWeight.w500, _grey2)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Load Detail Bottom Sheet ─────────────────────────────────────────────────

class _LoadDetailSheet extends StatelessWidget {
  final LoadRequirementModel load;
  const _LoadDetailSheet({required this.load});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: _divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Load Details', style: _t(18, FontWeight.w800, _grey1)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _orangeL,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('PENDING', style: _t(10, FontWeight.w700, _orange).copyWith(letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _DetailSection(
                    icon: Icons.business_rounded,
                    title: 'Load Owner',
                    children: [
                      _DetailRow(label: 'Company', value: load.companyName ?? '—'),
                      if (load.companyCity != null || load.companyState != null)
                        _DetailRow(
                          label: 'Location',
                          value: [load.companyCity, load.companyState]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(', '),
                        ),
                      if (load.companyPhone != null)
                        _DetailRow(label: 'Phone', value: load.companyPhone!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    icon: Icons.route_rounded,
                    title: 'Route',
                    children: [
                      _DetailRow(label: 'Pickup', value: load.pickupLocation ?? '—'),
                      _DetailRow(label: 'Drop', value: load.unloadLocation ?? '—'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    icon: Icons.inventory_2_outlined,
                    title: 'Load Info',
                    children: [
                      _DetailRow(label: 'Material', value: load.materialType ?? '—'),
                      _DetailRow(label: 'Trucks Required', value: '${load.truckCount}'),
                      if (load.capacity != null)
                        _DetailRow(label: 'Capacity', value: load.capacity!),
                      if (load.entryDate != null)
                        _DetailRow(label: 'Date', value: load.entryDate!),
                    ],
                  ),
                  if (load.axelType != null || load.bodyType != null || load.floorType != null) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      icon: Icons.settings_outlined,
                      title: 'Truck Specs',
                      children: [
                        if (load.axelType != null)
                          _DetailRow(label: 'Axle Type', value: load.axelType!),
                        if (load.bodyType != null)
                          _DetailRow(label: 'Body Type', value: load.bodyType!),
                        if (load.floorType != null)
                          _DetailRow(label: 'Floor Type', value: load.floorType!),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Posted On', value: load.displayDate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _DetailSection({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _orange),
              const SizedBox(width: 6),
              Text(title, style: _t(12, FontWeight.w700, _grey2).copyWith(letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: _t(12, FontWeight.w500, _grey3)),
          ),
          Expanded(
            child: Text(value, style: _t(12, FontWeight.w600, _grey1)),
          ),
        ],
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
    final initials = ((user?.fullName ?? 'T') as String)
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Container(
              color: _cardBg,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Row(
                children: [
                  Text('Profile', style: _t(22, FontWeight.w800, _grey1)),
                  const Spacer(),
                  Icon(Icons.person_rounded, color: _orange.withOpacity(0.5), size: 28),
                ],
              ),
            ),
            Container(height: 1, color: _divider),
            const SizedBox(height: 28),

            // Avatar + name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: _orangeL,
                      shape: BoxShape.circle,
                      border: Border.all(color: _orange.withOpacity(0.4), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(initials, style: _t(28, FontWeight.w800, _orange)),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? '—', style: _t(18, FontWeight.w700, _grey1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: _orangeL,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_shipping_rounded, size: 13, color: _orange),
                        const SizedBox(width: 5),
                        Text('Independent Transporter',
                            style: _t(11, FontWeight.w700, _orange)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Info tiles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.phone_outlined,
                    label: 'Mobile Number',
                    value: user?.phone ?? '—',
                  ),
                  if (user?.email != null && (user!.email?.isNotEmpty ?? false))
                    _ProfileTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email!,
                    ),
                  _ProfileTile(
                    icon: Icons.badge_outlined,
                    label: 'Username',
                    value: user?.username ?? '—',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Info box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _amberL,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _amber.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: _amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'As a Transporter, you can only upload loading slips for trips assigned to you by a Logistic Partner.',
                        style: _t(12, FontWeight.w500, Color(0xFF78550E)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Logout
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go(AppConstants.routeLogin);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text('Logout', style: _t(15, FontWeight.w600, Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ProfileTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _orangeL,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _t(10, FontWeight.w500, _grey3)),
                const SizedBox(height: 2),
                Text(value, style: _t(14, FontWeight.w600, _grey1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / Error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: _orangeL,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_outlined, size: 48, color: _orange),
            ),
            const SizedBox(height: 20),
            Text('No trips assigned yet', style: _t(18, FontWeight.w700, _grey1)),
            const SizedBox(height: 8),
            Text(
              'A Logistic Partner will assign trips to you. You will see them here once assigned.',
              style: _t(13, FontWeight.w400, _grey3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 36, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            Text('Could not load trips', style: _t(16, FontWeight.w700, _grey1)),
            const SizedBox(height: 8),
            Text(message, style: _t(12, FontWeight.w400, _grey3), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Try Again', style: _t(14, FontWeight.w600, Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
