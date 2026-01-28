import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Reports & Analytics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate and view various reports for your organization',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 28),

            // Report Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200
                    ? 3
                    : constraints.maxWidth > 800
                        ? 2
                        : 1;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _ReportCard(
                      title: 'Organization Summary',
                      description: 'Overview of drivers, users, and key metrics',
                      icon: Icons.dashboard,
                      color: Colors.blue,
                      onTap: () => context.push('/reports/organization-summary'),
                    ),
                    _ReportCard(
                      title: 'Driver List',
                      description: 'Complete list of all drivers with details',
                      icon: Icons.people,
                      color: Colors.green,
                      onTap: () => context.push('/reports/driver-list'),
                    ),
                    _ReportCard(
                      title: 'License Expiry',
                      description: 'Track license expiration dates',
                      icon: Icons.credit_card,
                      color: Colors.orange,
                      onTap: () => context.push('/reports/license-expiry'),
                    ),
                    _ReportCard(
                      title: 'Audit Log',
                      description: 'View system activity and changes',
                      icon: Icons.history,
                      color: Colors.purple,
                      onTap: () => context.push('/reports/audit-log'),
                    ),
                    _ReportCard(
                      title: 'User Activity',
                      description: 'Monitor user engagement and actions',
                      icon: Icons.bar_chart,
                      color: Colors.teal,
                      onTap: () => context.push('/reports/user-activity'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
