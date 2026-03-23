import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/providers/trip_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _primary = Color(0xFFFF6B00);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _surface = Color(0xFFFFFFFF);

TextStyle _manrope({
  double size = 14,
  FontWeight weight = FontWeight.w600,
  Color color = _onSurface,
}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _secondary,
}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

// ─── Screen ───────────────────────────────────────────────────────────────────

class TripLocateScreen extends ConsumerStatefulWidget {
  final TripModel trip;
  final TripLocationModel? location;

  const TripLocateScreen({
    super.key,
    required this.trip,
    this.location,
  });

  @override
  ConsumerState<TripLocateScreen> createState() => _TripLocateScreenState();
}

class _TripLocateScreenState extends ConsumerState<TripLocateScreen> {
  final _mapController = MapController();
  TripLocationModel? _currentLocation;
  bool _isRefreshing = false;
  Timer? _autoRefreshTimer;

  // Default centre: Mumbai (fallback when no GPS available)
  static const _defaultCenter = LatLng(19.0760, 72.8777);

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.location;
    if (_currentLocation?.hasLocation == true) {
      // Auto-refresh every 30 s
      _autoRefreshTimer =
          Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    final loc = await ref
        .read(tripProvider.notifier)
        .fetchTripLocation(widget.trip.id);
    if (mounted) {
      setState(() {
        _currentLocation = loc;
        _isRefreshing = false;
      });
      if (loc?.hasLocation == true) {
        _mapController.move(
          LatLng(loc!.latitude!, loc.longitude!),
          15.0,
        );
      }
    }
  }

  LatLng get _vehicleLatLng {
    final loc = _currentLocation;
    if (loc?.hasLocation == true) {
      return LatLng(loc!.latitude!, loc.longitude!);
    }
    return _defaultCenter;
  }

  @override
  Widget build(BuildContext context) {
    final hasGps = _currentLocation?.hasLocation == true;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _vehicleLatLng,
              initialZoom: hasGps ? 15.0 : 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fleet.management',
              ),
              if (hasGps)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _vehicleLatLng,
                      width: 60,
                      height: 60,
                      child: _VehicleMarker(
                        vehiclePlate: widget.trip.vehiclePlate,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Top bar ──────────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              tripNumber: widget.trip.tripNumber,
              isRefreshing: _isRefreshing,
              onBack: () => Navigator.of(context).pop(),
              onRefresh: _refresh,
            ),
          ),

          // ── Map controls ─────────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              children: [
                _MapBtn(
                  icon: Icons.add_rounded,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                const SizedBox(height: 8),
                _MapBtn(
                  icon: Icons.remove_rounded,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                ),
                const SizedBox(height: 8),
                if (hasGps)
                  _MapBtn(
                    icon: Icons.my_location_rounded,
                    color: _primary,
                    onTap: () =>
                        _mapController.move(_vehicleLatLng, 15.0),
                  ),
              ],
            ),
          ),

          // ── Bottom info sheet ─────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomSheet(
              trip: widget.trip,
              location: _currentLocation,
              hasGps: hasGps,
            ),
          ),

          // ── No GPS overlay ────────────────────────────────────────────────────
          if (!hasGps)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off_rounded,
                        size: 48, color: _secondary),
                    const SizedBox(height: 12),
                    Text('No GPS Location Available',
                        style: _manrope(size: 15, weight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      _currentLocation?.message ??
                          'The driver app has not shared a location yet for this trip.',
                      style: _inter(size: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, color: _primary),
                      label: Text('Try Again',
                          style: _inter(
                              size: 13,
                              weight: FontWeight.w700,
                              color: _primary)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String tripNumber;
  final bool isRefreshing;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _TopBar({
    required this.tripNumber,
    required this.isRefreshing,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    size: 18, color: _onSurface),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: _primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Locating $tripNumber',
                        style: _manrope(size: 13, weight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF22C55E)),
                    ),
                    const SizedBox(width: 5),
                    Text('LIVE',
                        style: _inter(
                            size: 10,
                            weight: FontWeight.w700,
                            color: Color(0xFF22C55E))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRefresh,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: isRefreshing
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _primary),
                      )
                    : const Icon(Icons.refresh_rounded,
                        size: 20, color: _onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vehicle marker ───────────────────────────────────────────────────────────

class _VehicleMarker extends StatelessWidget {
  final String? vehiclePlate;
  const _VehicleMarker({this.vehiclePlate});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            vehiclePlate ?? 'VEHICLE',
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
        ),
        CustomPaint(
          size: const Size(12, 6),
          painter: _TrianglePainter(),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _primary;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Map button ───────────────────────────────────────────────────────────────

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MapBtn({
    required this.icon,
    required this.onTap,
    this.color = _onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ─── Bottom sheet ─────────────────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final TripModel trip;
  final TripLocationModel? location;
  final bool hasGps;

  const _BottomSheet({
    required this.trip,
    required this.location,
    required this.hasGps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
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
                color: const Color(0xFFCDD0D5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Trip number + status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.tripNumber,
                        style: _manrope(
                            size: 18, weight: FontWeight.w900)),
                    Text('${trip.origin} → ${trip.destination}',
                        style: _inter(size: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _GpsStatusDot(hasGps: hasGps),
            ],
          ),
          const SizedBox(height: 16),

          // Info chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (trip.vehiclePlate != null)
                  _InfoChip(
                      icon: Icons.local_shipping_rounded,
                      label: trip.vehiclePlate!),
                if (trip.driverName != null)
                  _InfoChip(
                      icon: Icons.person_rounded,
                      label: trip.driverName!),
                if (trip.loadItem.isNotEmpty)
                  _InfoChip(
                      icon: Icons.inventory_2_rounded,
                      label: trip.loadItem),
                if (trip.weight != null)
                  _InfoChip(
                      icon: Icons.scale_rounded, label: trip.weight!),
                if (location?.speed != null)
                  _InfoChip(
                      icon: Icons.speed_rounded,
                      label:
                          '${location!.speed!.toStringAsFixed(0)} km/h'),
              ].map((w) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: w,
                  )).toList(),
            ),
          ),

          if (location?.timestamp != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last updated: ${_formatTime(location!.timestamp!)}',
              style: _inter(size: 11),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return iso;
    }
  }
}

class _GpsStatusDot extends StatelessWidget {
  final bool hasGps;
  const _GpsStatusDot({required this.hasGps});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasGps
                ? const Color(0xFF22C55E)
                : const Color(0xFFE53935),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          hasGps ? 'GPS Active' : 'No Signal',
          style: _inter(
            size: 11,
            weight: FontWeight.w600,
            color: hasGps
                ? const Color(0xFF2E7D32)
                : const Color(0xFFBA1A1A),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _secondary),
          const SizedBox(width: 5),
          Text(label,
              style: _inter(size: 12, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
