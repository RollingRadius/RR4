import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/custom_role_provider.dart';
import 'package:fleet_management/providers/template_provider.dart';

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
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(templateProvider.notifier).loadPredefinedTemplates();
      ref.read(customRoleProvider.notifier).loadCustomRoles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles & Permissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(templateProvider.notifier).loadPredefinedTemplates();
              ref.read(customRoleProvider.notifier).loadCustomRoles();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.library_books), text: 'Predefined'),
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Custom Roles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PredefinedTemplatesTab(),
          _CustomRolesTab(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 1) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => context.push('/roles/custom/create'),
            icon: const Icon(Icons.add),
            label: const Text('Create Custom Role'),
          );
        },
      ),
    );
  }
}

// ─── Predefined Templates Tab ─────────────────────────────────────────────────

class _PredefinedTemplatesTab extends ConsumerWidget {
  const _PredefinedTemplatesTab();

  static const _roleIcons = <String, IconData>{
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
  };

  static const _roleColors = <String, Color>{
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
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(templateProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(templateProvider.notifier).loadPredefinedTemplates(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.predefinedTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No predefined templates found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Templates are seeded automatically on server startup.',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.predefinedTemplates.length,
      itemBuilder: (context, index) {
        final template =
            state.predefinedTemplates[index] as Map<String, dynamic>;
        final roleKey = template['role_key'] as String? ?? '';
        final color = _roleColors[roleKey] ?? Colors.blue;
        final icon = _roleIcons[roleKey] ?? Icons.admin_panel_settings;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showTemplateDetails(context, template),
            borderRadius: BorderRadius.circular(12),
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
                        if ((template['description'] as String?)
                                ?.isNotEmpty ==
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
    final color = _roleColors[roleKey] ?? Colors.blue;
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
                      Icon(
                          _roleIcons[roleKey] ?? Icons.admin_panel_settings,
                          color: color,
                          size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template['role_name'] as String? ?? roleKey,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${capabilities.length} capabilities',
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if ((template['description'] as String?)?.isNotEmpty ==
                      true)
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
                        final cap =
                            capabilities[i] as Map<String, dynamic>;
                        final level =
                            cap['access_level'] as String? ?? 'view';
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.check_circle,
                              color: color.withOpacity(0.7), size: 20),
                          title: Text(
                            cap['capability_key'] as String? ?? '',
                            style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace'),
                          ),
                          trailing: _AccessLevelChip(level: level),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _useAsTemplate(context, template);
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: color),
                  icon:
                      const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Create Custom Role from This Template',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _useAsTemplate(
      BuildContext context, Map<String, dynamic> template) {
    final roleKey = template['role_key'] as String? ?? '';
    context.push('/roles/custom/create', extra: {'templateKey': roleKey});
  }
}

// ─── Custom Roles Tab ─────────────────────────────────────────────────────────

class _CustomRolesTab extends ConsumerWidget {
  const _CustomRolesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(customRoleProvider);

    if (roleState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (roleState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                roleState.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(customRoleProvider.notifier).loadCustomRoles(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (roleState.customRoles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings,
                size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Custom Roles Yet',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create custom roles tailored to your organization',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/roles/custom/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Role'),
            ),
          ],
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

// ─── Custom Role Card ─────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(12),
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
                      isTemplate
                          ? Icons.bookmark
                          : Icons.admin_panel_settings,
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
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
                            Icon(Icons.delete,
                                size: 20, color: Colors.red),
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
              labelText: 'New Role Name',
              border: OutlineInputBorder()),
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
                  content: Text(ok
                      ? 'Role cloned successfully'
                      : 'Failed to clone'),
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
                  labelText: 'Template Name',
                  border: OutlineInputBorder()),
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
              final ok = await ref
                  .read(customRoleProvider.notifier)
                  .saveAsTemplate(
                    id,
                    nameCtrl.text.trim(),
                    templateDescription:
                        descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Saved as template'
                      : 'Failed to save template'),
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
      builder: (_) => AlertDialog(
        title: const Text('Delete Role'),
        content: const Text(
            'Are you sure you want to delete this role? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
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

// ─── Shared Widgets ────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

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
