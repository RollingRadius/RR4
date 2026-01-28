import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/custom_role_provider.dart';

class CustomRolesScreen extends ConsumerStatefulWidget {
  const CustomRolesScreen({super.key});

  @override
  ConsumerState<CustomRolesScreen> createState() => _CustomRolesScreenState();
}

class _CustomRolesScreenState extends ConsumerState<CustomRolesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customRoleProvider.notifier).loadCustomRoles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roleState = ref.watch(customRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Roles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(customRoleProvider.notifier).loadCustomRoles();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: roleState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : roleState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${roleState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(customRoleProvider.notifier).loadCustomRoles();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : roleState.customRoles.isEmpty
                  ? _buildEmptyState()
                  : _buildRolesList(roleState.customRoles),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/roles/custom/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Custom Role'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Custom Roles Yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create custom roles to fit your organization needs',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/roles/custom/create');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Role'),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList(List<dynamic> roles) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index] as Map<String, dynamic>;
        return _RoleCard(role: role);
      },
    );
  }
}

class _RoleCard extends ConsumerWidget {
  final Map<String, dynamic> role;

  const _RoleCard({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleName = role['role_name'] as String? ?? 'Unknown Role';
    final description = role['description'] as String? ?? '';
    final capabilityCount = role['capability_count'] as int? ?? 0;
    final templateSources = role['template_sources'] as List<dynamic>? ?? [];
    final isTemplate = role['is_template'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/roles/custom/${role['custom_role_id']}/edit');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isTemplate ? Icons.bookmark : Icons.admin_panel_settings,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roleName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, ref, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clone',
                        child: Row(
                          children: [
                            Icon(Icons.content_copy, size: 20),
                            SizedBox(width: 12),
                            Text('Clone'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'impact',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 20),
                            SizedBox(width: 12),
                            Text('Impact Analysis'),
                          ],
                        ),
                      ),
                      if (!isTemplate)
                        const PopupMenuItem(
                          value: 'template',
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_add, size: 20),
                              SizedBox(width: 12),
                              Text('Save as Template'),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.verified_user,
                    label: '$capabilityCount Capabilities',
                    color: Colors.green,
                  ),
                  if (templateSources.isNotEmpty)
                    _InfoChip(
                      icon: Icons.layers,
                      label: '${templateSources.length} Templates',
                      color: Colors.orange,
                    ),
                  if (isTemplate)
                    const _InfoChip(
                      icon: Icons.bookmark,
                      label: 'Saved Template',
                      color: Colors.purple,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) async {
    final customRoleId = role['custom_role_id'] as String;

    switch (action) {
      case 'edit':
        context.push('/roles/custom/$customRoleId/edit');
        break;

      case 'clone':
        _showCloneDialog(context, ref, customRoleId);
        break;

      case 'impact':
        _showImpactAnalysis(context, ref, customRoleId);
        break;

      case 'template':
        _showSaveAsTemplateDialog(context, ref, customRoleId);
        break;

      case 'delete':
        _showDeleteConfirmation(context, ref, customRoleId);
        break;
    }
  }

  void _showCloneDialog(BuildContext context, WidgetRef ref, String customRoleId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clone Role'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Role Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                final success = await ref
                    .read(customRoleProvider.notifier)
                    .cloneCustomRole(customRoleId, controller.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Role cloned successfully'
                          : 'Failed to clone role'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Clone'),
          ),
        ],
      ),
    );
  }

  void _showImpactAnalysis(BuildContext context, WidgetRef ref, String customRoleId) async {
    await ref.read(customRoleProvider.notifier).loadImpactAnalysis(customRoleId);
    final analysis = ref.read(customRoleProvider).impactAnalysis;

    if (context.mounted && analysis != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Impact Analysis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Users Affected: ${analysis['total_users_affected']}'),
              const SizedBox(height: 8),
              Text('Organizations Affected: ${analysis['organizations_affected']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showSaveAsTemplateDialog(BuildContext context, WidgetRef ref, String customRoleId) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                final success = await ref.read(customRoleProvider.notifier).saveAsTemplate(
                      customRoleId,
                      nameController.text.trim(),
                      templateDescription: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Saved as template successfully'
                          : 'Failed to save as template'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String customRoleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content: const Text(
          'Are you sure you want to delete this role? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await ref.read(customRoleProvider.notifier).deleteCustomRole(customRoleId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? 'Role deleted successfully' : 'Failed to delete role'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
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

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}
