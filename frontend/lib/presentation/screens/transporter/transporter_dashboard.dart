import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/presentation/widgets/ongoing_trip_card.dart';

// ─── Design tokens (matches OngoingTripCard) ───────────────────────────────────

const _primary        = Color(0xFFFF6B00);
const _navy           = Color(0xFF001E40);
const _surface        = Color(0xFFF2F4F6);
const _card           = Colors.white;
const _secondary      = Color(0xFF546067);
const _outlineVariant = Color(0xFFCDD0D5);

TextStyle _manrope({double size = 14, FontWeight weight = FontWeight.w600, Color color = const Color(0xFF191C1E)}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter({double size = 13, FontWeight weight = FontWeight.w400, Color color = const Color(0xFF546067)}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

// ─── Provider ──────────────────────────────────────────────────────────────────

final transporterTripsProvider =
    StateNotifierProvider.autoDispose<_TransporterTripsNotifier, _TripsState>(
  (ref) => _TransporterTripsNotifier(ref.watch(dioProvider)),
);

class _TripsState {
  final List<TripModel> trips;
  final bool isLoading;
  final String? error;

  const _TripsState({this.trips = const [], this.isLoading = false, this.error});

  _TripsState copyWith({List<TripModel>? trips, bool? isLoading, String? error}) =>
      _TripsState(trips: trips ?? this.trips, isLoading: isLoading ?? this.isLoading, error: error);

  List<TripModel> get active   => trips.where((t) => t.s2LoadingSlipUrl == null).toList();
  List<TripModel> get uploaded => trips.where((t) => t.s2LoadingSlipUrl != null).toList();
}

class _TransporterTripsNotifier extends StateNotifier<_TripsState> {
  final Dio _dio;
  _TransporterTripsNotifier(this._dio) : super(const _TripsState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/api/trips/transporter/assigned');
      final trips = ((resp.data['trips'] as List?) ?? [])
          .map((j) => TripModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(trips: trips, isLoading: false);
    } catch (e) {
      final msg = e is DioException
          ? (e.response?.data?['detail'] as String? ?? 'Failed to load trips')
          : e.toString();
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  void patchTrip(TripModel updated) {
    state = state.copyWith(
      trips: state.trips.map((t) => t.id == updated.id ? updated : t).toList(),
    );
  }
}

// ─── Root screen ───────────────────────────────────────────────────────────────

class TransporterDashboard extends ConsumerStatefulWidget {
  const TransporterDashboard({super.key});

  @override
  ConsumerState<TransporterDashboard> createState() => _TransporterDashboardState();
}

class _TransporterDashboardState extends ConsumerState<TransporterDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(transporterTripsProvider);

    return Scaffold(
      backgroundColor: _surface,
      body: IndexedStack(
        index: _tab,
        children: [
          _DashboardTab(tripsState: tripsState),
          _RecordsTab(tripsState: tripsState),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: _card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: _primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: _primary),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: _primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Tab ─────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  final _TripsState tripsState;
  const _DashboardTab({required this.tripsState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final active = tripsState.active;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(transporterTripsProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: _Header(
                userName: user?.fullName ?? 'Transporter',
                activeCount: active.length,
                uploadCount: tripsState.uploaded.length,
                onRefresh: () => ref.read(transporterTripsProvider.notifier).load(),
              ),
            ),

            if (tripsState.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))

            else if (tripsState.error != null)
              SliverFillRemaining(
                child: _ErrorView(
                  message: tripsState.error!,
                  onRetry: () => ref.read(transporterTripsProvider.notifier).load(),
                ),
              )

            else if (active.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.airport_shuttle_outlined, size: 72, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No trips assigned yet',
                          style: _manrope(size: 16, color: _secondary)),
                      const SizedBox(height: 8),
                      Text('A Logistic Partner will assign trips to you',
                          style: _inter(size: 13, color: const Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
              )

            else ...[
              // ── Fleet Status header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                  child: OngoingTripsSectionHeader(count: active.length),
                ),
              ),

              // ── Trip cards ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _TransporterTripCard(trip: active[i]),
                    ),
                    childCount: active.length,
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

// ─── Transporter Trip Card ─────────────────────────────────────────────────────

class _TransporterTripCard extends ConsumerStatefulWidget {
  final TripModel trip;
  const _TransporterTripCard({required this.trip});

  @override
  ConsumerState<_TransporterTripCard> createState() => _TransporterTripCardState();
}

class _TransporterTripCardState extends ConsumerState<_TransporterTripCard> {
  bool _uploading = false;
  String? _errorMsg;
  final _picker = ImagePicker();

  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() { _uploading = true; _errorMsg = null; });

    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(
        '/api/trips/${widget.trip.id}/transporter-loading-slip',
        data: FormData.fromMap({
          'slip': MultipartFile.fromBytes(bytes, filename: picked.name),
        }),
      );
      final updated = TripModel.fromJson(
        (resp.data as Map<String, dynamic>)['trip'] as Map<String, dynamic>,
      );
      if (mounted) {
        ref.read(transporterTripsProvider.notifier).patchTrip(updated);
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading slip uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final msg = e is DioException
          ? (e.response?.data?['detail'] as String? ?? 'Upload failed')
          : e.toString();
      if (mounted) setState(() { _uploading = false; _errorMsg = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsUpload = widget.trip.isAtLoadingSlipStage;

    return Column(
      children: [
        // Same fleet-status card as LP (read-only — no LP actions shown)
        OngoingTripCard(trip: widget.trip, readOnly: true),

        // Upload panel — only at loading slip stage
        if (needsUpload) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file_rounded, size: 12, color: _primary),
                      const SizedBox(width: 4),
                      Text('ACTION REQUIRED',
                          style: _inter(size: 9, weight: FontWeight.w700, color: _primary)
                              .copyWith(letterSpacing: 0.8)),
                    ],
                  ),
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorMsg!, style: _inter(size: 12, color: Colors.red)),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _uploading ? null : _pickAndUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: _uploading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(
                      _uploading ? 'Uploading...' : 'Upload Loading Slip',
                      style: _manrope(size: 14, weight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Records Tab ───────────────────────────────────────────────────────────────

class _RecordsTab extends ConsumerWidget {
  final _TripsState tripsState;
  const _RecordsTab({required this.tripsState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploaded = tripsState.uploaded;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Records', style: _manrope(size: 22, weight: FontWeight.w800)),
                Text('${uploaded.length} slip${uploaded.length == 1 ? '' : 's'} uploaded',
                    style: _inter(size: 13)),
              ],
            ),
          ),
          Expanded(
            child: tripsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : uploaded.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No uploaded slips yet',
                                style: _manrope(size: 16, color: _secondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(transporterTripsProvider.notifier).load(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: uploaded.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _RecordCard(trip: uploaded[i]),
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
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TRIP NUMBER',
                        style: _inter(size: 9, weight: FontWeight.w700, color: _secondary)
                            .copyWith(letterSpacing: 1.2)),
                    Text(trip.tripNumber,
                        style: _manrope(size: 15, weight: FontWeight.w800, color: _primary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7F0D9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('SLIP UPLOADED',
                    style: _inter(size: 9, weight: FontWeight.w700, color: const Color(0xFF1B5E20))
                        .copyWith(letterSpacing: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(trip.origin,
              style: _manrope(size: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Text('↓', style: _inter(size: 11, color: _outlineVariant)),
          ),
          Text(trip.destination,
              style: _manrope(size: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 13, color: _secondary),
              const SizedBox(width: 6),
              Text(trip.loadItem, style: _inter(size: 12)),
              if (trip.weight != null) ...[
                Text(' · ', style: _inter(size: 12)),
                Text(trip.weight!, style: _inter(size: 12)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
              const SizedBox(width: 6),
              Text('Loading slip uploaded',
                  style: _inter(size: 12, weight: FontWeight.w600, color: const Color(0xFF2E7D32))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Profile Tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: _manrope(size: 22, weight: FontWeight.w800)),
            const SizedBox(height: 28),

            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: _primary.withOpacity(0.1),
                    child: Text(
                      (user?.fullName ?? 'T').substring(0, 1).toUpperCase(),
                      style: _manrope(size: 32, weight: FontWeight.w800, color: _primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? '—',
                      style: _manrope(size: 18, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: _navy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Transporter',
                        style: _inter(size: 12, weight: FontWeight.w700, color: _navy)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: user?.phone ?? '—'),
            if (user?.email != null && user!.email!.isNotEmpty)
              _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email!),

            const SizedBox(height: 32),

            SizedBox(
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
                icon: const Icon(Icons.logout),
                label: Text('Logout',
                    style: _manrope(size: 15, weight: FontWeight.w600, color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String userName;
  final int activeCount;
  final int uploadCount;
  final VoidCallback onRefresh;

  const _Header({
    required this.userName,
    required this.activeCount,
    required this.uploadCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF003070)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: _navy.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(Icons.airport_shuttle_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back', style: _inter(size: 12, color: Colors.white60)),
                    Text(userName,
                        style: _manrope(size: 17, weight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                onPressed: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderStat(label: 'Active Trips', count: activeCount, color: _primary),
              const SizedBox(width: 12),
              _HeaderStat(label: 'Uploaded', count: uploadCount, color: const Color(0xFF4CAF50)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _HeaderStat({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: _manrope(size: 18, weight: FontWeight.w800, color: color)),
          const SizedBox(width: 6),
          Text(label, style: _inter(size: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _navy),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _inter(size: 11, color: _secondary)),
              Text(value, style: _manrope(size: 14, weight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
