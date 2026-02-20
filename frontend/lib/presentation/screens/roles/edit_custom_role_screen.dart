import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/custom_role_provider.dart';
import 'package:fleet_management/providers/capability_provider.dart';

// ─── Category display configuration ───────────────────────────────────────────
class _CategoryInfo {
  final String label;
  final IconData icon;
  const _CategoryInfo(this.label, this.icon);
}

const _categoryMeta = <String, _CategoryInfo>{
  'user_management': _CategoryInfo('User Management', Icons.manage_accounts),
  'role_management': _CategoryInfo('Role Management', Icons.admin_panel_settings),
  'vehicle_management': _CategoryInfo('Vehicle Management', Icons.directions_car),
  'driver_management': _CategoryInfo('Driver Management', Icons.person),
  'trip_management': _CategoryInfo('Trip Management', Icons.route),
  'tracking': _CategoryInfo('Tracking & Monitoring', Icons.location_on),
  'financial': _CategoryInfo('Financial Management', Icons.attach_money),
  'maintenance': _CategoryInfo('Maintenance', Icons.build),
  'compliance': _CategoryInfo('Compliance & Safety', Icons.verified_user),
  'customer': _CategoryInfo('Customer Management', Icons.people),
  'reporting': _CategoryInfo('Reporting & Analytics', Icons.bar_chart),
  'system': _CategoryInfo('System Settings', Icons.settings),
};

const _accessLevels = ['none', 'view', 'limited', 'full'];

const _levelColors = {
  'none': Color(0xFFBDBDBD),
  'view': Color(0xFF42A5F5),
  'limited': Color(0xFFFFA726),
  'full': Color(0xFF66BB6A),
};

const _levelLabels = {
  'none': 'None',
  'view': 'View',
  'limited': 'Limited',
  'full': 'Full',
};

// ─── Screen ───────────────────────────────────────────────────────────────────
class EditCustomRoleScreen extends ConsumerStatefulWidget {
  final String customRoleId;

  const EditCustomRoleScreen({super.key, required this.customRoleId});

  @override
  ConsumerState<EditCustomRoleScreen> createState() =>
      _EditCustomRoleScreenState();
}

class _EditCustomRoleScreenState extends ConsumerState<EditCustomRoleScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // capability_key → access_level (e.g. 'none', 'view', 'limited', 'full')
  Map<String, String> _capabilityLevels = {};
  // All capabilities from API, grouped by category
  Map<String, List<Map<String, dynamic>>> _byCategory = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _hasChanges = false;

  // Original values for change detection
  String _originalName = '';
  String _originalDesc = '';
  Map<String, String> _originalLevels = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load custom role and all capabilities in parallel
      final customRoleApi = ref.read(customRoleApiProvider);
      final capabilityApi = ref.read(capabilityApiProvider);

      final results = await Future.wait([
        customRoleApi.getCustomRole(widget.customRoleId),
        capabilityApi.getAllCapabilities(),
      ]);

      final roleData = results[0]['custom_role'] as Map<String, dynamic>;
      final allCaps = results[1]['capabilities'] as List<dynamic>;

      // Populate name and description
      _nameController.text = roleData['role_name'] as String? ?? '';
      _descController.text = roleData['description'] as String? ?? '';
      _originalName = _nameController.text;
      _originalDesc = _descController.text;

      // Build current capability levels map from the list of role capabilities
      // API returns capabilities as List<{capability_key, access_level, ...}>
      final capsList = (roleData['capabilities'] as List<dynamic>?) ?? [];
      final Map<String, String> roleCaps = {};
      for (final cap in capsList) {
        final capMap = cap as Map<String, dynamic>;
        final key = capMap['capability_key'] as String?;
        final level = capMap['access_level'] as String?;
        if (key != null && level != null) {
          roleCaps[key] = level;
        }
      }

      // Group all capabilities by category
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final cap in allCaps) {
        final capMap = cap as Map<String, dynamic>;
        final category = capMap['feature_category'] as String? ?? 'other';
        grouped.putIfAbsent(category, () => []).add(capMap);
      }

      // Build levels map: default 'none' if not in role
      final Map<String, String> levels = {};
      for (final cap in allCaps) {
        final key = (cap as Map<String, dynamic>)['capability_key'] as String;
        levels[key] = roleCaps[key] ?? 'none';
      }

      setState(() {
        _byCategory = grouped;
        _capabilityLevels = levels;
        _originalLevels = Map.from(levels);
        _loading = false;
        _hasChanges = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onLevelChanged(String capKey, String newLevel) {
    setState(() {
      _capabilityLevels[capKey] = newLevel;
      _hasChanges = _detectChanges();
    });
  }

  bool _detectChanges() {
    if (_nameController.text != _originalName) return true;
    if (_descController.text != _originalDesc) return true;
    for (final key in _capabilityLevels.keys) {
      if (_capabilityLevels[key] != _originalLevels[key]) return true;
    }
    return false;
  }

  void _setCategoryLevel(String category, String level) {
    final caps = _byCategory[category] ?? [];
    setState(() {
      for (final cap in caps) {
        final key = cap['capability_key'] as String;
        _capabilityLevels[key] = level;
      }
      _hasChanges = _detectChanges();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    // Build capabilities dict excluding 'none' (remove means no access)
    final Map<String, String> capabilitiesToSave = {};
    for (final entry in _capabilityLevels.entries) {
      if (entry.value != 'none') {
        capabilitiesToSave[entry.key] = entry.value;
      }
    }

    final notifier = ref.read(customRoleProvider.notifier);
    final success = await notifier.updateCustomRole(
      widget.customRoleId,
      roleName: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      capabilities: capabilitiesToSave,
    );

    setState(() => _saving = false);

    if (mounted) {
      if (success) {
        _originalName = _nameController.text;
        _originalDesc = _descController.text;
        _originalLevels = Map.from(_capabilityLevels);
        setState(() => _hasChanges = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        final err = ref.read(customRoleProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role${err != null ? ': $err' : ''}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_hasChanges) {
                final leave = await _showUnsavedDialog();
                if (leave && context.mounted) context.pop();
              } else {
                context.pop();
              }
            },
          ),
          title: const Text('Edit Custom Role'),
          actions: [
            if (_hasChanges && !_saving)
              TextButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : _buildBody(),
        bottomNavigationBar: (!_loading && _error == null)
            ? _buildBottomBar()
            : null,
      );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load role',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        // Role Info Card
        SliverToBoxAdapter(child: _buildRoleInfoCard()),

        // Capabilities Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.security,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Capabilities',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_capabilityLevels.values.where((v) => v != 'none').length} / ${_capabilityLevels.length} enabled',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // Category Sections
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final category = _byCategory.keys.elementAt(index);
              return _CategorySection(
                category: category,
                capabilities: _byCategory[category]!,
                capabilityLevels: _capabilityLevels,
                onLevelChanged: _onLevelChanged,
                onSetAll: (level) => _setCategoryLevel(category, level),
              );
            },
            childCount: _byCategory.length,
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildRoleInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Role Information',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Role Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                onChanged: (_) => setState(() => _hasChanges = _detectChanges()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Role name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                onChanged: (_) => setState(() => _hasChanges = _detectChanges()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: (_saving || !_hasChanges) ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showUnsavedDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
                'You have unsaved changes. Do you want to leave without saving?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ─── Category Section ─────────────────────────────────────────────────────────
class _CategorySection extends StatefulWidget {
  final String category;
  final List<Map<String, dynamic>> capabilities;
  final Map<String, String> capabilityLevels;
  final void Function(String key, String level) onLevelChanged;
  final void Function(String level) onSetAll;

  const _CategorySection({
    required this.category,
    required this.capabilities,
    required this.capabilityLevels,
    required this.onLevelChanged,
    required this.onSetAll,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = false;

  String get _categoryLabel =>
      _categoryMeta[widget.category]?.label ??
      widget.category.replaceAll('_', ' ');

  IconData get _categoryIcon =>
      _categoryMeta[widget.category]?.icon ?? Icons.category;

  int get _enabledCount => widget.capabilities
      .where((c) =>
          (widget.capabilityLevels[c['capability_key'] as String] ?? 'none') !=
          'none')
      .length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = _enabledCount;
    final total = widget.capabilities.length;
    final allEnabled = enabled == total;
    final noneEnabled = enabled == 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_categoryIcon, color: colorScheme.onPrimaryContainer, size: 20),
        ),
        title: Text(
          _categoryLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$enabled / $total capabilities enabled',
          style: TextStyle(
            fontSize: 12,
            color: enabled > 0 ? Colors.green[700] : Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick action buttons
            if (_expanded) ...[
              _QuickActionButton(
                label: 'None',
                active: noneEnabled,
                onTap: () => widget.onSetAll('none'),
                color: _levelColors['none']!,
              ),
              const SizedBox(width: 4),
              _QuickActionButton(
                label: 'All',
                active: allEnabled,
                onTap: () => widget.onSetAll('full'),
                color: _levelColors['full']!,
              ),
              const SizedBox(width: 8),
            ],
            Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
        onExpansionChanged: (v) => setState(() => _expanded = v),
        children: widget.capabilities
            .map((cap) => _CapabilityRow(
                  capability: cap,
                  currentLevel:
                      widget.capabilityLevels[cap['capability_key'] as String] ??
                          'none',
                  onChanged: (newLevel) => widget.onLevelChanged(
                      cap['capability_key'] as String, newLevel),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Capability Row ───────────────────────────────────────────────────────────
class _CapabilityRow extends StatelessWidget {
  final Map<String, dynamic> capability;
  final String currentLevel;
  final void Function(String) onChanged;

  const _CapabilityRow({
    required this.capability,
    required this.currentLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final name = capability['capability_name'] as String? ?? '';
    final description = capability['description'] as String? ?? '';
    final isSystemCritical = capability['is_system_critical'] as bool? ?? false;
    final availableLevels =
        (capability['access_levels'] as List<dynamic>?)?.cast<String>() ??
            _accessLevels;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        color: currentLevel != 'none'
            ? (_levelColors[currentLevel] ?? Colors.grey).withOpacity(0.05)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (isSystemCritical) ...[
                      const SizedBox(width: 6),
                      const Tooltip(
                        message: 'System critical – restricted to super admin',
                        child: Icon(Icons.lock, size: 14, color: Colors.red),
                      ),
                    ],
                  ],
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _LevelSelector(
            currentLevel: currentLevel,
            availableLevels: availableLevels,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Level Selector ───────────────────────────────────────────────────────────
class _LevelSelector extends StatelessWidget {
  final String currentLevel;
  final List<String> availableLevels;
  final void Function(String) onChanged;

  const _LevelSelector({
    required this.currentLevel,
    required this.availableLevels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (_levelColors[currentLevel] ?? Colors.grey).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (_levelColors[currentLevel] ?? Colors.grey).withOpacity(0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLevel,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          items: availableLevels.map((level) {
            final color = _levelColors[level] ?? Colors.grey;
            return DropdownMenuItem<String>(
              value: level,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _levelLabels[level] ?? level,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─── Quick Action Button ──────────────────────────────────────────────────────
class _QuickActionButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionButton({
    required this.label,
    required this.active,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
