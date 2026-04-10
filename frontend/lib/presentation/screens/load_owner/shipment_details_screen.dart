import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/presentation/screens/shared/truck_tracking_screen.dart';

// Additional colour used for stage 4
const _stage4Color = Color(0xFF6750A4);

// ─── Colour tokens (shared with dashboard) ────────────────────────────────────
const _primary = Color(0xFFFF6B00);
const _background = Color(0xFFF8F9FB);
const _surfaceLowest = Color(0xFFFFFFFF);
const _surfaceContainer = Color(0xFFECEEF0);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _tertiary = Color(0xFF006B5E);
const _error = Color(0xFFBA1A1A);
const _errorContainer = Color(0xFFFFDAD6);

// ─── Provider: fetch full trip detail by ID ───────────────────────────────────

final _tripDetailProvider =
    FutureProvider.autoDispose.family<TripModel, String>((ref, tripId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/api/trips/$tripId');
  final data = response.data as Map<String, dynamic>;
  // Backend returns the trip dict directly (no 'trip' wrapper key)
  return TripModel.fromJson(data);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class ShipmentDetailsScreen extends ConsumerStatefulWidget {
  final TripModel trip;
  const ShipmentDetailsScreen({super.key, required this.trip});

  @override
  ConsumerState<ShipmentDetailsScreen> createState() => _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends ConsumerState<ShipmentDetailsScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) ref.invalidate(_tripDetailProvider(widget.trip.id));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(_tripDetailProvider(widget.trip.id));

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surfaceLowest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: _onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.trip.tripNumber,
          style: GoogleFonts.manrope(
              fontSize: 16, fontWeight: FontWeight.w800, color: _onSurface),
        ),
        actions: [
          detailAsync.whenOrNull(
            data: (fullTrip) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fullTrip.currentStage >= 3)
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TruckTrackingScreen(
                          trip: fullTrip,
                          emptyWeightUnit:
                              fullTrip.s3EmptyTruckWeightUnit ?? 'tons',
                          loadedWeightUnit:
                              fullTrip.s3LoadedTruckWeightUnit ?? 'tons',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.local_shipping_rounded,
                        size: 16, color: _primary),
                    label: Text('Track',
                        style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _primary)),
                  ),
                _StatusBadge(trip: fullTrip),
                const SizedBox(width: 8),
              ],
            ),
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: _error),
              const SizedBox(height: 12),
              Text('Failed to load details',
                  style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _onSurface)),
              const SizedBox(height: 4),
              Text(e.toString(),
                  style: GoogleFonts.inter(fontSize: 12, color: _secondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(_tripDetailProvider(widget.trip.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (fullTrip) => _ShipmentBody(trip: fullTrip),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _ShipmentBody extends StatelessWidget {
  final TripModel trip;
  const _ShipmentBody({required this.trip});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TripHeaderCard(trip: trip),
        const SizedBox(height: 16),
        _StageTimeline(trip: trip),
        const SizedBox(height: 16),
        if (trip.currentStage >= 1) ...[
          _Stage1Card(trip: trip),
          const SizedBox(height: 12),
        ],
        if (trip.currentStage >= 2) ...[
          _Stage2Card(trip: trip),
          const SizedBox(height: 12),
        ],
        if (trip.currentStage >= 3) ...[
          _Stage3Card(trip: trip),
          const SizedBox(height: 12),
        ],
        if (trip.currentStage >= 4) ...[
          _Stage4Card(trip: trip),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Trip header card ─────────────────────────────────────────────────────────

class _TripHeaderCard extends StatelessWidget {
  final TripModel trip;
  const _TripHeaderCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.loadItem,
                  style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _onSurface),
                ),
              ),
              _StatusBadge(trip: trip),
            ],
          ),
          const SizedBox(height: 12),
          _RouteRow(
            icon: Icons.radio_button_checked_rounded,
            iconColor: _tertiary,
            label: trip.origin,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(width: 2, height: 10, color: _surfaceContainer),
          ),
          _RouteRow(
            icon: Icons.location_on_rounded,
            iconColor: _secondary,
            label: trip.destination,
          ),
          if (trip.tripAmount != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.currency_rupee_rounded,
                    size: 14, color: _secondary),
                Text(
                  '${trip.tripAmount!.toStringAsFixed(0)} agreed freight',
                  style: GoogleFonts.inter(fontSize: 12, color: _secondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _RouteRow(
      {required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TripModel trip;
  const _StatusBadge({required this.trip});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _tripStateColors(trip);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg,
              letterSpacing: 0.4)),
    );
  }
}

(String, Color, Color) _tripStateColors(TripModel trip) {
  if (trip.isCancelled) return ('CANCELLED', const Color(0xFFFFDAD6), const Color(0xFFBA1A1A));
  if (trip.isCompleted) return ('COMPLETED', const Color(0xFFECEEF0), const Color(0xFF546067));
  if (trip.currentStage >= 4) return ('IN TRANSIT', const Color(0xFFD7F0D9), const Color(0xFF1B5E20));
  if (trip.currentStage >= 1) return ('ONGOING', const Color(0xFFFFE8D5), const Color(0xFFFF6B00));
  return ('PENDING', const Color(0xFFFFF3E0), const Color(0xFFE65100));
}

// ─── Stage progress timeline ──────────────────────────────────────────────────

class _StageTimeline extends StatelessWidget {
  final TripModel trip;
  const _StageTimeline({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceContainer),
      ),
      child: Row(
        children: [
          _StepDot(label: 'Verification', done: trip.currentStage >= 1, step: 1),
          _StepLine(done: trip.currentStage >= 2),
          _StepDot(label: 'Compliance', done: trip.currentStage >= 2, step: 2),
          _StepLine(done: trip.currentStage >= 3),
          _StepDot(label: 'Weighing', done: trip.currentStage >= 3, step: 3),
          _StepLine(done: trip.currentStage >= 4),
          _StepDot(label: 'Exit', done: trip.currentStage >= 4, step: 4,
              activeColor: _stage4Color),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool done;
  final int step;
  final Color? activeColor;
  const _StepDot({required this.label, required this.done, required this.step,
      this.activeColor});

  @override
  Widget build(BuildContext context) {
    final fillColor = done ? (activeColor ?? _primary) : _surfaceContainer;
    final textColor = done ? (activeColor ?? _primary) : _secondary;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: fillColor,
              shape: BoxShape.circle,
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Center(
                    child: Text(
                      '$step',
                      style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _secondary),
                    ),
                  ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: textColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 2,
      color: done ? _primary : _surfaceContainer,
    );
  }
}

// ─── Stage section header ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool completed;
  const _SectionHeader({required this.title, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: completed ? _primary : _surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: completed
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.manrope(
              fontSize: 14, fontWeight: FontWeight.w700, color: _onSurface),
        ),
        const Spacer(),
        if (completed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('COMPLETED',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _primary)),
          ),
      ],
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style:
                    GoogleFonts.inter(fontSize: 12, color: _secondary)),
          ),
          Expanded(
            child: Text(value!,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _onSurface)),
          ),
        ],
      ),
    );
  }
}

// ─── Stage 1 card ─────────────────────────────────────────────────────────────

class _Stage1Card extends StatelessWidget {
  final TripModel trip;
  const _Stage1Card({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Stage 1 — Driver & Vehicle Verification',
              completed: true),
          const SizedBox(height: 14),
          _InfoRow(label: 'Driver Name', value: trip.s1DriverName),
          _InfoRow(label: 'Driver Phone', value: trip.s1DriverPhone),
          _InfoRow(label: 'Driving License', value: trip.s1DrivingLicense),
          _InfoRow(label: 'Aadhaar', value: trip.s1Aadhaar),
          _InfoRow(label: 'RC Number', value: trip.s1Rc),
          _InfoRow(label: 'Insurance', value: trip.s1Insurance),
          _InfoRow(label: 'Pollution Cert.', value: trip.s1Pollution),
          _InfoRow(label: 'Fitness Cert.', value: trip.s1Fitness),
          _InfoRow(label: 'PAN', value: trip.s1Pan),
          if (trip.vehiclePlate != null || trip.vehicleModel != null) ...[
            const Divider(height: 20),
            _InfoRow(label: 'Vehicle Plate', value: trip.vehiclePlate),
            _InfoRow(label: 'Vehicle Model', value: trip.vehicleModel),
          ],
        ],
      ),
    );
  }
}

// ─── Stage 2 card ─────────────────────────────────────────────────────────────

class _Stage2Card extends StatelessWidget {
  final TripModel trip;
  const _Stage2Card({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Stage 2 — Safety & Compliance', completed: true),
          const SizedBox(height: 14),
          _CheckRow(label: 'Truck Specs Verified', value: trip.s2SpecsVerified),
          _CheckRow(label: 'Documents Verified', value: trip.s2DocsVerified),
          _CheckRow(
              label: 'Driver Documents Valid', value: trip.s2DriverDocsValid),
          _CheckRow(
              label: 'Entry Permission Granted', value: trip.s2EntryPermission),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool? value;
  const _CheckRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final ok = value == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: ok
                  ? const Color(0xFF006B5E).withValues(alpha: 0.12)
                  : _surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ok ? Icons.check_rounded : Icons.close_rounded,
              size: 12,
              color: ok ? const Color(0xFF006B5E) : _secondary,
            ),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ok ? _onSurface : _secondary)),
        ],
      ),
    );
  }
}

// ─── Stage 3 card ─────────────────────────────────────────────────────────────

class _Stage3Card extends StatelessWidget {
  final TripModel trip;
  const _Stage3Card({required this.trip});

  String? get _netLoad {
    final emptyUnit = trip.s3EmptyTruckWeightUnit ?? 'tons';
    final loadedUnit = trip.s3LoadedTruckWeightUnit ?? 'tons';
    final empty = double.tryParse(trip.s3EmptyTruckWeightKg ?? '');
    final loaded = double.tryParse(trip.s3LoadedTruckWeightKg ?? '');
    if (empty == null || loaded == null) return null;
    if (emptyUnit != loadedUnit) return null;
    final net = loaded - empty;
    if (net <= 0) return null;
    return '${net.toStringAsFixed(emptyUnit == 'tons' ? 2 : 0)} $emptyUnit';
  }

  @override
  Widget build(BuildContext context) {
    final emptyUnit = trip.s3EmptyTruckWeightUnit ?? 'tons';
    final loadedUnit = trip.s3LoadedTruckWeightUnit ?? 'tons';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Stage 3 — Arrival & Weighing', completed: true),
          const SizedBox(height: 14),
          _WeightRow(
            label: 'Empty Truck Weight',
            value: trip.s3EmptyTruckWeightKg,
            unit: emptyUnit,
          ),
          _WeightRow(
            label: 'Loaded Truck Weight',
            value: trip.s3LoadedTruckWeightKg,
            unit: loadedUnit,
          ),
          if (_netLoad != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                Text('Net Load',
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _onSurface)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _netLoad!,
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _primary),
                  ),
                ),
              ],
            ),
          ],
          // Bilty image
          if (trip.s3BiltyUrl != null) ...[
            const Divider(height: 24),
            _DocImageSection(
              title: 'Bilty',
              icon: Icons.receipt_long_rounded,
              urls: [trip.s3BiltyUrl!],
            ),
          ],
          // Material documents
          if (trip.s3MaterialDocUrls != null &&
              trip.s3MaterialDocUrls!.isNotEmpty) ...[
            const Divider(height: 24),
            _DocImageSection(
              title: 'Material Documents',
              icon: Icons.folder_open_rounded,
              urls: trip.s3MaterialDocUrls!,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TruckTrackingScreen(
                    trip: trip,
                    emptyWeightUnit: emptyUnit,
                    loadedWeightUnit: loadedUnit,
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.local_shipping_rounded,
                  size: 16, color: _primary),
              label: Text('Track Truck',
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _primary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stage 4 card ─────────────────────────────────────────────────────────────

class _Stage4Card extends StatelessWidget {
  final TripModel trip;
  const _Stage4Card({required this.trip});

  @override
  Widget build(BuildContext context) {
    final notified = trip.s4NotifiedAt != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _stage4Color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: _stage4Color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Stage 4 — Truck Exit From Factory',
                  style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _stage4Color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('COMPLETED',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _stage4Color)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CheckRow(label: 'Truck moved to exit gate',      value: trip.s4TruckMoved),
          _CheckRow(label: 'Security verified documents',   value: trip.s4SecurityVerified),
          _CheckRow(label: 'Bilty checked',                 value: trip.s4BiltyChecked),
          _CheckRow(label: 'Loaded weight slip checked',    value: trip.s4WeightChecked),
          _CheckRow(label: 'Material documents checked',    value: trip.s4MaterialChecked),
          const SizedBox(height: 8),
          // Notification status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: notified
                  ? const Color(0xFF006B5E).withValues(alpha: 0.07)
                  : _surfaceContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  notified ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  size: 14,
                  color: notified ? const Color(0xFF006B5E) : _secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  notified
                      ? 'You were notified by the logistic partner'
                      : 'Logistic partner has not sent a notification yet',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: notified ? const Color(0xFF006B5E) : _secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Document image section ───────────────────────────────────────────────────

class _DocImageSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> urls;

  const _DocImageSection({
    required this.title,
    required this.icon,
    required this.urls,
  });

  String _fullUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${AppConfig.apiBaseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: _secondary),
            const SizedBox(width: 6),
            Text(title,
                style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _onSurface)),
          ],
        ),
        const SizedBox(height: 10),
        if (urls.length == 1)
          _NetworkImage(url: _fullUrl(urls.first), fullWidth: true)
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) =>
                  _NetworkImage(url: _fullUrl(urls[i]), fullWidth: false),
            ),
          ),
      ],
    );
  }
}

class _NetworkImage extends StatelessWidget {
  final String url;
  final bool fullWidth;
  const _NetworkImage({required this.url, required this.fullWidth});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: fullWidth ? double.infinity : 110,
          height: fullWidth ? 200 : 120,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  width: fullWidth ? double.infinity : 110,
                  height: fullWidth ? 200 : 120,
                  color: _surfaceContainer,
                  child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _primary),
                  ),
                ),
          errorBuilder: (_, __, ___) => Container(
            width: fullWidth ? double.infinity : 110,
            height: fullWidth ? 200 : 120,
            color: _surfaceContainer,
            child: const Icon(Icons.broken_image_rounded,
                color: _secondary, size: 32),
          ),
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  final String label;
  final String? value;
  final String unit;
  const _WeightRow(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(fontSize: 12, color: _secondary)),
          ),
          Text(
            '$value $unit',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _onSurface),
          ),
        ],
      ),
    );
  }
}
