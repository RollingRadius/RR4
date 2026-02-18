import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/report_provider.dart';
import 'package:fleet_management/core/animations/app_animations.dart';
import 'package:intl/intl.dart';

class OrganizationSummaryReportScreen extends ConsumerStatefulWidget {
  const OrganizationSummaryReportScreen({super.key});

  @override
  ConsumerState<OrganizationSummaryReportScreen> createState() =>
      _OrganizationSummaryReportScreenState();
}

class _OrganizationSummaryReportScreenState
    extends ConsumerState<OrganizationSummaryReportScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reportProvider.notifier).loadOrganizationSummaryReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(reportProvider.notifier).loadOrganizationSummaryReport();
            },
            tooltip: 'Refresh Report',
          ),
        ],
      ),
      body: reportState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${reportState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(reportProvider.notifier)
                              .loadOrganizationSummaryReport();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : reportState.currentReport == null
                  ? const Center(child: Text('No data available'))
                  : _buildReportContent(reportState.currentReport!),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> report) {
    final stats = report['stats'] as Map<String, dynamic>;
    final generatedAt = DateTime.parse(report['generated_at']);
    final recentActivity = report['recent_activity'] as List<dynamic>;

    return PageEntrance(
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report['organization_name'],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(generatedAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // TODO: Implement export
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export feature coming soon')),
                  );
                },
                tooltip: 'Export Report',
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Driver Statistics
          Text(
            'Driver Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid([
            _StatCard(
              title: 'Total Drivers',
              value: stats['total_drivers'].toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Active',
              value: stats['active_drivers'].toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Inactive',
              value: stats['inactive_drivers'].toString(),
              icon: Icons.cancel,
              color: Colors.grey,
            ),
            _StatCard(
              title: 'On Leave',
              value: stats['on_leave_drivers'].toString(),
              icon: Icons.event_busy,
              color: Colors.orange,
            ),
          ]),
          const SizedBox(height: 28),

          // User Statistics
          Text(
            'User Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid([
            _StatCard(
              title: 'Total Users',
              value: stats['total_users'].toString(),
              icon: Icons.person,
              color: Colors.purple,
            ),
            _StatCard(
              title: 'Active',
              value: stats['active_users'].toString(),
              icon: Icons.verified_user,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Pending',
              value: stats['pending_users'].toString(),
              icon: Icons.pending,
              color: Colors.amber,
            ),
          ]),
          const SizedBox(height: 28),

          // License Compliance
          Text(
            'License Compliance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid([
            _StatCard(
              title: 'Expiring Soon',
              value: stats['licenses_expiring_soon'].toString(),
              icon: Icons.warning,
              color: Colors.orange,
              subtitle: 'Within 30 days',
            ),
            _StatCard(
              title: 'Expired',
              value: stats['expired_licenses'].toString(),
              icon: Icons.error,
              color: Colors.red,
              subtitle: 'Action required',
            ),
          ]),
          const SizedBox(height: 28),

          // Recent Activity
          if (recentActivity.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full audit log
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentActivity.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final activity = recentActivity[index];
                  final timestamp =
                      DateTime.parse(activity['timestamp']);
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(_getActionIcon(activity['action'])),
                    ),
                    title: Text(
                      _formatAction(activity['action']),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      activity['entity_type'] ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      DateFormat('HH:mm').format(timestamp),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    ),  // closes PageEntrance
    );
  }

  Widget _buildStatsGrid(List<_StatCard> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  IconData _getActionIcon(String action) {
    if (action.contains('login')) return Icons.login;
    if (action.contains('logout')) return Icons.logout;
    if (action.contains('created')) return Icons.add_circle;
    if (action.contains('updated')) return Icons.edit;
    if (action.contains('deleted')) return Icons.delete;
    if (action.contains('approved')) return Icons.check_circle;
    return Icons.info;
  }

  String _formatAction(String action) {
    return action.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
