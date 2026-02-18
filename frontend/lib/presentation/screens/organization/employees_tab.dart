import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/organization_dashboard_provider.dart';
import 'package:fleet_management/providers/role_provider.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class EmployeesTab extends ConsumerStatefulWidget {
  const EmployeesTab({super.key});

  @override
  ConsumerState<EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends ConsumerState<EmployeesTab> {
  String _statusFilter = 'active';
  String? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final orgState = ref.watch(organizationDashboardProvider);

    return PageEntrance(
      child: Column(
        children: [
          FadeSlide(delay: 0, child: _buildFilters()),
          Expanded(
            child: orgState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : orgState.error != null
                    ? _buildErrorState(orgState.error!)
                    : orgState.employees.isEmpty
                        ? _buildEmptyState()
                        : _buildEmployeeList(orgState.employees),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Status Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.filter_list),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'all', child: Text('All')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _statusFilter = value;
                  });
                  ref.read(organizationDashboardProvider.notifier).loadEmployees(
                        statusFilter: value,
                        roleFilter: _roleFilter,
                      );
                }
              },
            ),
          ),
          const SizedBox(width: 16),

          // Refresh Button
          IconButton(
            onPressed: () {
              ref.read(organizationDashboardProvider.notifier).loadEmployees(
                    statusFilter: _statusFilter,
                    roleFilter: _roleFilter,
                  );
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(organizationDashboardProvider.notifier).loadEmployees();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Employees Found',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Employees will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(List<Map<String, dynamic>> employees) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(organizationDashboardProvider.notifier).loadEmployees(
              statusFilter: _statusFilter,
              roleFilter: _roleFilter,
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          return StaggeredItem(
            index: index,
            staggerMs: 70,
            child: _buildEmployeeCard(employees[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final role = employee['role'];
    final status = employee['status'];
    final isActive = status == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isActive ? Colors.blue : Colors.grey,
                  child: Text(
                    employee['full_name'][0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Employee Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee['full_name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${employee['username']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Role Info
            if (role != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Role',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            role['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Contact Info
            const SizedBox(height: 12),
            _buildContactRow(Icons.email, employee['email']),
            const SizedBox(height: 4),
            _buildContactRow(Icons.phone, employee['phone']),

            // Actions
            if (role?['key'] != 'owner') ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showChangeRoleDialog(employee),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Change Role'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleRemoveEmployee(employee),
                      icon: const Icon(Icons.person_remove, size: 18),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield, size: 16, color: Colors.purple[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Organization Owner',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
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

  Widget _buildContactRow(IconData icon, String? value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          value ?? 'N/A',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Future<void> _showChangeRoleDialog(Map<String, dynamic> employee) async {
    // Load available roles first
    await ref.read(rolesProvider.notifier).loadAvailableRoles();

    final rolesState = ref.read(rolesProvider);

    if (!mounted) return;

    final selectedRoleId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Employee Role'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select new role for ${employee['full_name']}:'),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: rolesState.roles.length,
                  itemBuilder: (context, index) {
                    final role = rolesState.roles[index];
                    // Don't show owner role
                    if (role.roleKey == 'owner') return const SizedBox();

                    return ListTile(
                      title: Text(role.roleName),
                      subtitle: role.description != null
                          ? Text(
                              role.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, role.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedRoleId != null) {
      final success = await ref
          .read(organizationDashboardProvider.notifier)
          .updateEmployeeRole(employee['user_organization_id'], selectedRoleId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Role updated successfully' : 'Failed to update role',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRemoveEmployee(Map<String, dynamic> employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Employee'),
        content: Text(
          'Are you sure you want to remove ${employee['full_name']} from the organization?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(organizationDashboardProvider.notifier)
          .removeEmployee(employee['user_organization_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Employee removed successfully'
                  : 'Failed to remove employee',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
