import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fleet_management/providers/geofence_provider.dart';
import 'package:fleet_management/data/models/geofence_event.dart';

/// Geofence Management Screen
/// Shows geofence events and zone activity
class GeofenceManagementScreen extends ConsumerStatefulWidget {
  const GeofenceManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GeofenceManagementScreen> createState() =>
      _GeofenceManagementScreenState();
}

class _GeofenceManagementScreenState
    extends ConsumerState<GeofenceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedDriver;
  String? _selectedZone;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    ref.read(geofenceProvider.notifier).fetchEvents(
          driverId: _selectedDriver,
          zoneId: _selectedZone,
        );
  }

  @override
  Widget build(BuildContext context) {
    final geofenceState = ref.watch(geofenceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Events', icon: Icon(Icons.list)),
            Tab(text: 'By Zone', icon: Icon(Icons.location_on)),
            Tab(text: 'By Driver', icon: Icon(Icons.local_shipping)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: geofenceState.isLoading ? null : _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: geofenceState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : geofenceState.error != null
              ? _buildErrorWidget(geofenceState.error!)
              : geofenceState.events.isEmpty
                  ? _buildEmptyState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEventsList(geofenceState.events),
                        _buildEventsByZone(geofenceState.eventsByZone),
                        _buildEventsByDriver(geofenceState.eventsByDriver),
                      ],
                    ),
    );
  }

  /// Build events list
  Widget _buildEventsList(List<GeofenceEvent> events) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(geofenceProvider.notifier).refresh(
              driverId: _selectedDriver,
              zoneId: _selectedZone,
            );
      },
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  /// Build events grouped by zone
  Widget _buildEventsByZone(Map<String, List<GeofenceEvent>> eventsByZone) {
    final zones = eventsByZone.keys.toList();

    if (zones.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: zones.length,
      itemBuilder: (context, index) {
        final zoneName = zones[index];
        final events = eventsByZone[zoneName]!;

        return ExpansionTile(
          leading: const Icon(Icons.location_on, color: Colors.blue),
          title: Text(zoneName),
          subtitle: Text('${events.length} events'),
          children: events.map((event) => _buildEventCard(event)).toList(),
        );
      },
    );
  }

  /// Build events grouped by driver
  Widget _buildEventsByDriver(
      Map<String, List<GeofenceEvent>> eventsByDriver) {
    final drivers = eventsByDriver.keys.toList();

    if (drivers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driverName = drivers[index];
        final events = eventsByDriver[driverName]!;

        return ExpansionTile(
          leading: const Icon(Icons.local_shipping, color: Colors.green),
          title: Text(driverName),
          subtitle: Text('${events.length} events'),
          children: events.map((event) => _buildEventCard(event)).toList(),
        );
      },
    );
  }

  /// Build event card
  Widget _buildEventCard(GeofenceEvent event) {
    final timeFormatter = DateFormat('MMM d, HH:mm:ss');
    final isEnter = event.isEnter;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEnter ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isEnter ? Icons.login : Icons.logout,
            color: isEnter ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          event.driverName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.zoneName,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  timeFormatter.format(event.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            isEnter ? 'ENTER' : 'EXIT',
            style: TextStyle(
              color: isEnter ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          backgroundColor:
              isEnter ? Colors.green.shade50 : Colors.red.shade50,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error loading events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadEvents,
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
          const Text(
            'No geofence events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Geofence events will appear here when drivers\nenter or exit defined zones',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Show filter dialog
  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Events'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter by driver or zone\n(Feature in development)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // TODO: Add driver and zone selection dropdowns
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('All Drivers'),
              subtitle: const Text('Coming soon'),
              enabled: false,
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('All Zones'),
              subtitle: const Text('Coming soon'),
              enabled: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
