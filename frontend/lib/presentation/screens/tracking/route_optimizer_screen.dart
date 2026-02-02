import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fleet_management/data/models/route_optimization.dart';
import 'package:fleet_management/data/services/tracking_api.dart';
import 'package:fleet_management/providers/location_tracking_provider.dart';

/// Route Optimizer Screen
/// Allows creating and optimizing routes with multiple waypoints
class RouteOptimizerScreen extends ConsumerStatefulWidget {
  const RouteOptimizerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RouteOptimizerScreen> createState() =>
      _RouteOptimizerScreenState();
}

class _RouteOptimizerScreenState extends ConsumerState<RouteOptimizerScreen> {
  final MapController _mapController = MapController();
  final List<Waypoint> _waypoints = [];
  final TextEditingController _routeNameController = TextEditingController();

  RouteOptimizeResponse? _optimizedRoute;
  bool _isOptimizing = false;
  String? _error;

  @override
  void dispose() {
    _routeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Optimizer'),
        actions: [
          if (_waypoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearWaypoints,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            child: Stack(
              children: [
                _buildMap(),

                // Waypoint count badge
                if (_waypoints.isNotEmpty)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          '${_waypoints.length} waypoints',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                // Optimized route info
                if (_optimizedRoute != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildOptimizedRouteCard(),
                  ),

                // Error message
                if (_error != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.red.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _error = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom panel
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waypoints list
                if (_waypoints.isNotEmpty) _buildWaypointsList(),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showAddWaypointDialog,
                          icon: const Icon(Icons.add_location),
                          label: const Text('Add Waypoint'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _waypoints.length >= 2 && !_isOptimizing
                              ? _optimizeRoute
                              : null,
                          icon: _isOptimizing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.route),
                          label: Text(
                            _isOptimizing ? 'Optimizing...' : 'Optimize',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Save button (if optimized)
                if (_optimizedRoute != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveRoute,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Route'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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

  /// Build map
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(20.5937, 78.9629),
        zoom: 5.0,
        onTap: (_, latLng) {
          _addWaypointFromMap(latLng);
        },
      ),
      children: [
        // OpenStreetMap tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fleet_management.app',
        ),

        // Route polyline (optimized)
        if (_optimizedRoute != null &&
            _optimizedRoute!.optimizedWaypoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _optimizedRoute!.optimizedWaypoints
                    .map((wp) => LatLng(wp.lat, wp.lng))
                    .toList(),
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),

        // Waypoint markers
        if (_waypoints.isNotEmpty)
          MarkerLayer(
            markers: _waypoints.asMap().entries.map((entry) {
              final index = entry.key;
              final waypoint = entry.value;
              final isOptimized = _optimizedRoute != null;

              return Marker(
                point: LatLng(waypoint.lat, waypoint.lng),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _editWaypoint(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isOptimized ? Colors.blue : Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        isOptimized
                            ? '${waypoint.order! + 1}'
                            : '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Build waypoints list
  Widget _buildWaypointsList() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _waypoints.length,
        onReorder: _reorderWaypoints,
        itemBuilder: (context, index) {
          final waypoint = _waypoints[index];
          return _buildWaypointChip(waypoint, index, key: ValueKey(index));
        },
      ),
    );
  }

  /// Build waypoint chip
  Widget _buildWaypointChip(Waypoint waypoint, int index, {required Key key}) {
    return Container(
      key: key,
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => _removeWaypoint(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                waypoint.address ?? 'Waypoint $index',
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build optimized route card
  Widget _buildOptimizedRouteCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Optimized Route',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRouteStatItem(
                  Icons.route,
                  'Distance',
                  '${_optimizedRoute!.totalDistance.toStringAsFixed(1)} km',
                ),
                _buildRouteStatItem(
                  Icons.access_time,
                  'Duration',
                  '${_optimizedRoute!.estimatedDuration} min',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build route stat item
  Widget _buildRouteStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Add waypoint from map tap
  void _addWaypointFromMap(LatLng latLng) {
    if (_waypoints.length >= 25) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 25 waypoints allowed')),
      );
      return;
    }

    setState(() {
      _waypoints.add(Waypoint(
        lat: latLng.latitude,
        lng: latLng.longitude,
        address: 'Waypoint ${_waypoints.length + 1}',
      ));
      _optimizedRoute = null; // Clear previous optimization
      _error = null;
    });
  }

  /// Show add waypoint dialog
  Future<void> _showAddWaypointDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Waypoint'),
        content: const Text(
          'Tap on the map to add waypoints, or use the search feature (coming soon)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Edit waypoint
  void _editWaypoint(int index) {
    // TODO: Show edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit waypoint ${index + 1} (coming soon)')),
    );
  }

  /// Remove waypoint
  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
      _optimizedRoute = null;
      _error = null;
    });
  }

  /// Reorder waypoints
  void _reorderWaypoints(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final waypoint = _waypoints.removeAt(oldIndex);
      _waypoints.insert(newIndex, waypoint);
      _optimizedRoute = null; // Clear optimization on manual reorder
      _error = null;
    });
  }

  /// Clear all waypoints
  void _clearWaypoints() {
    setState(() {
      _waypoints.clear();
      _optimizedRoute = null;
      _error = null;
    });
  }

  /// Optimize route using OSRM
  Future<void> _optimizeRoute() async {
    if (_waypoints.length < 2) {
      return;
    }

    setState(() {
      _isOptimizing = true;
      _error = null;
    });

    try {
      final trackingApi = ref.read(trackingApiProvider);
      final result = await trackingApi.optimizeRoute(_waypoints);

      setState(() {
        _optimizedRoute = result;
        _isOptimizing = false;

        // Update waypoints with optimized order
        _waypoints.clear();
        _waypoints.addAll(result.optimizedWaypoints);
      });

      // Fit bounds to optimized route
      _fitBoundsToRoute();
    } catch (e) {
      setState(() {
        _isOptimizing = false;
        _error = 'Failed to optimize route: ${e.toString()}';
      });
    }
  }

  /// Save route
  Future<void> _saveRoute() async {
    if (_optimizedRoute == null) return;

    // Show name input dialog
    final name = await _showSaveDialog();
    if (name == null || name.isEmpty) return;

    try {
      final trackingApi = ref.read(trackingApiProvider);
      final routeCreate = RouteCreate(
        name: name,
        waypoints: _optimizedRoute!.optimizedWaypoints,
        optimizedRoute: _optimizedRoute!.optimizedWaypoints,
        totalDistance: _optimizedRoute!.totalDistance,
        estimatedDuration: _optimizedRoute!.estimatedDuration,
        status: 'active',
      );

      await trackingApi.createRoute(routeCreate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save route: ${e.toString()}')),
        );
      }
    }
  }

  /// Show save dialog
  Future<String?> _showSaveDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Route'),
        content: TextField(
          controller: _routeNameController,
          decoration: const InputDecoration(
            labelText: 'Route Name',
            hintText: 'Enter a name for this route',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _routeNameController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Fit bounds to route
  void _fitBoundsToRoute() {
    if (_waypoints.isEmpty) return;

    double minLat = _waypoints.first.lat;
    double maxLat = _waypoints.first.lat;
    double minLng = _waypoints.first.lng;
    double maxLng = _waypoints.first.lng;

    for (final waypoint in _waypoints) {
      if (waypoint.lat < minLat) minLat = waypoint.lat;
      if (waypoint.lat > maxLat) maxLat = waypoint.lat;
      if (waypoint.lng < minLng) minLng = waypoint.lng;
      if (waypoint.lng > maxLng) maxLng = waypoint.lng;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
    );
  }
}
