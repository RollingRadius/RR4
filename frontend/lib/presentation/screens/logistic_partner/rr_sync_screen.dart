import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';

// ─── Typography helpers (local) ───────────────────────────────────────────────

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

// ─── Colour tokens (mirror dashboard) ────────────────────────────────────────

const _primary = Color(0xFFFF6B00);
const _surfaceContainer = Color(0xFFECEEF0);
const _secondary = Color(0xFF546067);
const _errorColor = Color(0xFFBA1A1A);
const _errorContainer = Color(0xFFFFDAD6);
const _successColor = Color(0xFF006B5E);
const _successContainer = Color(0xFFCCF0EB);

// ─── Entry point — show as modal bottom sheet ─────────────────────────────────

void showRrSyncSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: const _RrSyncSheet(),
    ),
  );
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class _RrSyncSheet extends ConsumerStatefulWidget {
  const _RrSyncSheet();

  @override
  ConsumerState<_RrSyncSheet> createState() => _RrSyncSheetState();
}

class _RrSyncSheetState extends ConsumerState<_RrSyncSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rrSyncProvider.notifier).loadReadyTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rrSyncProvider);

    // Show snackbar on success or error
    ref.listen<RrSyncState>(rrSyncProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.successMessage!),
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(state),
            if (state.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: _primary)))
            else
              Expanded(
                child: RefreshIndicator(
                  color: _primary,
                  onRefresh: () => ref.read(rrSyncProvider.notifier).loadReadyTrips(),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      if (state.readyTrips.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Ready to Sync',
                          '${state.readyTrips.length}',
                          color: _successColor,
                        ),
                        ...state.readyTrips.map((trip) => _ReadyTripTile(trip: trip)),
                        const SizedBox(height: 8),
                      ],
                      if (state.readyTrips.isEmpty && state.missingDataTrips.isEmpty && !state.isLoading)
                        _buildEmptyState(),
                      if (state.missingDataTrips.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Uploads Incomplete',
                          '${state.missingDataTrips.length}',
                          color: _errorColor,
                        ),
                        ...state.missingDataTrips.map((trip) => _MissingTripTile(trip: trip)),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() => Column(children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: _surfaceContainer,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
      ]);

  Widget _buildHeader(RrSyncState state) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
        child: Row(
          children: [
            const Icon(Icons.sync_rounded, color: _primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text('RR Sync Manager', style: _manrope(size: 17)),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _secondary, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(rrSyncProvider.notifier).loadReadyTrips(),
            ),
          ],
        ),
      );

  Widget _buildSectionHeader(String title, String count, {required Color color}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(count,
                  style: _manrope(size: 12, weight: FontWeight.w700, color: color)),
            ),
            const SizedBox(width: 8),
            Text(title, style: _manrope(size: 13, color: const Color(0xFF191C1E))),
          ],
        ),
      );

  Widget _buildEmptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: _successColor.withOpacity(0.5), size: 48),
              const SizedBox(height: 12),
              Text('All trips are synced', style: _manrope(size: 15, color: _secondary)),
              const SizedBox(height: 4),
              Text('No trips pending RR sync',
                  style: _inter(size: 13, color: _secondary)),
            ],
          ),
        ),
      );
}

// ─── Ready trip tile — tap to login + sync ────────────────────────────────────

class _ReadyTripTile extends ConsumerWidget {
  final Map<String, dynamic> trip;
  const _ReadyTripTile({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripId = trip['trip_id'] as String;
    final isSyncing = ref.watch(
        rrSyncProvider.select((s) => s.syncingTripId == tripId));
    final syncStatus = trip['rr_sync_status'] as String? ?? 'not_synced';
    final lastStage = trip['last_stage'] as String? ?? 'S2';

    return GestureDetector(
      onTap: isSyncing ? null : () => _onTap(context, ref, tripId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _surfaceContainer),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: isSyncing
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: _primary, strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded, color: _primary, size: 22),
          title: Text(
            trip['trip_number'] as String? ?? tripId,
            style: _manrope(size: 14),
          ),
          subtitle: Text(
            '${trip['origin'] ?? ''} → ${trip['destination'] ?? ''}',
            style: _inter(size: 12),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusChip(syncStatus),
              const SizedBox(height: 2),
              Text(lastStage, style: _inter(size: 11, color: _secondary)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, String tripId) async {
    await runRrAction(context, ref, () => ref.read(rrSyncProvider.notifier).syncTrip(tripId));
  }
}

// ─── Missing data tile (read-only, shows what's missing) ─────────────────────

class _MissingTripTile extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _MissingTripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final missing = List<String>.from(trip['missing'] as List? ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _errorContainer.withOpacity(0.4),
        border: Border.all(color: _errorContainer),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: const Icon(Icons.warning_amber_rounded,
            color: _errorColor, size: 22),
        title: Text(
          trip['trip_number'] as String? ?? trip['trip_id'] as String,
          style: _manrope(size: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${trip['origin'] ?? ''} → ${trip['destination'] ?? ''}',
              style: _inter(size: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: missing
                  .take(3)
                  .map((m) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(m,
                            style: _inter(
                                size: 10,
                                weight: FontWeight.w500,
                                color: _errorColor)),
                      ))
                  .toList(),
            ),
            if (missing.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('+${missing.length - 3} more',
                    style: _inter(size: 10, color: _errorColor)),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'not_synced'         => ('Not synced',    const Color(0xFFECEEF0), _secondary),
      'failed'             => ('Failed',         _errorContainer,         _errorColor),
      'trip_created'       => ('Trip created',   const Color(0xFFE8F4FD), const Color(0xFF0066CC)),
      'loading_slip_synced'=> ('S2 synced',      _successContainer,       _successColor),
      'bilty_synced'       => ('S3 synced',      _successContainer,       _successColor),
      'pod_synced'         => ('Fully synced',   _successContainer,       _successColor),
      _ => (status, const Color(0xFFECEEF0), _secondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: _inter(size: 10, weight: FontWeight.w600, color: fg)),
    );
  }
}
