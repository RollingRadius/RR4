import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

class VehicleDetailsScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  ConsumerState<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual API call
    final vehicle = _getMockVehicleDetails();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(vehicle['registration'] as String),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              // TODO: Handle menu actions
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'assign_driver',
                child: Text('Assign Driver'),
              ),
              const PopupMenuItem(
                value: 'schedule_maintenance',
                child: Text('Schedule Maintenance'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Report'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
            Tab(text: 'Maintenance'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(vehicle: vehicle),
          _AnalyticsTab(vehicle: vehicle),
          _MaintenanceTab(vehicleId: widget.vehicleId),
          _ExpensesTab(vehicleId: widget.vehicleId),
        ],
      ),
    );
  }

  Map<String, dynamic> _getMockVehicleDetails() {
    return {
      'id': widget.vehicleId,
      'registration': 'DL01AB1234',
      'make': 'Tata',
      'model': 'Ace',
      'year': 2022,
      'type': 'Truck',
      'status': 'Active',
      'driver': 'John Doe',
      'driverId': '1',
      'mileage': 15000.0,
      'fuelType': 'Diesel',
      'purchaseDate': '2022-01-15',
      'purchasePrice': 850000.0,
      'vinNumber': 'MAT123456789',
      'engineNumber': 'ENG456789',
      'insurance': {
        'provider': 'HDFC ERGO',
        'policyNumber': 'POL123456',
        'expiryDate': '2025-01-14',
      },
      'lastService': '2024-01-15',
      'nextServiceDue': '2024-04-15',
    };
  }
}

// Overview Tab
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const _OverviewTab({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _StatusCard(vehicle: vehicle),
          const SizedBox(height: 16),

          // Quick Stats
          _QuickStatsCard(vehicle: vehicle),
          const SizedBox(height: 16),

          // Vehicle Details
          _DetailsCard(vehicle: vehicle),
          const SizedBox(height: 16),

          // Insurance & Documents
          _InsuranceCard(vehicle: vehicle),
          const SizedBox(height: 16),

          // Driver Assignment
          _DriverCard(vehicle: vehicle),
          const SizedBox(height: 16),

          // Recommendations
          _RecommendationsCard(vehicle: vehicle),
        ],
      ),
    );
  }
}

// Status Card Widget
class _StatusCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const _StatusCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final status = vehicle['status'] as String;
    final statusColor = _getStatusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_car,
                size: 40,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle['make']} ${vehicle['model']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Year: ${vehicle['year']} • ${vehicle['type']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
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
            ),
          ],
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

// Quick Stats Card
class _QuickStatsCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const _QuickStatsCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.speed,
                    label: 'Total Mileage',
                    value: '${vehicle['mileage']} km',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.local_gas_station,
                    label: 'Fuel Type',
                    value: vehicle['fuelType'] as String,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: _StatItem(
                    icon: Icons.build,
                    label: 'Maintenance',
                    value: '3 services',
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.currency_rupee,
                    label: 'Total Cost',
                    value: '₹${_formatCurrency(125000)}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

// Stat Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Details Card
class _DetailsCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const _DetailsCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Registration Number',
              value: vehicle['registration'] as String,
            ),
            _DetailRow(
              label: 'VIN Number',
              value: vehicle['vinNumber'] as String,
            ),
            _DetailRow(
              label: 'Engine Number',
              value: vehicle['engineNumber'] as String,
            ),
            _DetailRow(
              label: 'Purchase Date',
              value: vehicle['purchaseDate'] as String,
            ),
            _DetailRow(
              label: 'Purchase Price',
              value: '₹${vehicle['purchasePrice']}',
            ),
          ],
        ),
      ),
    );
  }
}

// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Insurance Card
class _InsuranceCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const _InsuranceCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final insurance = vehicle['insurance'] as Map<String, dynamic>;
    final expiryDate = DateTime.parse(insurance['expiryDate'] as String);
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysUntilExpiry <= 30;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Insurance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isExpiringSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Expiring in $daysUntilExpiry days',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Provider',
              value: insurance['provider'] as String,
            ),
            _DetailRow(
              label: 'Policy Number',
              value: insurance['policyNumber'] as String,
            ),
            _DetailRow(
              label: 'Expiry Date',
              value: insurance['expiryDate'] as String,
            ),
          ],
        ),
      ),
    );
  }
}

// Driver Card
class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const _DriverCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final hasDriver = vehicle['driver'] != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Assigned Driver',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (hasDriver)
                  TextButton(
                    onPressed: () {
                      // TODO: Change driver
                    },
                    child: const Text('Change'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Assign driver
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Assign'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasDriver)
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 28,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['driver'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Employee ID: EMP001',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_off_outlined, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Text(
                      'No driver assigned',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Recommendations Card
class _RecommendationsCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const _RecommendationsCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final recommendations = _getRecommendations();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) => _RecommendationItem(
                  icon: rec['icon'] as IconData,
                  title: rec['title'] as String,
                  description: rec['description'] as String,
                  priority: rec['priority'] as String,
                )),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getRecommendations() {
    return [
      {
        'icon': Icons.build,
        'title': 'Schedule Maintenance',
        'description': 'Next service due in 15 days (at 20,000 km)',
        'priority': 'medium',
      },
      {
        'icon': Icons.description,
        'title': 'Insurance Renewal',
        'description': 'Policy expires in 28 days. Start renewal process.',
        'priority': 'high',
      },
      {
        'icon': Icons.trending_down,
        'title': 'Fuel Efficiency',
        'description': 'Current: 12 km/l. Target: 15 km/l. Check tire pressure and air filter.',
        'priority': 'low',
      },
    ];
  }
}

// Recommendation Item Widget
class _RecommendationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String priority;

  const _RecommendationItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: priorityColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: priorityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Analytics Tab
class _AnalyticsTab extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const _AnalyticsTab({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mileage Trend Chart
          _MileageTrendChart(),
          const SizedBox(height: 16),

          // Fuel Efficiency Chart
          _FuelEfficiencyChart(),
          const SizedBox(height: 16),

          // Cost Breakdown
          _CostBreakdownChart(),
          const SizedBox(height: 16),

          // Performance Metrics
          _PerformanceMetrics(),
        ],
      ),
    );
  }
}

// Mileage Trend Chart
class _MileageTrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mileage Trend (Last 6 Months)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'];
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 8000),
                        const FlSpot(1, 9500),
                        const FlSpot(2, 11000),
                        const FlSpot(3, 12500),
                        const FlSpot(4, 13800),
                        const FlSpot(5, 15000),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fuel Efficiency Chart
class _FuelEfficiencyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fuel Efficiency (km/l)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: const Text('Current: 12 km/l'),
                  backgroundColor: Colors.orange.withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: const Text('Target: 15 km/l'),
                  backgroundColor: Colors.green.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(toY: 11.5, color: Colors.orange, width: 20)
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(toY: 12.0, color: Colors.orange, width: 20)
                    ]),
                    BarChartGroupData(x: 2, barRods: [
                      BarChartRodData(toY: 11.8, color: Colors.orange, width: 20)
                    ]),
                    BarChartGroupData(x: 3, barRods: [
                      BarChartRodData(toY: 12.3, color: Colors.orange, width: 20)
                    ]),
                    BarChartGroupData(x: 4, barRods: [
                      BarChartRodData(toY: 12.5, color: Colors.orange, width: 20)
                    ]),
                    BarChartGroupData(x: 5, barRods: [
                      BarChartRodData(toY: 12.0, color: Colors.orange, width: 20)
                    ]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'];
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Cost Breakdown Chart
class _CostBreakdownChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cost Breakdown (Last 6 Months)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: [
                          PieChartSectionData(
                            value: 45,
                            title: 'Fuel\n45%',
                            color: Colors.blue,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 30,
                            title: 'Maintenance\n30%',
                            color: Colors.orange,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 15,
                            title: 'Insurance\n15%',
                            color: Colors.green,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 10,
                            title: 'Other\n10%',
                            color: Colors.purple,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CostLegendItem(
                        color: Colors.blue,
                        label: 'Fuel',
                        amount: '₹56,250',
                      ),
                      _CostLegendItem(
                        color: Colors.orange,
                        label: 'Maintenance',
                        amount: '₹37,500',
                      ),
                      _CostLegendItem(
                        color: Colors.green,
                        label: 'Insurance',
                        amount: '₹18,750',
                      ),
                      _CostLegendItem(
                        color: Colors.purple,
                        label: 'Other',
                        amount: '₹12,500',
                      ),
                      const Divider(),
                      _CostLegendItem(
                        color: Colors.black,
                        label: 'Total',
                        amount: '₹1,25,000',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Cost Legend Item
class _CostLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;
  final bool isBold;

  const _CostLegendItem({
    required this.color,
    required this.label,
    required this.amount,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Performance Metrics
class _PerformanceMetrics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _MetricBar(
              label: 'Fuel Efficiency',
              value: 0.8,
              current: '12 km/l',
              target: '15 km/l',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _MetricBar(
              label: 'Maintenance Score',
              value: 0.9,
              current: '90/100',
              target: '100',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _MetricBar(
              label: 'Uptime',
              value: 0.95,
              current: '95%',
              target: '100%',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _MetricBar(
              label: 'Cost Efficiency',
              value: 0.75,
              current: '₹8.3/km',
              target: '₹6.0/km',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

// Metric Bar Widget
class _MetricBar extends StatelessWidget {
  final String label;
  final double value;
  final String current;
  final String target;
  final Color color;

  const _MetricBar({
    required this.label,
    required this.value,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$current / $target',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// Maintenance Tab
class _MaintenanceTab extends StatelessWidget {
  final String vehicleId;

  const _MaintenanceTab({required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final maintenanceHistory = _getMockMaintenanceHistory();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: maintenanceHistory.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Next Service Due',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'April 15, 2024',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'In 15 days or at 20,000 km',
                    style: TextStyle(
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Schedule maintenance
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Schedule Now'),
                  ),
                ],
              ),
            ),
          );
        }

        final maintenance = maintenanceHistory[index - 1];
        return _MaintenanceCard(maintenance: maintenance);
      },
    );
  }

  List<Map<String, dynamic>> _getMockMaintenanceHistory() {
    return [
      {
        'date': '2024-01-15',
        'type': 'Routine Service',
        'mileage': 15000,
        'cost': 4500.0,
        'description': 'Oil change, filter replacement, general inspection',
        'status': 'Completed',
        'vendor': 'ABC Auto Service',
      },
      {
        'date': '2023-10-20',
        'type': 'Tire Replacement',
        'mileage': 12000,
        'cost': 18000.0,
        'description': 'Replaced all 4 tires',
        'status': 'Completed',
        'vendor': 'XYZ Tires',
      },
      {
        'date': '2023-07-10',
        'type': 'Brake Service',
        'mileage': 10000,
        'cost': 8500.0,
        'description': 'Brake pad replacement, brake fluid change',
        'status': 'Completed',
        'vendor': 'ABC Auto Service',
      },
    ];
  }
}

// Maintenance Card
class _MaintenanceCard extends StatelessWidget {
  final Map<String, dynamic> maintenance;

  const _MaintenanceCard({required this.maintenance});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    maintenance['type'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    maintenance['status'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              maintenance['description'] as String,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  maintenance['date'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.speed, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${maintenance['mileage']} km',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  '₹${maintenance['cost']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (maintenance['vendor'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.store, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    maintenance['vendor'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Expenses Tab
class _ExpensesTab extends StatelessWidget {
  final String vehicleId;

  const _ExpensesTab({required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final expenses = _getMockExpenses();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _ExpenseSummaryCard(
                  title: 'Total',
                  amount: '₹1,25,000',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ExpenseSummaryCard(
                  title: 'This Month',
                  amount: '₹18,500',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ExpenseSummaryCard(
                  title: 'Avg/Month',
                  amount: '₹20,833',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return _ExpenseCard(expense: expense);
            },
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getMockExpenses() {
    return [
      {
        'date': '2024-01-25',
        'category': 'Fuel',
        'amount': 5500.0,
        'description': 'Fuel refill - 75 liters',
        'vendor': 'Shell Petrol Pump',
      },
      {
        'date': '2024-01-15',
        'category': 'Maintenance',
        'amount': 4500.0,
        'description': 'Routine service',
        'vendor': 'ABC Auto Service',
      },
      {
        'date': '2024-01-10',
        'category': 'Toll',
        'amount': 850.0,
        'description': 'Highway toll - Delhi to Jaipur',
        'vendor': 'NHAI',
      },
      {
        'date': '2024-01-05',
        'category': 'Fuel',
        'amount': 5200.0,
        'description': 'Fuel refill - 72 liters',
        'vendor': 'HP Petrol Pump',
      },
    ];
  }
}

// Expense Summary Card
class _ExpenseSummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _ExpenseSummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Expense Card
class _ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;

  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getCategoryColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(),
                color: _getCategoryColor(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense['category'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense['description'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        expense['date'] as String,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '₹${expense['amount']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (expense['category'] as String) {
      case 'Fuel':
        return Icons.local_gas_station;
      case 'Maintenance':
        return Icons.build;
      case 'Toll':
        return Icons.toll;
      case 'Parking':
        return Icons.local_parking;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor() {
    switch (expense['category'] as String) {
      case 'Fuel':
        return Colors.blue;
      case 'Maintenance':
        return Colors.orange;
      case 'Toll':
        return Colors.purple;
      case 'Parking':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
