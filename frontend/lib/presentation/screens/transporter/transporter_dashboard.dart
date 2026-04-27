import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _transporterTripsProvider =
    StateNotifierProvider.autoDispose<_TransporterTripsNotifier, _TripsState>(
  (ref) => _TransporterTripsNotifier(ref.watch(dioProvider)),
);

class _TripsState {
  final List<TripModel> trips;
  final bool isLoading;
  final String? error;

  const _TripsState({this.trips = const [], this.isLoading = false, this.error});

  _TripsState copyWith({List<TripModel>? trips, bool? isLoading, String? error}) =>
      _TripsState(
        trips: trips ?? this.trips,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  List<TripModel> get pending => trips.where((t) => t.isAtLoadingSlipStage).toList();
  List<TripModel> get uploaded => trips.where((t) => t.s2LoadingSlipUrl != null).toList();
}

class _TransporterTripsNotifier extends StateNotifier<_TripsState> {
  final Dio _dio;

  _TransporterTripsNotifier(this._dio) : super(const _TripsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/api/trips/transporter/assigned');
      final data = resp.data as Map<String, dynamic>;
      final trips = (data['trips'] as List<dynamic>? ?? [])
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

// ─── Screen ───────────────────────────────────────────────────────────────────

class TransporterDashboard extends ConsumerWidget {
  const TransporterDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final tripsState = ref.watch(_transporterTripsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Transporter Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(_transporterTripsProvider.notifier).load(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppConstants.routeLogin);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(_transporterTripsProvider.notifier).load(),
        child: tripsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : tripsState.error != null
                ? _ErrorView(
                    message: tripsState.error!,
                    onRetry: () => ref.read(_transporterTripsProvider.notifier).load(),
                  )
                : _TripsList(
                    pending: tripsState.pending,
                    uploaded: tripsState.uploaded,
                    userName: user?.fullName ?? 'Transporter',
                  ),
      ),
    );
  }
}

// ─── List view ────────────────────────────────────────────────────────────────

class _TripsList extends StatelessWidget {
  final List<TripModel> pending;
  final List<TripModel> uploaded;
  final String userName;

  const _TripsList({
    required this.pending,
    required this.uploaded,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty && uploaded.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.airport_shuttle_outlined, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No trips assigned yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'A Logistic Partner will assign trips to you',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.airport_shuttle, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $userName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${pending.length} pending · ${uploaded.length} uploaded',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Pending uploads
        if (pending.isNotEmpty) ...[
          _SectionHeader(
            title: 'Pending Upload',
            count: pending.length,
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          ...pending.map((t) => _TripCard(trip: t, showUpload: true)),
          const SizedBox(height: 24),
        ],

        // Completed uploads
        if (uploaded.isNotEmpty) ...[
          _SectionHeader(
            title: 'Uploaded',
            count: uploaded.length,
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          ...uploaded.map((t) => _TripCard(trip: t, showUpload: false)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ─── Trip Card ────────────────────────────────────────────────────────────────

class _TripCard extends ConsumerStatefulWidget {
  final TripModel trip;
  final bool showUpload;

  const _TripCard({required this.trip, required this.showUpload});

  @override
  ConsumerState<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends ConsumerState<_TripCard> {
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
      final formData = FormData.fromMap({
        'slip': MultipartFile.fromBytes(bytes, filename: picked.name),
      });
      final resp = await dio.post(
        '/api/trips/${widget.trip.id}/transporter-loading-slip',
        data: formData,
      );
      final updated = TripModel.fromJson(
        (resp.data as Map<String, dynamic>)['trip'] as Map<String, dynamic>,
      );
      if (mounted) {
        ref.read(_transporterTripsProvider.notifier).patchTrip(updated);
        setState(() { _uploading = false; });
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
    final trip = widget.trip;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip number + status
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.tripNumber,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusChip(uploaded: !widget.showUpload),
              ],
            ),
            const SizedBox(height: 10),

            // Route
            Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(child: Text(trip.origin, style: const TextStyle(fontSize: 13))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(width: 1, height: 12, color: Colors.grey[300]),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(child: Text(trip.destination, style: const TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 10),

            // Load item
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(trip.loadItem, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (trip.weight != null) ...[
                  const SizedBox(width: 8),
                  Text('· ${trip.weight}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ],
            ),

            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],

            if (widget.showUpload) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.upload_file, size: 18),
                  label: Text(_uploading ? 'Uploading...' : 'Upload Loading Slip'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool uploaded;
  const _StatusChip({required this.uploaded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: uploaded ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: uploaded ? Colors.green : Colors.orange),
      ),
      child: Text(
        uploaded ? 'Uploaded' : 'Pending',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: uploaded ? Colors.green[700] : Colors.orange[800],
        ),
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
