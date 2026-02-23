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
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> employees) {
    if (_searchQuery.isEmpty) return employees;
    return employees.where((e) {
      final name = (e['full_name'] as String? ?? '').toLowerCase();
      final username = (e['username'] as String? ?? '').toLowerCase();
      final email = (e['email'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery) ||
          username.contains(_searchQuery) ||
          email.contains(_searchQuery);
    }).toList();
  }

  void _setFilter(String value) {
    setState(() => _statusFilter = value);
    ref.read(organizationDashboardProvider.notifier).loadEmployees(
          statusFilter: value,
        );
  }

  @override
  Widget build(BuildContext context) {
    final orgState = ref.watch(organizationDashboardProvider);
    final employees = _filtered(orgState.employees);

    return Column(
      children: [
        _buildSearchAndFilter(context),
        Expanded(
          child: orgState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : orgState.error != null
                  ? _buildErrorState(orgState.error!)
                  : employees.isEmpty
                      ? _buildEmptyState()
                      : _buildList(employees),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search employees…',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[400]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: theme.brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips
          Row(
            children: [
              _FilterChip(
                label: 'Active',
                selected: _statusFilter == 'active',
                onTap: () => _setFilter('active'),
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Pending',
                selected: _statusFilter == 'pending',
                onTap: () => _setFilter('pending'),
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'All',
                selected: _statusFilter == 'all',
                onTap: () => _setFilter('all'),
                color: theme.primaryColor,
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.refresh_outlined, size: 20),
                tooltip: 'Refresh',
                onPressed: () => ref
                    .read(organizationDashboardProvider.notifier)
                    .loadEmployees(statusFilter: _statusFilter),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> employees) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(organizationDashboardProvider.notifier)
            .loadEmployees(statusFilter: _statusFilter);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: employees.length,
        itemBuilder: (context, index) => StaggeredItem(
          index: index,
          staggerMs: 60,
          child: _EmployeeCard(
            employee: employees[index],
            onChangeRole: () => _showChangeRoleDialog(employees[index]),
            onRemove: () => _handleRemoveEmployee(employees[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : 'No employees found',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600]),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _searchController.clear(),
              child: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref
                  .read(organizationDashboardProvider.notifier)
                  .loadEmployees(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeRoleDialog(Map<String, dynamic> employee) async {
    await ref.read(rolesProvider.notifier).loadAvailableRoles();
    final rolesState = ref.read(rolesProvider);
    if (!mounted) return;

    final selectedRoleId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Role'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select new role for ${employee['full_name']}:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: rolesState.roles.length,
                  itemBuilder: (context, index) {
                    final role = rolesState.roles[index];
                    if (role.roleKey == 'owner') return const SizedBox();
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(role.roleName,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: role.description != null
                          ? Text(role.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12))
                          : null,
                      onTap: () => Navigator.pop(dialogContext, role.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              success ? 'Role updated successfully' : 'Failed to update role'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
      }
    }
  }

  Future<void> _handleRemoveEmployee(Map<String, dynamic> employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Employee'),
        content: Text(
          'Remove ${employee['full_name']} from the organization?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Employee removed'
              : 'Failed to remove employee'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
      }
    }
  }
}

// ─── Employee Card ────────────────────────────────────────────────────────────

class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onChangeRole;
  final VoidCallback onRemove;

  const _EmployeeCard({
    required this.employee,
    required this.onChangeRole,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final role = employee['role'] as Map<String, dynamic>?;
    final status = employee['status'] as String? ?? '';
    final isActive = status == 'active';
    final isOwner = role?['key'] == 'owner';
    final fullName = employee['full_name'] as String? ?? 'Unknown';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    final avatarColor = _colorFromName(fullName);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: avatarColor.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${employee['username'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Role chip
                      if (role != null)
                        _SmallChip(
                          label: role['name'] as String? ?? 'Unknown',
                          color: isOwner ? Colors.purple : theme.primaryColor,
                        ),
                      const SizedBox(width: 6),
                      // Status chip
                      _SmallChip(
                        label: status.toUpperCase(),
                        color: isActive ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            if (!isOwner)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'change_role') onChangeRole();
                  if (value == 'remove') onRemove();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'change_role',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 18),
                        SizedBox(width: 10),
                        Text('Change Role'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove_outlined,
                            size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Remove',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_vert, size: 18),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14, color: Colors.purple[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Owner',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[600],
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

  Color _colorFromName(String name) {
    const colors = [
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    final idx = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[idx];
  }
}

// ─── Small Chip ───────────────────────────────────────────────────────────────

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Filter Chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
