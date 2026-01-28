import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/driver_provider.dart';
import 'package:fleet_management/data/models/driver_model.dart';

class DriversListScreen extends ConsumerStatefulWidget {
  const DriversListScreen({super.key});

  @override
  ConsumerState<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends ConsumerState<DriversListScreen> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Load drivers on screen init
    Future.microtask(() => ref.read(driverProvider.notifier).loadDrivers());
  }

  Future<void> _refreshDrivers() async {
    await ref.read(driverProvider.notifier).loadDrivers(status: _selectedStatus);
  }

  void _filterByStatus(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    ref.read(driverProvider.notifier).loadDrivers(status: status);
  }

  void _showDeleteConfirmation(BuildContext context, DriverModel driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text(
          'Are you sure you want to delete ${driver.fullName}? This will set their status to terminated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(driverProvider.notifier).deleteDriver(driver.driverId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${driver.fullName} deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'on_leave':
        return Colors.blue;
      case 'terminated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'inactive':
        return Icons.pause_circle;
      case 'on_leave':
        return Icons.beach_access;
      case 'terminated':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDrivers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedStatus == null,
                    onSelected: (_) => _filterByStatus(null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Active'),
                    selected: _selectedStatus == 'active',
                    onSelected: (_) => _filterByStatus('active'),
                    avatar: const Icon(Icons.check_circle, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Inactive'),
                    selected: _selectedStatus == 'inactive',
                    onSelected: (_) => _filterByStatus('inactive'),
                    avatar: const Icon(Icons.pause_circle, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('On Leave'),
                    selected: _selectedStatus == 'on_leave',
                    onSelected: (_) => _filterByStatus('on_leave'),
                    avatar: const Icon(Icons.beach_access, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Terminated'),
                    selected: _selectedStatus == 'terminated',
                    onSelected: (_) => _filterByStatus('terminated'),
                    avatar: const Icon(Icons.cancel, size: 18),
                  ),
                ],
              ),
            ),
          ),

          // Statistics Bar
          if (driverState.drivers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatisticCard(
                    label: 'Total',
                    value: driverState.total.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _StatisticCard(
                    label: 'Active',
                    value: driverState.drivers.where((d) => d.isActive).length.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  _StatisticCard(
                    label: 'Expiring Soon',
                    value: driverState.drivers.where((d) => d.hasExpiringSoonLicense).length.toString(),
                    icon: Icons.warning,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Drivers List
          Expanded(
            child: driverState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : driverState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: ${driverState.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshDrivers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : driverState.drivers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_off_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No drivers found',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first driver to get started',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => context.push('/drivers/add'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Driver'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshDrivers,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: driverState.drivers.length,
                              itemBuilder: (context, index) {
                                final driver = driverState.drivers[index];
                                return _DriverCard(
                                  driver: driver,
                                  onTap: () {
                                    // Navigate to driver details (to be implemented)
                                    ref.read(driverProvider.notifier).selectDriver(driver);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Selected ${driver.fullName}')),
                                    );
                                  },
                                  onDelete: () => _showDeleteConfirmation(context, driver),
                                  getStatusColor: _getStatusColor,
                                  getStatusIcon: _getStatusIcon,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/drivers/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Driver'),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatisticCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color Function(String) getStatusColor;
  final IconData Function(String) getStatusIcon;

  const _DriverCard({
    required this.driver,
    required this.onTap,
    required this.onDelete,
    required this.getStatusColor,
    required this.getStatusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final hasLicenseWarning = driver.hasExpiredLicense || driver.hasExpiringSoonLicense;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: getStatusColor(driver.status).withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: getStatusColor(driver.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'ID: ${driver.employeeId}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(driver.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getStatusIcon(driver.status),
                          size: 16,
                          color: getStatusColor(driver.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          driver.statusDisplay,
                          style: TextStyle(
                            color: getStatusColor(driver.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Contact Information
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(driver.phone),
                  if (driver.email != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        driver.email!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // License Information
              if (driver.license != null) ...[
                const Divider(),
                Row(
                  children: [
                    Icon(
                      Icons.card_membership,
                      size: 16,
                      color: hasLicenseWarning ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${driver.license!.licenseType} - ${driver.license!.licenseNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Expires: ${driver.license!.expiryDate.day}/${driver.license!.expiryDate.month}/${driver.license!.expiryDate.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: hasLicenseWarning ? Colors.orange : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (driver.hasExpiredLicense)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, size: 14, color: Colors.red),
                            SizedBox(width: 4),
                            Text(
                              'EXPIRED',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (driver.hasExpiringSoonLicense)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'EXPIRING SOON',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],

              // Join Date
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Joined: ${driver.joinDate.day}/${driver.joinDate.month}/${driver.joinDate.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
