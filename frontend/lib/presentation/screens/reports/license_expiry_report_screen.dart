import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/report_provider.dart';
import 'package:intl/intl.dart';

class LicenseExpiryReportScreen extends ConsumerStatefulWidget {
  const LicenseExpiryReportScreen({super.key});

  @override
  ConsumerState<LicenseExpiryReportScreen> createState() =>
      _LicenseExpiryReportScreenState();
}

class _LicenseExpiryReportScreenState
    extends ConsumerState<LicenseExpiryReportScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reportProvider.notifier).loadLicenseExpiryReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('License Expiry Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(reportProvider.notifier).loadLicenseExpiryReport();
            },
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
    final licenses = report['licenses'] as List<dynamic>;

    return Column(
      children: [
        // Statistics Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(
                icon: Icons.error,
                label: 'Expired',
                value: report['expired_count'].toString(),
                color: Colors.red,
              ),
              _StatCard(
                icon: Icons.warning,
                label: 'Expiring Soon',
                value: report['expiring_soon_count'].toString(),
                color: Colors.orange,
              ),
              _StatCard(
                icon: Icons.check_circle,
                label: 'Valid',
                value: report['valid_count'].toString(),
                color: Colors.green,
              ),
            ],
          ),
        ),

        // License List
        Expanded(
          child: licenses.isEmpty
              ? const Center(child: Text('No licenses found'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: licenses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final license = licenses[index];
                    return _LicenseCard(license: license);
                  },
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _LicenseCard extends StatelessWidget {
  final Map<String, dynamic> license;

  const _LicenseCard({required this.license});

  @override
  Widget build(BuildContext context) {
    final status = license['status'] as String;
    final daysUntilExpiry = license['days_until_expiry'] as int;
    final expiryDate = DateTime.parse(license['expiry_date']);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'expired':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'EXPIRED';
        break;
      case 'expiring_soon':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = 'EXPIRING SOON';
        break;
      default:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'VALID';
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        license['full_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        license['employee_id'] ?? '-',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    statusText,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: statusColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.credit_card,
                    label: 'License',
                    value: license['license_number'] ?? '-',
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.local_shipping,
                    label: 'Type',
                    value: license['license_type'] ?? '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.calendar_today,
                    label: 'Expiry Date',
                    value: DateFormat('MMM dd, yyyy').format(expiryDate),
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.timer,
                    label: 'Days Left',
                    value: daysUntilExpiry < 0
                        ? 'Expired'
                        : '$daysUntilExpiry days',
                    valueColor: statusColor,
                  ),
                ),
              ],
            ),
            if (daysUntilExpiry >= 0 && daysUntilExpiry <= 30) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Renewal required soon',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (daysUntilExpiry < 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'License expired - immediate action required',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
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
        ),
      ],
    );
  }
}
