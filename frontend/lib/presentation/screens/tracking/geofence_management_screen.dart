import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

enum _DrawingMode { none, polygon, circle }

class GeofenceManagementScreen extends StatefulWidget {
  const GeofenceManagementScreen({super.key});

  @override
  State<GeofenceManagementScreen> createState() =>
      _GeofenceManagementScreenState();
}

class _GeofenceManagementScreenState extends State<GeofenceManagementScreen> {
  static const _primary = Color(0xFFEC5B13);

  final _nameController = TextEditingController(text: 'Downtown Logistics Hub');
  final _descController = TextEditingController();
  bool _onEntrance = true;
  bool _onExit = true;

  _DrawingMode _drawingMode = _DrawingMode.polygon;
  final _mapController = MapController();

  // Initial polygon points around Mumbai
  final List<LatLng> _polygonPoints = [
    const LatLng(19.0810, 72.8850),
    const LatLng(19.0850, 72.8920),
    const LatLng(19.0790, 72.8960),
    const LatLng(19.0750, 72.8890),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleMapTap(TapPosition _, LatLng point) {
    if (_drawingMode == _DrawingMode.polygon) {
      setState(() => _polygonPoints.add(point));
    }
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() => _polygonPoints.removeLast());
    }
  }

  void _resetAll() {
    setState(() {
      _polygonPoints.clear();
      _nameController.clear();
      _descController.clear();
      _onEntrance = true;
      _onExit = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(context),
          _buildDrawingTools(),
          _buildFloatingSearch(),
          if (_drawingMode == _DrawingMode.polygon && _polygonPoints.isNotEmpty)
            _buildUndoButton(),
          _buildBottomSheet(context),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(19.0800, 72.8900),
        initialZoom: 14.5,
        onTap: _handleMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fleet.management',
        ),
        // Filled polygon overlay
        if (_polygonPoints.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: _polygonPoints,
                color: _primary.withOpacity(0.22),
                borderColor: _primary,
                borderStrokeWidth: 2.5,
              ),
            ],
          ),
        // Corner point markers
        if (_polygonPoints.isNotEmpty)
          MarkerLayer(
            markers: _polygonPoints
                .map(
                  (pt) => Marker(
                    point: pt,
                    width: 16,
                    height: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: _primary.withOpacity(0.3),
                              blurRadius: 4)
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white.withOpacity(0.92),
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + 8, 16, 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Create Geofence',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: _resetAll,
              child: const Text('Reset',
                  style: TextStyle(
                      color: _primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSearch() {
    final topOffset = MediaQuery.of(context).padding.top + 70;
    return Positioned(
      top: topOffset,
      left: 16,
      right: 72,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, color: Colors.grey.shade400, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search address or coordinates...',
                  hintStyle: TextStyle(fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingTools() {
    final topOffset = MediaQuery.of(context).padding.top + 70;
    return Positioned(
      top: topOffset,
      right: 16,
      child: Column(
        children: [
          _DrawToolBtn(
            icon: Icons.radio_button_unchecked_rounded,
            active: _drawingMode == _DrawingMode.circle,
            onTap: () => setState(
                () => _drawingMode = _DrawingMode.circle),
          ),
          const SizedBox(height: 8),
          _DrawToolBtn(
            icon: Icons.polyline_outlined,
            active: _drawingMode == _DrawingMode.polygon,
            onTap: () => setState(
                () => _drawingMode = _DrawingMode.polygon),
          ),
          const SizedBox(height: 8),
          _DrawToolBtn(
            icon: Icons.layers_outlined,
            active: false,
            onTap: () {},
          ),
          Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              width: 28,
              height: 1,
              color: Colors.grey.shade300),
          _DrawToolBtn(
            icon: Icons.my_location_rounded,
            active: false,
            onTap: () => _mapController.move(
                const LatLng(19.0800, 72.8900), 14.5),
          ),
        ],
      ),
    );
  }

  Widget _buildUndoButton() {
    final topOffset = MediaQuery.of(context).padding.top + 170;
    return Positioned(
      top: topOffset,
      right: 16,
      child: GestureDetector(
        onTap: _undoLastPoint,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)
            ],
          ),
          child: Icon(Icons.undo_rounded,
              color: Colors.grey.shade600, size: 20),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.12,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -4))
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                // Drawing mode hint
                if (_drawingMode == _DrawingMode.polygon)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded,
                            color: _primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap on the map to add polygon points'
                            ' (${_polygonPoints.length} added)',
                            style: const TextStyle(
                                fontSize: 12,
                                color: _primary,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildSectionLabel('Geofence Details'),
                const SizedBox(height: 12),
                _buildInputField('Name', _nameController),
                const SizedBox(height: 12),
                _buildInputField(
                    'Description (Optional)', _descController,
                    hint: 'Enter purpose of this zone...', maxLines: 2),
                const SizedBox(height: 20),
                _buildSectionLabel('Notification Triggers'),
                const SizedBox(height: 12),
                _buildTriggerRow(
                    icon: Icons.login_rounded,
                    label: 'On Entrance',
                    value: _onEntrance,
                    onChanged: (v) => setState(() => _onEntrance = v)),
                const SizedBox(height: 8),
                _buildTriggerRow(
                    icon: Icons.logout_rounded,
                    label: 'On Exit',
                    value: _onExit,
                    onChanged: (v) => setState(() => _onExit = v)),
                const SizedBox(height: 20),
                _buildSectionLabel('Apply To'),
                const SizedBox(height: 12),
                _buildFleetSelector(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Cancel',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_polygonPoints.length < 3) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Draw at least 3 points on the map'),
                                  backgroundColor: Color(0xFFF59E0B)),
                            );
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Geofence saved!'),
                                backgroundColor: Color(0xFF22C55E)),
                          );
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Save Geofence'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade500,
          letterSpacing: 1.0),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl,
      {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: value ? _primary.withOpacity(0.3) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: _primary,
          ),
        ],
      ),
    );
  }

  Widget _buildFleetSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined,
              color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('West Coast Fleet (12 Vehicles)',
                style: TextStyle(fontSize: 13)),
          ),
          Icon(Icons.expand_more, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

// ── Drawing toolbar button ────────────────────────────────────────────────────

class _DrawToolBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _DrawToolBtn(
      {required this.icon, required this.active, required this.onTap});

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: active ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _primary : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)
          ],
        ),
        child: Icon(icon,
            color: active ? Colors.white : Colors.grey.shade600, size: 20),
      ),
    );
  }
}
