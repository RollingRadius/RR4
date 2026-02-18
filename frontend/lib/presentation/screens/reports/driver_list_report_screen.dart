import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/report_provider.dart';
import 'package:fleet_management/core/animations/app_animations.dart';
import 'package:intl/intl.dart';

class DriverListReportScreen extends ConsumerStatefulWidget {
  const DriverListReportScreen({super.key});

  @override
  ConsumerState<DriverListReportScreen> createState() =>
      _DriverListReportScreenState();
}

class _DriverListReportScreenState
    extends ConsumerState<DriverListReportScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    Future.microtask(() {
      ref.read(reportProvider.notifier).loadDriverListReport(
            statusFilter: _statusFilter,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver List Report'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by Status',
            onSelected: (value) {
              setState(() {
                _statusFilter = value == 'all' ? null : value;
              });
              _loadReport();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Drivers')),
              const PopupMenuItem(value: 'active', child: Text('Active Only')),
              const PopupMenuItem(value: 'inactive', child: Text('Inactive Only')),
              const PopupMenuItem(value: 'on_leave', child: Text('On Leave')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: reportState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportState.error != null
              ? Center(child: Text('Error: ${reportState.error}'))
              : reportState.currentReport == null
                  ? const Center(child: Text('No data'))
                  : _buildReportContent(reportState.currentReport!),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> report) {
    final drivers = report['drivers'] as List<dynamic>;

    return Column(
      children: [
        // Statistics Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Total',
                value: report['total_drivers'].toString(),
                color: Colors.blue,
              ),
              _StatItem(
                label: 'Active',
                value: report['active_drivers'].toString(),
                color: Colors.green,
              ),
              _StatItem(
                label: 'Inactive',
                value: report['inactive_drivers'].toString(),
                color: Colors.grey,
              ),
            ],
          ),
        ),

        // Driver List
        Expanded(
          child: drivers.isEmpty
              ? const Center(child: Text('No drivers found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return StaggeredItem(
                      index: index,
                      staggerMs: 60,
                      child: _DriverCard(driver: driver),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;

  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final isExpired = driver['is_license_expired'] ?? false;
    final isExpiringSoon = driver['is_license_expiring_soon'] ?? false;
    final daysUntilExpiry = driver['days_until_expiry'];

    Color statusColor = Colors.grey;
    if (driver['status'] == 'active') statusColor = Colors.green;
    if (driver['status'] == 'on_leave') statusColor = Colors.orange;
    if (driver['status'] == 'terminated') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Text(
            driver['full_name']?.substring(0, 1).toUpperCase() ?? 'D',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          driver['full_name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${driver['employee_id']} • ${driver['phone']}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isExpired)
              const Chip(
                label: Text('Expired', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.red,
                labelPadding: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.zero,
              )
            else if (isExpiringSoon)
              const Chip(
                label: Text('Expiring', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.orange,
                labelPadding: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  icon: Icons.badge,
                  label: 'Employee ID',
                  value: driver['employee_id'] ?? '-',
                ),
                _DetailRow(
                  icon: Icons.credit_card,
                  label: 'License',
                  value:
                      '${driver['license_number'] ?? '-'} (${driver['license_type'] ?? '-'})',
                ),
                if (driver['license_expiry'] != null)
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'License Expiry',
                    value: DateFormat('MMM dd, yyyy')
                        .format(DateTime.parse(driver['license_expiry'])),
                  ),
                if (daysUntilExpiry != null)
                  _DetailRow(
                    icon: Icons.timer,
                    label: 'Days Until Expiry',
                    value: daysUntilExpiry.toString(),
                    valueColor: isExpired
                        ? Colors.red
                        : isExpiringSoon
                            ? Colors.orange
                            : null,
                  ),
                _DetailRow(
                  icon: Icons.work,
                  label: 'Join Date',
                  value: DateFormat('MMM dd, yyyy')
                      .format(DateTime.parse(driver['join_date'])),
                ),
                _DetailRow(
                  icon: Icons.info,
                  label: 'Status',
                  value: driver['status']?.toString().toUpperCase() ?? '-',
                  valueColor: statusColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
