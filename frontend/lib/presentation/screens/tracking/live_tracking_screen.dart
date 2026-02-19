import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFFEC5B13);
  static const _success = Color(0xFF22C55E);
  static const _warning = Color(0xFFF59E0B);

  final _searchController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
  }

  void _centerOnFleet() {
    _mapController.move(const LatLng(19.0760, 72.8777), 13.5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(context),
          _buildMapControls(),
          _buildLiveBadge(),
          _buildBottomSheet(context),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(19.0760, 72.8777),
        initialZoom: 13.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fleet.management',
        ),
        MarkerLayer(
          markers: [
            // TRK-201 — Active (green)
            Marker(
              point: const LatLng(19.0820, 72.8877),
              width: 84,
              height: 72,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => _VehicleMarker(
                  label: 'TRK-201',
                  color: _success,
                  icon: Icons.turn_right_rounded,
                  pulse: true,
                  pulseAnim: _pulseAnimation,
                ),
              ),
            ),
            // VAN-402 — Warning (yellow)
            Marker(
              point: const LatLng(19.0900, 72.8977),
              width: 84,
              height: 72,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => _VehicleMarker(
                  label: 'VAN-402',
                  color: _warning,
                  icon: Icons.delivery_dining_outlined,
                  pulse: false,
                  pulseAnim: _pulseAnimation,
                ),
              ),
            ),
            // TRK-902 — Selected (orange)
            Marker(
              point: const LatLng(19.0700, 72.8700),
              width: 96,
              height: 80,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => _VehicleMarker(
                  label: 'TRK-902 (LIVE)',
                  color: _primary,
                  icon: Icons.local_shipping_rounded,
                  pulse: true,
                  pulseAnim: _pulseAnimation,
                  selected: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              // Row 1: back + search + filter
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12)
                        ],
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: Colors.grey.shade700, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12)
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.search, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search vehicles, drivers...',
                                hintStyle: TextStyle(fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          Icon(Icons.mic_none_rounded,
                              color: Colors.grey.shade400),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: _primary.withOpacity(0.4), blurRadius: 8)
                      ],
                    ),
                    child: const Icon(Icons.filter_list_rounded,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Row 2: status pill + quick-nav chips
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: _success, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('42 Active',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 8),
                            width: 1,
                            height: 12,
                            color: Colors.white24),
                        const Text('50 Total',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TopNavChip(
                    icon: Icons.local_shipping_outlined,
                    label: 'Fleet',
                    onTap: () => context.go('/fleet-hub'),
                  ),
                  const SizedBox(width: 6),
                  _TopNavChip(
                    icon: Icons.notifications_outlined,
                    label: 'Alerts',
                    badge: true,
                    onTap: () =>
                        context.push('/tracking/geofence-alerts'),
                  ),
                  const SizedBox(width: 6),
                  _TopNavChip(
                    icon: Icons.settings_outlined,
                    label: 'Setup',
                    onTap: () => context.push('/tracking/geofences'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      right: 70,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primary
                          .withOpacity(0.7 * (1 - _pulseAnimation.value)),
                      blurRadius: 6,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text('LIVE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          _MapControlBtn(icon: Icons.layers_outlined, onTap: () {}),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1), blurRadius: 6)
              ],
            ),
            child: Column(
              children: [
                _MapControlBtn(
                    icon: Icons.add_rounded,
                    onTap: _zoomIn,
                    borderBottom: true),
                _MapControlBtn(icon: Icons.remove_rounded, onTap: _zoomOut),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _MapControlBtn(
              icon: Icons.my_location_rounded,
              onTap: _centerOnFleet,
              color: _primary),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.12,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Vehicle header
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.local_shipping_rounded,
                            color: _primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TRK-902',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                        color: _success,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 5),
                                Text('Moving • Heavy Freight',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_horiz, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Driver card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                              color: Colors.grey, shape: BoxShape.circle),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Driver',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500)),
                              const Text('Marcus Richardson',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _DriverActionBtn(icon: Icons.call_rounded),
                            const SizedBox(width: 8),
                            _DriverActionBtn(icon: Icons.chat_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Telemetry grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.0,
                    children: [
                      _TelemetryCard(
                        label: 'Current Speed',
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text('64',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Text('km/h',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                      _TelemetryCard(
                        label: 'Heading',
                        child: const Row(
                          children: [
                            Icon(Icons.explore_outlined,
                                color: _primary, size: 20),
                            SizedBox(width: 6),
                            Text('NW 320°',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      _TelemetryCard(
                        label: 'Fuel Level',
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: const LinearProgressIndicator(
                                  value: 0.78,
                                  minHeight: 6,
                                  backgroundColor: Color(0xFFE5E7EB),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      _primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('78%',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      _TelemetryCard(
                        label: 'Battery',
                        child: const Row(
                          children: [
                            Icon(Icons.battery_charging_full_outlined,
                                color: _success, size: 20),
                            SizedBox(width: 6),
                            Text('12.8V',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push(
                              '/tracking/history/trk902',
                              extra: {'driverName': 'Marcus Richardson'}),
                          icon: const Icon(Icons.route_outlined, size: 18),
                          label: const Text('View History'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.assignment_outlined, size: 18),
                          label: const Text('Dispatch'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.grey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}

// ── Vehicle marker widget ─────────────────────────────────────────────────────

class _VehicleMarker extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool pulse;
  final Animation<double> pulseAnim;
  final bool selected;

  const _VehicleMarker({
    required this.label,
    required this.color,
    required this.icon,
    required this.pulse,
    required this.pulseAnim,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (pulse)
              Container(
                width: selected ? 56 : 46,
                height: selected ? 56 : 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2 * (1 - pulseAnim.value)),
                  shape: BoxShape.circle,
                ),
              ),
            Container(
              width: selected ? 40 : 36,
              height: selected ? 40 : 36,
              decoration: BoxDecoration(
                color: selected ? color : const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)
                ],
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : color, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: selected
                ? color
                : const Color(0xFF1E1E1E).withOpacity(0.85),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _MapControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool borderBottom;
  final Color? color;

  const _MapControlBtn({
    required this.icon,
    required this.onTap,
    this.borderBottom = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              borderBottom ? BorderRadius.zero : BorderRadius.circular(10),
          border: borderBottom
              ? const Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))
              : Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: borderBottom
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 6)
                ],
        ),
        child: Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
      ),
    );
  }
}

class _DriverActionBtn extends StatelessWidget {
  final IconData icon;
  const _DriverActionBtn({required this.icon});

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _primary, size: 16),
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _TelemetryCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _TopNavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool badge;
  final VoidCallback onTap;

  const _TopNavChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = false,
  });

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12), blurRadius: 6)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: _primary, size: 14),
                if (badge)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: _primary, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _primary)),
          ],
        ),
      ),
    );
  }
}
