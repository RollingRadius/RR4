import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/models/role_model.dart';
import 'package:fleet_management/providers/role_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? profileData;

  const RoleSelectionScreen({
    super.key,
    this.profileData,
  });

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  RoleModel? _selectedRole;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load available roles when screen loads
    Future.microtask(
      () => ref.read(rolesProvider.notifier).loadAvailableRoles(),
    );
  }

  List<RoleModel> _filterRoles(List<RoleModel> roles) {
    if (_searchQuery.isEmpty) return roles;

    return roles.where((role) {
      final nameLower = role.roleName.toLowerCase();
      final descLower = (role.description ?? '').toLowerCase();
      final queryLower = _searchQuery.toLowerCase();

      return nameLower.contains(queryLower) || descLower.contains(queryLower);
    }).toList();
  }

  void _handleContinue() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Return selected role to previous screen
    Navigator.of(context).pop({
      'requested_role_id': _selectedRole!.id,
      'requested_role_name': _selectedRole!.roleName,
    });
  }

  @override
  Widget build(BuildContext context) {
    final rolesState = ref.watch(rolesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Role',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the role that best describes your responsibilities. The organization owner will review and approve your request.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search roles...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Roles List
          Expanded(
            child: rolesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : rolesState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              rolesState.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(rolesProvider.notifier)
                                    .loadAvailableRoles();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildRolesList(rolesState.roles),
          ),

          // Continue Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedRole == null
                      ? 'Select a Role to Continue'
                      : 'Continue with ${_selectedRole!.roleName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList(List<RoleModel> roles) {
    final filteredRoles = _filterRoles(roles);

    if (filteredRoles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No roles found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: filteredRoles.length,
      itemBuilder: (context, index) {
        final role = filteredRoles[index];
        final isAvailable = role.roleKey == 'logistic_partner';
        final isSelected = _selectedRole?.id == role.id;

        return StaggeredItem(
          index: index,
          staggerMs: 60,
          child: Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
          child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: isAvailable
                ? () {
                    setState(() {
                      _selectedRole = role;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Role Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getRoleIcon(role.roleKey),
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Role Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.roleName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.black87,
                          ),
                        ),
                        if (role.description != null &&
                            role.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            role.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Selection Indicator or Coming Soon badge
                  if (!isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  else if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    )
                  else
                    Icon(
                      Icons.circle_outlined,
                      color: Colors.grey[400],
                      size: 28,
                    ),
                ],
              ),
            ),
          ),
        ),  // closes Card
        ),  // closes Opacity
        );
      },
    );
  }

  IconData _getRoleIcon(String roleKey) {
    switch (roleKey.toLowerCase()) {
      case 'logistic_partner':
      case 'fleet_manager':
        return Icons.local_shipping_rounded;
      case 'load_owner':
        return Icons.inventory_2_outlined;
      case 'transporter':
        return Icons.airport_shuttle_rounded;
      case 'driver':
        return Icons.drive_eta_rounded;
      case 'logistic_partner_worker':
        return Icons.engineering_rounded;
      case 'lp_rr_operations':
        return Icons.sync_alt_rounded;
      case 'load_receiver':
        return Icons.warehouse_outlined;
      case 'super_admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}
