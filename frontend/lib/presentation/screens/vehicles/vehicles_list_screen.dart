import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VehiclesListScreen extends ConsumerStatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  ConsumerState<VehiclesListScreen> createState() =>
      _VehiclesListScreenState();
}

class _VehiclesListScreenState extends ConsumerState<VehiclesListScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual data from provider
    final isLoading = false;
    final vehicles = _getMockVehicles();

    return Column(
      children: [
        // Header with search and filters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search vehicles...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      count: vehicles.length,
                      isSelected: _selectedFilter == 'all',
                      onTap: () => setState(() => _selectedFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Active',
                      count: 3,
                      isSelected: _selectedFilter == 'active',
                      onTap: () => setState(() => _selectedFilter = 'active'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Maintenance',
                      count: 2,
                      isSelected: _selectedFilter == 'maintenance',
                      onTap: () => setState(() => _selectedFilter = 'maintenance'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Inactive',
                      count: 0,
                      isSelected: _selectedFilter == 'inactive',
                      onTap: () => setState(() => _selectedFilter = 'inactive'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Vehicle list
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : vehicles.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = vehicles[index];
                        return _VehicleCard(
                          vehicle: vehicle,
                          onTap: () => context.push('/vehicles/${vehicle['id']}'),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getMockVehicles() {
    // TODO: Replace with actual data from provider
    return [
      {
        'id': '1',
        'registration': 'DL01AB1234',
        'make': 'Tata',
        'model': 'Ace',
        'year': 2022,
        'type': 'Truck',
        'status': 'Active',
        'driver': 'John Doe',
        'mileage': 15000.0,
        'fuelType': 'Diesel',
      },
      {
        'id': '2',
        'registration': 'MH02CD5678',
        'make': 'Mahindra',
        'model': 'Bolero',
        'year': 2021,
        'type': 'SUV',
        'status': 'Active',
        'driver': 'Jane Smith',
        'mileage': 25000.0,
        'fuelType': 'Diesel',
      },
      {
        'id': '3',
        'registration': 'KA03EF9012',
        'make': 'Maruti',
        'model': 'Swift',
        'year': 2023,
        'type': 'Car',
        'status': 'Active',
        'driver': null,
        'mileage': 5000.0,
        'fuelType': 'Petrol',
      },
      {
        'id': '4',
        'registration': 'TN04GH3456',
        'make': 'Ashok Leyland',
        'model': 'Dost',
        'year': 2020,
        'type': 'Truck',
        'status': 'Maintenance',
        'driver': null,
        'mileage': 50000.0,
        'fuelType': 'Diesel',
      },
      {
        'id': '5',
        'registration': 'UP05IJ7890',
        'make': 'Force',
        'model': 'Traveller',
        'year': 2022,
        'type': 'Van',
        'status': 'Maintenance',
        'driver': 'Bob Johnson',
        'mileage': 30000.0,
        'fuelType': 'Diesel',
      },
    ];
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade300,
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = vehicle['status'] as String;
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with registration and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle['registration'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vehicle['make']} ${vehicle['model']} (${vehicle['year']})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Details
              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.category_outlined,
                      label: vehicle['type'] as String,
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.local_gas_station_outlined,
                      label: vehicle['fuelType'] as String,
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.speed,
                      label: '${vehicle['mileage']} km',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Driver info
              if (vehicle['driver'] != null) ...[
                const Divider(),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      vehicle['driver'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Divider(),
                Row(
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No driver assigned',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Vehicles Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first vehicle to get started',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/vehicles/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }
}
