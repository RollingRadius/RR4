import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/custom_role_provider.dart';
import 'package:fleet_management/providers/template_provider.dart';
import 'package:fleet_management/providers/role_provider.dart';
import 'package:fleet_management/providers/org_members_provider.dart';
import 'package:fleet_management/data/models/role_model.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

// ─── Shared role styling ──────────────────────────────────────────────────────

const _roleIcons = <String, IconData>{
  'super_admin': Icons.shield,
  'fleet_manager': Icons.directions_car,
  'dispatcher': Icons.assignment_turned_in,
  'driver': Icons.drive_eta,
  'accountant': Icons.account_balance,
  'maintenance_manager': Icons.build,
  'compliance_officer': Icons.gavel,
  'operations_manager': Icons.business_center,
  'maintenance_technician': Icons.construction,
  'customer_service': Icons.support_agent,
  'viewer_analyst': Icons.bar_chart,
  'owner': Icons.star_rounded,
};

const _roleColors = <String, Color>{
  'super_admin': Colors.red,
  'fleet_manager': Colors.blue,
  'dispatcher': Colors.orange,
  'driver': Colors.green,
  'accountant': Colors.teal,
  'maintenance_manager': Colors.brown,
  'compliance_officer': Colors.purple,
  'operations_manager': Colors.indigo,
  'maintenance_technician': Colors.deepOrange,
  'customer_service': Colors.pink,
  'viewer_analyst': Colors.cyan,
  'owner': Colors.amber,
};

Color _roleColor(String key) => _roleColors[key] ?? Colors.blueGrey;
IconData _roleIcon(String key) => _roleIcons[key] ?? Icons.admin_panel_settings;

// ─── Screen ───────────────────────────────────────────────────────────────────

class CustomRolesScreen extends ConsumerStatefulWidget {
  const CustomRolesScreen({super.key});

  @override
  ConsumerState<CustomRolesScreen> createState() => _CustomRolesScreenState();
}

class _CustomRolesScreenState extends ConsumerState<CustomRolesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      ref.read(templateProvider.notifier).loadPredefinedTemplates();
      ref.read(customRoleProvider.notifier).loadCustomRoles();
      ref.read(rolesProvider.notifier).loadPendingRequests();
      ref.read(rolesProvider.notifier).loadAvailableRoles();
      ref.read(orgMembersProvider.notifier).loadMembers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        ref.watch(rolesProvider).pendingRequests.length;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          _buildHeader(pendingCount),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _PredefinedTemplatesTab(),
                _CustomRolesTab(),
                _PendingRequestsTab(),
                _MembersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 1) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => context.push('/roles/custom/create'),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Create Custom Role'),
          );
        },
      ),
    );
  }

  Widget _buildHeader(int pendingCount) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              child: Row(
                children: [
                  if (context.canPop()) ...[
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.bgPrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E0E0)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC5B13), Color(0xFFD14A0A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Roles & Permissions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Manage roles, permissions & team members',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppTheme.textSecondary, size: 20),
                    tooltip: 'Refresh',
                    onPressed: () {
                      ref.read(templateProvider.notifier).loadPredefinedTemplates();
                      ref.read(customRoleProvider.notifier).loadCustomRoles();
                      ref.read(rolesProvider.notifier).loadPendingRequests();
                      ref.read(rolesProvider.notifier).loadAvailableRoles();
                      ref.read(orgMembersProvider.notifier).loadMembers();
                    },
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryBlue,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              tabs: [
                const Tab(icon: Icon(Icons.library_books_rounded, size: 16), text: 'Templates'),
                const Tab(icon: Icon(Icons.admin_panel_settings_rounded, size: 16), text: 'Custom'),
                Tab(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pending_actions_rounded, size: 16),
                          SizedBox(height: 2),
                          Text('Pending',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (pendingCount > 0)
                        Positioned(
                          right: -10,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Tab(
                    icon: Icon(Icons.group_rounded, size: 16), text: 'Members'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 0: Predefined Templates ─────────────────────────────────────────────

class _PredefinedTemplatesTab extends ConsumerWidget {
  const _PredefinedTemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(templateProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _ErrorRetry(
        message: state.error!,
        onRetry: () =>
            ref.read(templateProvider.notifier).loadPredefinedTemplates(),
      );
    }

    if (state.predefinedTemplates.isEmpty) {
      return const _EmptyState(
        icon: Icons.library_books,
        title: 'No predefined templates found',
        subtitle: 'Templates are seeded automatically on server startup.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.predefinedTemplates.length,
      itemBuilder: (context, index) {
        final template =
            state.predefinedTemplates[index] as Map<String, dynamic>;
        final roleKey = template['role_key'] as String? ?? '';
        final color = _roleColor(roleKey);
        final icon = _roleIcon(roleKey);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showTemplateDetails(context, template),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template['role_name'] as String? ?? roleKey,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if ((template['description'] as String?)?.isNotEmpty ==
                            true)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              template['description'] as String,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.verified_user,
                                size: 14, color: color.withOpacity(0.8)),
                            const SizedBox(width: 4),
                            Text(
                              '${template['capability_count'] ?? 0} capabilities',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _useAsTemplate(context, template),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color.withOpacity(0.5)),
                    ),
                    child: const Text('Use'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTemplateDetails(
      BuildContext context, Map<String, dynamic> template) {
    final roleKey = template['role_key'] as String? ?? '';
    final color = _roleColor(roleKey);
    final capabilities = template['capabilities'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(_roleIcon(roleKey), color: color, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template['role_name'] as String? ?? roleKey,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${capabilities.length} capabilities',
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if ((template['description'] as String?)?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        template['description'] as String,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: capabilities.isEmpty
                  ? Center(
                      child: Text('No capabilities listed',
                          style: TextStyle(color: Colors.grey[500])))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: capabilities.length,
                      itemBuilder: (context, i) {
                        final cap = capabilities[i] as Map<String, dynamic>;
                        final level = cap['access_level'] as String? ?? 'view';
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.check_circle,
                              color: color.withOpacity(0.7), size: 20),
                          title: Text(
                            cap['capability_key'] as String? ?? '',
                            style: const TextStyle(
                                fontSize: 13, fontFamily: 'monospace'),
                          ),
                          trailing: _AccessLevelChip(level: level),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _useAsTemplate(context, template);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Create Custom Role from This Template',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _useAsTemplate(BuildContext context, Map<String, dynamic> template) {
    final roleKey = template['role_key'] as String? ?? '';
    context.push('/roles/custom/create', extra: {'templateKey': roleKey});
  }
}

// ─── Tab 1: Custom Roles ──────────────────────────────────────────────────────

class _CustomRolesTab extends ConsumerWidget {
  const _CustomRolesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(customRoleProvider);

    if (roleState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (roleState.error != null) {
      return _ErrorRetry(
        message: roleState.error!,
        onRetry: () => ref.read(customRoleProvider.notifier).loadCustomRoles(),
      );
    }

    if (roleState.customRoles.isEmpty) {
      return _EmptyState(
        icon: Icons.admin_panel_settings,
        title: 'No Custom Roles Yet',
        subtitle: 'Create custom roles tailored to your organization',
        action: ElevatedButton.icon(
          onPressed: () => context.push('/roles/custom/create'),
          icon: const Icon(Icons.add),
          label: const Text('Create Your First Role'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roleState.customRoles.length,
      itemBuilder: (context, index) {
        final role = roleState.customRoles[index] as Map<String, dynamic>;
        return _CustomRoleCard(role: role);
      },
    );
  }
}

// ─── Tab 2: Pending Requests ──────────────────────────────────────────────────

class _PendingRequestsTab extends ConsumerWidget {
  const _PendingRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rolesProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _ErrorRetry(
        message: state.error!,
        onRetry: () => ref.read(rolesProvider.notifier).loadPendingRequests(),
      );
    }

    if (state.pendingRequests.isEmpty) {
      return const _EmptyState(
        icon: Icons.how_to_reg_rounded,
        title: 'No Pending Requests',
        subtitle: 'All join requests have been processed.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${state.pendingRequests.length} member${state.pendingRequests.length == 1 ? '' : 's'} waiting to join your organization',
                  style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...state.pendingRequests.map((r) => _PendingRequestCard(request: r)),
      ],
    );
  }
}

class _PendingRequestCard extends ConsumerWidget {
  final PendingRoleRequest request;
  const _PendingRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = request.userName;
    final username = request.username;
    final email = request.email ?? '';
    final userOrgId = request.userOrganizationId;
    final requestedRole = request.requestedRole;
    final currentRole = request.currentRole;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final requestedRoleKey = requestedRole?.key ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User Info ────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      _roleColor(requestedRoleKey).withOpacity(0.15),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _roleColor(requestedRoleKey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('@$username · $email',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Role Request Arrow ────────────────────────────
            Row(
              children: [
                _RoleChip(
                  label: currentRole.name,
                  roleKey: currentRole.key,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppTheme.textTertiary),
                ),
                if (requestedRole != null)
                  _RoleChip(
                    label: requestedRole.name,
                    roleKey: requestedRoleKey,
                    highlighted: true,
                  )
                else
                  const Text('No role requested',
                      style: TextStyle(
                          color: AppTheme.textTertiary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 14),

            // ── Actions ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context, ref, userOrgId, name),
                    icon: const Icon(Icons.close_rounded, size: 16,
                        color: AppTheme.errorColor),
                    label: const Text('Reject',
                        style: TextStyle(color: AppTheme.errorColor)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _showApproveDialog(
                        context, ref, userOrgId, name, requestedRole),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(
    BuildContext context,
    WidgetRef ref,
    String userOrgId,
    String userName,
    RoleInfo? requestedRole,
  ) {
    final availableRoles = ref.read(rolesProvider).roles;
    String? selectedRoleId = requestedRole?.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Approve Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Approving join request from $userName.'),
              const SizedBox(height: 16),
              const Text('Assign Role:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedRoleId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                hint: const Text('Select role'),
                items: availableRoles
                    .where((r) => r.roleKey != 'owner')
                    .map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.roleName),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedRoleId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedRoleId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final ok = await ref
                          .read(rolesProvider.notifier)
                          .approveRoleRequest(userOrgId,
                              approvedRoleId: selectedRoleId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? '$userName approved successfully!'
                              : 'Failed to approve request'),
                          backgroundColor:
                              ok ? AppTheme.successColor : AppTheme.errorColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                    },
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.successColor),
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, WidgetRef ref, String userOrgId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: Text(
            'Reject join request from $name? They will need to reapply to join.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok =
                  await ref.read(rolesProvider.notifier).rejectRoleRequest(userOrgId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      ok ? 'Request rejected.' : 'Failed to reject request'),
                  backgroundColor:
                      ok ? AppTheme.statusWarning : AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Members ───────────────────────────────────────────────────────────

class _MembersTab extends ConsumerWidget {
  const _MembersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orgMembersProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _ErrorRetry(
        message: state.error!,
        onRetry: () => ref.read(orgMembersProvider.notifier).loadMembers(),
      );
    }

    if (state.members.isEmpty) {
      return const _EmptyState(
        icon: Icons.group_rounded,
        title: 'No Members Yet',
        subtitle: 'Approve pending requests to add members to your organization.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.group_rounded, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              '${state.members.length} active member${state.members.length == 1 ? '' : 's'}',
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...state.members.map((m) => _MemberCard(member: m as Map<String, dynamic>)),
      ],
    );
  }
}

class _MemberCard extends ConsumerWidget {
  final Map<String, dynamic> member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = member['full_name'] as String? ?? 'Unknown';
    final username = member['username'] as String? ?? '';
    final email = member['email'] as String? ?? '';
    final userOrgId = member['user_organization_id'] as String? ?? '';
    final role = member['role'] as Map<String, dynamic>?;
    final roleKey = role?['key'] as String? ?? '';
    final roleName = role?['name'] as String? ?? 'No Role';
    final initials = name.isNotEmpty
        ? name.split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '?';
    final isCustomRole = role?['is_custom'] as bool? ?? false;
    final isOwner = roleKey == 'owner';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // ── Avatar ─────────────────────────────────────
            CircleAvatar(
              radius: 22,
              backgroundColor: _roleColor(roleKey).withOpacity(0.15),
              child: Text(
                initials,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _roleColor(roleKey),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('@$username · $email',
                      style: const TextStyle(
                          color: AppTheme.textTertiary, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _RoleChip(label: roleName, roleKey: roleKey),
                      if (isCustomRole)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('custom',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Change Role Button ──────────────────────────
            if (!isOwner)
              IconButton(
                icon: const Icon(Icons.edit_rounded,
                    size: 18, color: AppTheme.textSecondary),
                tooltip: 'Change Role',
                onPressed: () =>
                    _showChangeRoleDialog(context, ref, userOrgId, name, role),
              ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(
    BuildContext context,
    WidgetRef ref,
    String userOrgId,
    String memberName,
    Map<String, dynamic>? currentRole,
  ) {
    final availableRoles = ref.read(rolesProvider).roles;
    String? selectedRoleId = currentRole?['id'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Change Member Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update role for $memberName',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              const Text('New Role:',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedRoleId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: availableRoles
                    .where((r) => r.roleKey != 'owner')
                    .map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.roleName),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedRoleId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedRoleId == null ||
                      selectedRoleId == currentRole?['id']
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final ok = await ref
                          .read(orgMembersProvider.notifier)
                          .updateMemberRole(userOrgId, selectedRoleId!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? 'Role updated for $memberName'
                              : 'Failed to update role'),
                          backgroundColor: ok
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                    },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom Role Card (Tab 1) ─────────────────────────────────────────────────

class _CustomRoleCard extends ConsumerWidget {
  final Map<String, dynamic> role;
  const _CustomRoleCard({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleName = role['role_name'] as String? ?? 'Unknown Role';
    final description = role['description'] as String? ?? '';
    final capabilityCount = role['capability_count'] as int? ?? 0;
    final templateSources = role['template_sources'] as List<dynamic>? ?? [];
    final isTemplate = role['is_template'] as bool? ?? false;
    final id = role['custom_role_id'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/roles/custom/$id/edit'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isTemplate ? Icons.bookmark : Icons.admin_panel_settings,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(roleName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        if (description.isNotEmpty)
                          Text(description,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) =>
                        _handleAction(context, ref, v, id, isTemplate),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Edit')
                          ])),
                      const PopupMenuItem(
                          value: 'clone',
                          child: Row(children: [
                            Icon(Icons.content_copy, size: 20),
                            SizedBox(width: 12),
                            Text('Clone')
                          ])),
                      if (!isTemplate)
                        const PopupMenuItem(
                            value: 'template',
                            child: Row(children: [
                              Icon(Icons.bookmark_add, size: 20),
                              SizedBox(width: 12),
                              Text('Save as Template')
                            ])),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete',
                                style: TextStyle(color: Colors.red))
                          ])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _InfoChip(
                      icon: Icons.verified_user,
                      label: '$capabilityCount Capabilities',
                      color: Colors.green),
                  if (templateSources.isNotEmpty)
                    _InfoChip(
                        icon: Icons.layers,
                        label: '${templateSources.length} Templates',
                        color: Colors.orange),
                  if (isTemplate)
                    const _InfoChip(
                        icon: Icons.bookmark,
                        label: 'Saved Template',
                        color: Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action,
      String id, bool isTemplate) {
    switch (action) {
      case 'edit':
        context.push('/roles/custom/$id/edit');
      case 'clone':
        _cloneDialog(context, ref, id);
      case 'template':
        _saveTemplateDialog(context, ref, id);
      case 'delete':
        _deleteDialog(context, ref, id);
    }
  }

  void _cloneDialog(BuildContext context, WidgetRef ref, String id) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clone Role'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'New Role Name', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              final ok = await ref
                  .read(customRoleProvider.notifier)
                  .cloneCustomRole(id, ctrl.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      ok ? 'Role cloned successfully' : 'Failed to clone'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Clone'),
          ),
        ],
      ),
    );
  }

  void _saveTemplateDialog(BuildContext context, WidgetRef ref, String id) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save as Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Template Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              final ok = await ref.read(customRoleProvider.notifier).saveAsTemplate(
                    id,
                    nameCtrl.text.trim(),
                    templateDescription: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      ok ? 'Saved as template' : 'Failed to save template'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Role'),
        content: const Text(
            'Are you sure you want to delete this role? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final ok = await ref
                  .read(customRoleProvider.notifier)
                  .deleteCustomRole(id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Role deleted successfully'
                      : 'Failed to delete role'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _RoleChip extends StatelessWidget {
  final String label;
  final String roleKey;
  final bool highlighted;

  const _RoleChip({
    required this.label,
    required this.roleKey,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(roleKey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? color.withOpacity(0.15) : AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(20),
        border: highlighted ? Border.all(color: color.withOpacity(0.4)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_roleIcon(roleKey),
              size: 12,
              color: highlighted ? color : AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: highlighted ? color : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _AccessLevelChip extends StatelessWidget {
  final String level;
  const _AccessLevelChip({required this.level});

  static const _colors = <String, Color>{
    'full': Colors.green,
    'limited': Colors.orange,
    'view': Colors.blue,
    'none': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[level] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
