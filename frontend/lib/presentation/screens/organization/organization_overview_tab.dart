import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/organization_dashboard_provider.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class OrganizationOverviewTab extends ConsumerWidget {
  const OrganizationOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgState = ref.watch(organizationDashboardProvider);

    if (orgState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orgState.error != null) {
      return _buildErrorState(context, ref, orgState.error!);
    }

    if (orgState.organization == null) {
      return const Center(child: Text('No organization found'));
    }

    final org = orgState.organization!;
    final stats = orgState.statistics ?? {};

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(organizationDashboardProvider.notifier).loadMyOrganization();
        await ref.read(organizationDashboardProvider.notifier).loadStatistics();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlide(delay: 0, child: _buildStatsRow(context, stats)),
            const SizedBox(height: 20),
            FadeSlide(delay: 100, child: _buildCompanyDetails(context, org)),
            const SizedBox(height: 20),
            if (stats['role_distribution'] != null)
              FadeSlide(
                delay: 200,
                child: _buildRoleDistribution(context, stats['role_distribution']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load organization',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(organizationDashboardProvider.notifier).loadMyOrganization(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Map<String, dynamic> stats) {
    final total = stats['total_employees'] ?? 0;
    final pending = stats['pending_requests'] ?? 0;
    final active = (total - pending).clamp(0, 999);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: '$total',
            icon: Icons.people_alt_outlined,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Active',
            value: '$active',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Pending',
            value: '$pending',
            icon: Icons.hourglass_top_outlined,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyDetails(BuildContext context, Map<String, dynamic> org) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Company Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: org['email'],
            ),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: org['phone'],
            ),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: org['address'],
            ),
            _DetailRow(
              icon: Icons.map_outlined,
              label: 'Location',
              value: '${org['city'] ?? ''}, ${org['state'] ?? ''} ${org['pincode'] ?? ''}\n${org['country'] ?? ''}',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDistribution(
      BuildContext context, Map<String, dynamic> roleDistribution) {
    if (roleDistribution.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final total = roleDistribution.values
        .fold<int>(0, (sum, v) => sum + (v['count'] as int? ?? 0));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_outlined,
                    size: 18, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Team by Role',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '$total members',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...roleDistribution.entries.map((entry) {
              final roleName = entry.value['role_name'] as String? ?? entry.key;
              final count = entry.value['count'] as int? ?? 0;
              final pct = total > 0 ? count / total : 0.0;
              final color = _getRoleColor(entry.key);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            roleName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String roleKey) {
    switch (roleKey.toLowerCase()) {
      case 'owner':
        return Colors.purple;
      case 'fleet_manager':
        return Colors.blue;
      case 'dispatcher':
        return Colors.green;
      case 'driver':
        return Colors.orange;
      case 'accountant':
        return Colors.teal;
      case 'maintenance_manager':
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value?.isNotEmpty == true ? value! : 'N/A',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
      ],
    );
  }
}
