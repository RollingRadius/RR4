import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/organization_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/data/services/organization_api.dart';

class OrganizationManagementScreen extends ConsumerStatefulWidget {
  final String organizationId;
  final String organizationName;

  const OrganizationManagementScreen({
    super.key,
    required this.organizationId,
    required this.organizationName,
  });

  @override
  ConsumerState<OrganizationManagementScreen> createState() =>
      _OrganizationManagementScreenState();
}

class _OrganizationManagementScreenState
    extends ConsumerState<OrganizationManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _pendingUsers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orgApi = ref.read(organizationApiProvider);

      // Load members and pending users in parallel
      final results = await Future.wait([
        orgApi.getOrganizationMembers(widget.organizationId, includePending: false),
        orgApi.getPendingUsers(widget.organizationId),
      ]);

      print('Members response: ${results[0]}');
      print('Pending users response: ${results[1]}');

      if (mounted) {
        final pendingUsersList = List<Map<String, dynamic>>.from(results[1]['pending_users'] ?? []);
        print('Pending users count: ${pendingUsersList.length}');

        setState(() {
          _members = List<Map<String, dynamic>>.from(results[0]['members'] ?? []);
          _pendingUsers = pendingUsersList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading organization data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load organization data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveUser(String userId, String username) async {
    // Show role selection dialog
    final roleKey = await showDialog<String>(
      context: context,
      builder: (context) => _RoleSelectionDialog(
        title: 'Approve $username',
        subtitle: 'Select a role to assign:',
      ),
    );

    if (roleKey != null && mounted) {
      setState(() => _isLoading = true);

      try {
        final orgApi = ref.read(organizationApiProvider);
        await orgApi.approveUser(widget.organizationId, userId, roleKey);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$username approved successfully')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to approve user: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }


  Future<void> _rejectUser(String userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Text('Are you sure you want to reject $username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      try {
        final orgApi = ref.read(organizationApiProvider);
        await orgApi.rejectUser(widget.organizationId, userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$username rejected')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject user: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _changeUserRole(String userId, String username, String currentRole) async {
    final roleKey = await showDialog<String>(
      context: context,
      builder: (context) => _RoleSelectionDialog(
        title: 'Change Role for $username',
        subtitle: 'Current role: $currentRole\n\nSelect new role:',
      ),
    );

    if (roleKey != null && mounted) {
      setState(() => _isLoading = true);

      try {
        final orgApi = ref.read(organizationApiProvider);
        await orgApi.updateUserRole(widget.organizationId, userId, roleKey);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role updated successfully')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update role: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _removeUser(String userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User'),
        content: Text('Are you sure you want to remove $username from the organization?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      try {
        final orgApi = ref.read(organizationApiProvider);
        await orgApi.removeUser(widget.organizationId, userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$username removed from organization')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove user: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.organizationName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              'Organization Management',
              style: TextStyle(fontSize: 12, color: Colors.grey[300]),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.people),
              text: 'Members (${_members.length})',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _pendingUsers.isNotEmpty,
                label: Text(_pendingUsers.length.toString()),
                child: const Icon(Icons.pending_actions),
              ),
              text: 'Pending (${_pendingUsers.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMembersTab(),
                    _buildPendingTab(),
                  ],
                ),
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No members found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final isOwner = member['role_key'] == 'owner';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isOwner
                    ? Colors.amber
                    : Theme.of(context).primaryColor.withOpacity(0.2),
                child: Text(
                  member['username']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: TextStyle(
                    color: isOwner ? Colors.white : Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                member['full_name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member['username'] ?? ''),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(
                      member['role'] ?? 'No Role',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: isOwner ? Colors.amber : Colors.blue.shade100,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ],
              ),
              trailing: !isOwner
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'change_role') {
                          _changeUserRole(
                            member['user_id'],
                            member['username'],
                            member['role'],
                          );
                        } else if (value == 'remove') {
                          _removeUser(member['user_id'], member['username']);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'change_role',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz),
                              SizedBox(width: 8),
                              Text('Change Role'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.remove_circle_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Remove', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error loading pending users'),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pendingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('No pending approvals'),
            const SizedBox(height: 8),
            Text(
              'Users who request to join will appear here',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingUsers.length,
        itemBuilder: (context, index) {
          final user = _pendingUsers[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withOpacity(0.2),
                child: Text(
                  user['username']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                user['full_name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['username'] ?? ''),
                  const SizedBox(height: 4),
                  if (user['requested_role'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Requested: ${user['requested_role']}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'] ?? user['phone'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _approveUser(user['user_id'], user['username']),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _rejectUser(user['user_id'], user['username']),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Role selection dialog with all available roles
class _RoleSelectionDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const _RoleSelectionDialog({
    required this.title,
    required this.subtitle,
  });

  @override
  State<_RoleSelectionDialog> createState() => _RoleSelectionDialogState();
}

class _RoleSelectionDialogState extends State<_RoleSelectionDialog> {
  String? _selectedRole;

  // Currently available roles in the backend
  final List<Map<String, dynamic>> _roles = [
    {
      'key': 'admin',
      'name': 'Admin',
      'icon': Icons.admin_panel_settings,
      'color': Colors.red,
      'description': 'Can manage members and settings',
    },
    {
      'key': 'dispatcher',
      'name': 'Dispatcher',
      'icon': Icons.assignment_ind,
      'color': Colors.purple,
      'description': 'Can manage trips and assignments',
    },
    {
      'key': 'user',
      'name': 'User',
      'icon': Icons.person,
      'color': Colors.blue,
      'description': 'Standard access to features',
    },
    {
      'key': 'viewer',
      'name': 'Viewer',
      'icon': Icons.visibility,
      'color': Colors.grey,
      'description': 'Read-only access',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _roles.map((role) => _buildRoleOption(role)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedRole != null
              ? () => Navigator.of(context).pop(_selectedRole)
              : null,
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildRoleOption(Map<String, dynamic> role) {
    final isSelected = _selectedRole == role['key'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? role['color'].withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? role['color'] : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: role['color'].withOpacity(0.2),
          child: Icon(
            role['icon'],
            color: role['color'],
            size: 20,
          ),
        ),
        title: Text(
          role['name'],
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          role['description'],
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: role['color'])
            : null,
        onTap: () {
          setState(() {
            _selectedRole = role['key'];
          });
        },
      ),
    );
  }
}
