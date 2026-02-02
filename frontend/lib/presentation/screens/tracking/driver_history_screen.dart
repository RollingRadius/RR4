import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:fleet_management/data/models/driver_location.dart';
import 'package:fleet_management/data/services/tracking_api.dart';
import 'package:fleet_management/providers/location_tracking_provider.dart';

/// Driver History Screen
/// Shows historical location data with route visualization
class DriverHistoryScreen extends ConsumerStatefulWidget {
  final String driverId;
  final String driverName;

  const DriverHistoryScreen({
    Key? key,
    required this.driverId,
    required this.driverName,
  }) : super(key: key);

  @override
  ConsumerState<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends ConsumerState<DriverHistoryScreen> {
  final MapController _mapController = MapController();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _endDate = DateTime.now();

  List<DriverLocation> _locations = [];
  bool _isLoading = false;
  String? _error;

  bool _showTimeline = true;
  int? _selectedLocationIndex;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location History'),
            Text(
              widget.driverName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
            tooltip: 'Select date range',
          ),
          IconButton(
            icon: Icon(_showTimeline ? Icons.map : Icons.timeline),
            onPressed: () {
              setState(() {
                _showTimeline = !_showTimeline;
              });
            },
            tooltip: _showTimeline ? 'Show map only' : 'Show timeline',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range display
          _buildDateRangeBar(),

          // Statistics card
          if (_locations.isNotEmpty) _buildStatisticsCard(),

          // Map and timeline
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _locations.isEmpty
                        ? _buildEmptyState()
                        : _showTimeline
                            ? _buildMapWithTimeline()
                            : _buildMapOnly(),
          ),
        ],
      ),
    );
  }

  /// Build date range bar
  Widget _buildDateRangeBar() {
    final formatter = DateFormat('MMM d, HH:mm');

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${formatter.format(_startDate)} - ${formatter.format(_endDate)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (_locations.isNotEmpty)
            Text(
              '${_locations.length} points',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
        ],
      ),
    );
  }

  /// Build statistics card
  Widget _buildStatisticsCard() {
    final stats = _calculateStatistics();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.route,
              label: 'Distance',
              value: '${stats['distance']?.toStringAsFixed(1)} km',
            ),
            _buildStatItem(
              icon: Icons.access_time,
              label: 'Duration',
              value: stats['duration'] ?? 'N/A',
            ),
            _buildStatItem(
              icon: Icons.speed,
              label: 'Avg Speed',
              value: '${stats['avgSpeed']?.toStringAsFixed(0)} km/h',
            ),
            _buildStatItem(
              icon: Icons.pause_circle,
              label: 'Stops',
              value: '${stats['stops']}',
            ),
          ],
        ),
      ),
    );
  }

  /// Build stat item
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
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
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// Build map with timeline
  Widget _buildMapWithTimeline() {
    return Row(
      children: [
        // Map
        Expanded(
          flex: 2,
          child: _buildMap(),
        ),

        // Timeline
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Text(
                      'Timeline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_locations.length}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final location = _locations[index];
                    final isSelected = _selectedLocationIndex == index;

                    return _buildTimelineItem(
                      location,
                      index,
                      isSelected,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build map only
  Widget _buildMapOnly() {
    return _buildMap();
  }

  /// Build map
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _locations.isNotEmpty
            ? LatLng(
                _locations.first.latitude,
                _locations.first.longitude,
              )
            : LatLng(20.5937, 78.9629),
        zoom: 13.0,
      ),
      children: [
        // OpenStreetMap tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fleet_management.app',
        ),

        // Route polyline
        if (_locations.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _locations
                    .map((loc) => LatLng(loc.latitude, loc.longitude))
                    .toList(),
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),

        // Start marker
        if (_locations.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  _locations.first.latitude,
                  _locations.first.longitude,
                ),
                width: 40,
                height: 40,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              // End marker
              Marker(
                point: LatLng(
                  _locations.last.latitude,
                  _locations.last.longitude,
                ),
                width: 40,
                height: 40,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              // Selected location marker
              if (_selectedLocationIndex != null)
                Marker(
                  point: LatLng(
                    _locations[_selectedLocationIndex!].latitude,
                    _locations[_selectedLocationIndex!].longitude,
                  ),
                  width: 50,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// Build timeline item
  Widget _buildTimelineItem(
    DriverLocation location,
    int index,
    bool isSelected,
  ) {
    final timeFormatter = DateFormat('HH:mm:ss');
    final speed = location.speed != null
        ? (location.speed! * 3.6).toStringAsFixed(0)
        : 'N/A';

    return InkWell(
      onTap: () {
        setState(() {
          _selectedLocationIndex = index;
        });
        _mapController.move(
          LatLng(location.latitude, location.longitude),
          16.0,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 3 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Time indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == 0
                    ? Colors.green
                    : index == _locations.length - 1
                        ? Colors.red
                        : Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeFormatter.format(location.timestamp),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.speed, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '$speed km/h',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (location.accuracy != null) ...[
                        Icon(Icons.gps_fixed,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${location.accuracy!.toStringAsFixed(0)}m',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow indicator
            if (isSelected)
              const Icon(Icons.chevron_right, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading history',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No location data',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'No location history found for the selected date range',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showDateRangePicker,
            icon: const Icon(Icons.date_range),
            label: const Text('Change Date Range'),
          ),
        ],
      ),
    );
  }

  /// Load history from API
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedLocationIndex = null;
    });

    try {
      final trackingApi = ref.read(trackingApiProvider);
      final response = await trackingApi.getDriverHistory(
        driverId: widget.driverId,
        startTime: _startDate,
        endTime: _endDate,
        pageSize: 500, // Load more points for better route visualization
      );

      setState(() {
        _locations = response.locations.reversed.toList(); // Oldest to newest
        _isLoading = false;
      });

      // Fit bounds to route
      if (_locations.isNotEmpty) {
        _fitBoundsToRoute();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// Show date range picker
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadHistory();
    }
  }

  /// Calculate statistics
  Map<String, dynamic> _calculateStatistics() {
    if (_locations.length < 2) {
      return {
        'distance': 0.0,
        'duration': 'N/A',
        'avgSpeed': 0.0,
        'stops': 0,
      };
    }

    final distance = Distance();
    double totalDistance = 0.0;
    int stops = 0;

    for (int i = 1; i < _locations.length; i++) {
      final prev = _locations[i - 1];
      final curr = _locations[i];

      // Calculate distance
      final dist = distance.as(
        LengthUnit.Kilometer,
        LatLng(prev.latitude, prev.longitude),
        LatLng(curr.latitude, curr.longitude),
      );
      totalDistance += dist;

      // Detect stops (speed < 1 km/h for more than 5 minutes)
      if (curr.speed != null && curr.speed! * 3.6 < 1) {
        final timeDiff = curr.timestamp.difference(prev.timestamp);
        if (timeDiff.inMinutes >= 5) {
          stops++;
        }
      }
    }

    // Calculate duration
    final duration = _endDate.difference(_startDate);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    // Calculate average speed
    final avgSpeed = duration.inSeconds > 0
        ? (totalDistance / duration.inHours)
        : 0.0;

    return {
      'distance': totalDistance,
      'duration': durationStr,
      'avgSpeed': avgSpeed,
      'stops': stops,
    };
  }

  /// Fit map bounds to route
  void _fitBoundsToRoute() {
    if (_locations.isEmpty) return;

    double minLat = _locations.first.latitude;
    double maxLat = _locations.first.latitude;
    double minLng = _locations.first.longitude;
    double maxLng = _locations.first.longitude;

    for (final location in _locations) {
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
}
