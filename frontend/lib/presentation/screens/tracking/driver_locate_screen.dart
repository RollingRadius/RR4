import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fleet_management/providers/location_tracking_provider.dart';

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

/// Driver-centric live map — same visual language as TripLocateScreen, but
/// keyed by driverId instead of a trip, for the "Track" sidebar search
/// (LP/RR-ops locating a driver continuously, independent of any trip).
class DriverLocateScreen extends ConsumerStatefulWidget {
  final String driverId;
  final String driverName;

  const DriverLocateScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  ConsumerState<DriverLocateScreen> createState() => _DriverLocateScreenState();
}

class _DriverLocateScreenState extends ConsumerState<DriverLocateScreen> {
  final _mapController = MapController();
  _DriverStatus? _currentStatus;
  bool _isRefreshing = false;
  bool _hasLoaded = false;
  Timer? _autoRefreshTimer;

  // Default centre: Mumbai (fallback when no GPS available)
  static const _defaultCenter = LatLng(19.0760, 72.8777);

  @override
  void initState() {
    super.initState();
    _refresh();
    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _isRefreshing = true);
    _DriverStatus status;
    try {
      final data = await ref.read(trackingApiProvider).getDriverTrackStatus(widget.driverId);
      status = _DriverStatus.fromJson(data);
    } catch (_) {
      status = _DriverStatus.error();
    }
    if (mounted) {
      setState(() {
        _currentStatus = status;
        _isRefreshing = false;
        _hasLoaded = true;
      });
      if (status.hasLocation) {
        _mapController.move(LatLng(status.latitude!, status.longitude!), 15.0);
      }
    }
  }

  LatLng get _driverLatLng {
    final status = _currentStatus;
    if (status?.hasLocation == true) return LatLng(status!.latitude!, status.longitude!);
    return _defaultCenter;
  }

  // Past this age, a location is shown as stale rather than live — mirrors
  // TripLocateScreen's threshold so both screens read consistently.
  static const _staleThreshold = Duration(minutes: 15);

  bool get _isStale {
    final ts = _currentStatus?.timestamp;
    if (ts == null) return false;
    return DateTime.now().toUtc().difference(ts.toUtc()) > _staleThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final hasGps = _currentStatus?.hasLocation == true;
    final isStale = hasGps && _isStale;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverLatLng,
              initialZoom: hasGps ? 15.0 : 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fleet.management',
              ),
              if (hasGps)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _driverLatLng,
                      width: 120,
                      height: 60,
                      child: _DriverMarker(
                        driverName: widget.driverName,
                        isStale: isStale,
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
              driverName: widget.driverName,
              isRefreshing: _isRefreshing,
              onBack: () => Navigator.of(context).pop(),
              onRefresh: _refresh,
            ),
          ),

          // ── Map controls ─────────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 200,
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
                    onTap: () => _mapController.move(_driverLatLng, 15.0),
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
              driverName: widget.driverName,
              status: _currentStatus,
              hasGps: hasGps,
              isStale: isStale,
            ),
          ),

          // ── No GPS overlay ────────────────────────────────────────────────────
          if (_hasLoaded && !hasGps)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off_rounded, size: 48, color: _secondary),
                    const SizedBox(height: 12),
                    Text('No GPS Location Available',
                        style: _manrope(size: 15, weight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      _currentStatus?.message ??
                          'This driver has not shared a location yet, or is not currently tracked.',
                      style: _inter(size: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, color: _primary),
                      label: Text('Try Again',
                          style: _inter(size: 13, weight: FontWeight.w700, color: _primary)),
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
  final String driverName;
  final bool isRefreshing;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _TopBar({
    required this.driverName,
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: _onSurface),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_circle_rounded, color: _primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Tracking $driverName',
                          style: _manrope(size: 13, weight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22C55E)),
                    ),
                    const SizedBox(width: 5),
                    Text('LIVE',
                        style: _inter(size: 10, weight: FontWeight.w700, color: const Color(0xFF22C55E))),
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
                ),
                child: isRefreshing
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20, color: _onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Driver marker ────────────────────────────────────────────────────────────

class _DriverMarker extends StatelessWidget {
  final String driverName;
  final bool isStale;
  const _DriverMarker({required this.driverName, this.isStale = false});

  @override
  Widget build(BuildContext context) {
    final color = isStale ? _secondary : _primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Text(
            driverName,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        Icon(Icons.arrow_drop_down_rounded, color: color, size: 22),
      ],
    );
  }
}

// ─── Map button ───────────────────────────────────────────────────────────────

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MapBtn({required this.icon, required this.onTap, this.color = _onSurface});

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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ─── Bottom sheet ─────────────────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final String driverName;
  final _DriverStatus? status;
  final bool hasGps;
  final bool isStale;

  const _BottomSheet({
    required this.driverName,
    required this.status,
    required this.hasGps,
    required this.isStale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Row(
            children: [
              Expanded(
                child: Text(driverName,
                    style: _manrope(size: 18, weight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              _GpsStatusDot(hasGps: hasGps, isStale: isStale),
            ],
          ),
          const SizedBox(height: 16),
          if (hasGps)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (status?.speed != null)
                    _InfoChip(
                        icon: Icons.speed_rounded,
                        label: '${status!.speed!.toStringAsFixed(0)} km/h'),
                  if (status?.batteryLevel != null)
                    _InfoChip(
                        icon: Icons.battery_std_rounded,
                        label: '${status!.batteryLevel}%'),
                ].map((w) => Padding(padding: const EdgeInsets.only(right: 8), child: w)).toList(),
              ),
            ),
          if (status?.timestamp != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last updated: ${_relativeTime(status!.timestamp!)} (${_formatTime(status!.timestamp!)})',
              style: _inter(
                size: 11,
                weight: isStale ? FontWeight.w700 : FontWeight.w400,
                color: isStale ? const Color(0xFFBA1A1A) : _secondary,
              ),
            ),
          ],
          if (hasGps) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${status!.latitude},${status!.longitude}',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Open in Google Maps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _relativeTime(DateTime dt) {
    final age = DateTime.now().toUtc().difference(dt.toUtc());
    if (age.isNegative) return 'time mismatch';
    if (age.inSeconds < 60) return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }
}

class _GpsStatusDot extends StatelessWidget {
  final bool hasGps;
  final bool isStale;
  const _GpsStatusDot({required this.hasGps, this.isStale = false});

  @override
  Widget build(BuildContext context) {
    final label = !hasGps ? 'No Signal' : (isStale ? 'Stale' : 'GPS Active');
    final color = !hasGps
        ? const Color(0xFFE53935)
        : (isStale ? const Color(0xFF9E9E9E) : const Color(0xFF22C55E));
    final textColor = !hasGps
        ? const Color(0xFFBA1A1A)
        : (isStale ? const Color(0xFF616161) : const Color(0xFF2E7D32));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(label, style: _inter(size: 11, weight: FontWeight.w600, color: textColor)),
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
          Text(label, style: _inter(size: 12, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Parses GET /tracking/drivers/{id}/track-status — always 200, with a
/// specific `message` explaining *why* has_location is false (no app
/// account / tracking disabled / never shared a location) rather than one
/// generic "no location" state.
class _DriverStatus {
  final bool hasLocation;
  final String? message;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final int? batteryLevel;
  final DateTime? timestamp;

  const _DriverStatus({
    required this.hasLocation,
    this.message,
    this.latitude,
    this.longitude,
    this.speed,
    this.batteryLevel,
    this.timestamp,
  });

  factory _DriverStatus.fromJson(Map<String, dynamic> json) => _DriverStatus(
        hasLocation: json['has_location'] as bool? ?? false,
        message: json['message'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
        batteryLevel: json['battery_level'] as int?,
        timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'] as String) : null,
      );

  factory _DriverStatus.error() => const _DriverStatus(
        hasLocation: false,
        message: 'Could not load this driver\'s location. Tap refresh to try again.',
      );
}
