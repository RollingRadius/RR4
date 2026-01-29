import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/organization_dashboard_provider.dart';

class OrganizationOverviewTab extends ConsumerWidget {
  const OrganizationOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgState = ref.watch(organizationDashboardProvider);

    if (orgState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orgState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(orgState.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(organizationDashboardProvider.notifier).loadMyOrganization();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Header
            _buildCompanyHeader(context, org),
            const SizedBox(height: 24),

            // Statistics Cards
            _buildStatisticsSection(context, stats),
            const SizedBox(height: 24),

            // Company Details
            _buildCompanyDetails(context, org),
            const SizedBox(height: 24),

            // Role Distribution
            if (stats['role_distribution'] != null)
              _buildRoleDistribution(context, stats['role_distribution']),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(BuildContext context, Map<String, dynamic> org) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        org['business_type'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_city,
                    size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  '${org['city']}, ${org['state']}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(
      BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total Employees',
                '${stats['total_employees'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Pending Requests',
                '${stats['pending_requests'] ?? 0}',
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyDetails(BuildContext context, Map<String, dynamic> org) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Company Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.email, 'Email', org['email']),
            const Divider(),
            _buildDetailRow(Icons.phone, 'Phone', org['phone']),
            const Divider(),
            _buildDetailRow(Icons.location_on, 'Address', org['address']),
            const Divider(),
            _buildDetailRow(
              Icons.flag,
              'Location',
              '${org['city']}, ${org['state']} ${org['pincode']}\n${org['country']}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? 'N/A',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDistribution(
      BuildContext context, Map<String, dynamic> roleDistribution) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team by Role',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...roleDistribution.entries.map((entry) {
              final roleName = entry.value['role_name'] ?? entry.key;
              final count = entry.value['count'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getRoleColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        roleName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(entry.key).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getRoleColor(entry.key),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
        return Colors.grey;
    }
  }
}
