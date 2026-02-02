import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fleet_management/providers/live_tracking_provider.dart';
import 'package:fleet_management/data/models/driver_location.dart';

/// Live Tracking Screen
/// Shows real-time locations of all drivers on a map
class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  bool _showDriverList = false;

  @override
  void initState() {
    super.initState();
    // Fetch initial locations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveTrackingProvider.notifier).fetchLiveLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(liveTrackingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          // Auto-refresh toggle
          IconButton(
            icon: Icon(
              trackingState.autoRefresh
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
            ),
            onPressed: () {
              ref.read(liveTrackingProvider.notifier).toggleAutoRefresh();
            },
            tooltip: trackingState.autoRefresh
                ? 'Pause auto-refresh'
                : 'Start auto-refresh',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: trackingState.isLoading
                ? null
                : () {
                    ref.read(liveTrackingProvider.notifier).fetchLiveLocations();
                  },
            tooltip: 'Refresh',
          ),
          // Driver list toggle
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              setState(() {
                _showDriverList = !_showDriverList;
              });
            },
            tooltip: 'Driver list',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(20.5937, 78.9629), // India center
              zoom: 5.0,
              maxZoom: 18.0,
              minZoom: 3.0,
              onTap: (_, __) {
                // Clear selection on map tap
                ref.read(liveTrackingProvider.notifier).clearSelection();
              },
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fleet_management.app',
                maxZoom: 19,
              ),
              // Driver markers
              if (trackingState.locations.isNotEmpty)
                MarkerLayer(
                  markers: trackingState.locations.map((location) {
                    return Marker(
                      point: LatLng(location.latitude, location.longitude),
                      width: 50,
                      height: 50,
                      child: _buildDriverMarker(
                        location,
                        isSelected: trackingState.selectedDriver?.driverId ==
                            location.driverId,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Loading indicator
          if (trackingState.isLoading)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Updating locations...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Status summary card
          Positioned(
            top: 16,
            right: 16,
            child: _buildStatusSummary(trackingState),
          ),

          // Selected driver info card
          if (trackingState.selectedDriver != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildDriverInfoCard(trackingState.selectedDriver!),
            ),

          // Driver list bottom sheet
          if (_showDriverList)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildDriverList(trackingState),
            ),

          // Error snackbar
          if (trackingState.error != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          trackingState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          ref.read(liveTrackingProvider.notifier).clearError();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Center on all drivers
          if (trackingState.locations.isNotEmpty)
            FloatingActionButton(
              heroTag: 'fit_bounds',
              onPressed: () => _fitBoundsToAllDrivers(trackingState.locations),
              tooltip: 'Fit to all drivers',
              child: const Icon(Icons.center_focus_strong),
            ),
          const SizedBox(height: 12),
          // Zoom in
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: () {
              _mapController.move(
                _mapController.center,
                _mapController.zoom + 1,
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          // Zoom out
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: () {
              _mapController.move(
                _mapController.center,
                _mapController.zoom - 1,
              );
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  /// Build driver marker
  Widget _buildDriverMarker(LiveLocation location, {bool isSelected = false}) {
    Color markerColor;
    IconData icon;

    // Determine color and icon based on status
    switch (location.status) {
      case LocationStatus.active:
        markerColor = Colors.green;
        icon = Icons.local_shipping;
        break;
      case LocationStatus.idle:
        markerColor = Colors.orange;
        icon = Icons.local_shipping;
        break;
      case LocationStatus.offline:
        markerColor = Colors.red;
        icon = Icons.local_shipping;
        break;
    }

    return GestureDetector(
      onTap: () {
        ref.read(liveTrackingProvider.notifier).selectDriver(location.driverId);
        // Center map on selected driver
        _mapController.move(
          LatLng(location.latitude, location.longitude),
          15.0,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle (selection indicator)
          if (isSelected)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.3),
                border: Border.all(color: Colors.blue, width: 2),
              ),
            ),
          // Marker circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Build status summary card
  Widget _buildStatusSummary(LiveTrackingState state) {
    final counts = state.statusCounts;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Drivers: ${state.totalDrivers}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Active',
              counts[LocationStatus.active] ?? 0,
              Colors.green,
            ),
            _buildStatusRow(
              'Idle',
              counts[LocationStatus.idle] ?? 0,
              Colors.orange,
            ),
            _buildStatusRow(
              'Offline',
              counts[LocationStatus.offline] ?? 0,
              Colors.red,
            ),
            if (state.lastRefresh != null) ...[
              const Divider(),
              Text(
                'Updated: ${_formatTime(state.lastRefresh!)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build status row
  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('$label: $count', style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  /// Build driver info card
  Widget _buildDriverInfoCard(LiveLocation driver) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    driver.driverName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(liveTrackingProvider.notifier).clearSelection();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.speed,
              'Speed',
              driver.speed != null
                  ? '${(driver.speed! * 3.6).toStringAsFixed(1)} km/h'
                  : 'N/A',
            ),
            _buildInfoRow(
              Icons.navigation,
              'Heading',
              driver.heading != null
                  ? '${driver.heading!.toStringAsFixed(0)}°'
                  : 'N/A',
            ),
            _buildInfoRow(
              Icons.battery_std,
              'Battery',
              driver.batteryLevel != null
                  ? '${driver.batteryLevel}%'
                  : 'N/A',
            ),
            _buildInfoRow(
              Icons.access_time,
              'Last Update',
              '${driver.minutesSinceUpdate} min ago',
            ),
          ],
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Build driver list bottom sheet
  Widget _buildDriverList(LiveTrackingState state) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'All Drivers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showDriverList = false;
                    });
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Driver list
          Expanded(
            child: ListView.builder(
              itemCount: state.locations.length,
              itemBuilder: (context, index) {
                final driver = state.locations[index];
                return ListTile(
                  leading: Icon(
                    Icons.local_shipping,
                    color: driver.status == LocationStatus.active
                        ? Colors.green
                        : driver.status == LocationStatus.idle
                            ? Colors.orange
                            : Colors.red,
                  ),
                  title: Text(driver.driverName),
                  subtitle: Text(
                    '${driver.minutesSinceUpdate} min ago',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: driver.speed != null
                      ? Text(
                          '${(driver.speed! * 3.6).toStringAsFixed(0)} km/h',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(liveTrackingProvider.notifier)
                        .selectDriver(driver.driverId);
                    _mapController.move(
                      LatLng(driver.latitude, driver.longitude),
                      15.0,
                    );
                    setState(() {
                      _showDriverList = false;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Fit map bounds to show all drivers
  void _fitBoundsToAllDrivers(List<LiveLocation> locations) {
    if (locations.isEmpty) return;

    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final location in locations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
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

  /// Format time
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
