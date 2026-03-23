import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/organization_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/data/services/organization_api.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

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
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text.toLowerCase()));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final orgApi = ref.read(organizationApiProvider);
      final results = await Future.wait([
        orgApi.getOrganizationMembers(widget.organizationId,
            includePending: false),
        orgApi.getPendingUsers(widget.organizationId),
      ]);
      if (mounted) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(
              results[0]['members'] ?? []);
          _pendingUsers = List<Map<String, dynamic>>.from(
              results[1]['pending_users'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load organization data.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveUser(String userId, String username) async {
    final roleKey = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _RoleSelectionDialog(
        title: 'Approve $username',
        subtitle: 'Select a role to assign',
      ),
    );
    if (roleKey != null && mounted) {
      setState(() => _isLoading = true);
      try {
        final orgApi = ref.read(organizationApiProvider);
        await orgApi.approveUser(widget.organizationId, userId, roleKey);
        if (mounted) {
          _showSnack('$username approved successfully', Colors.green);
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          _showSnack('Failed to approve user: $e', Colors.red);
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _rejectUser(String userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject User'),
        content: Text('Reject $username\'s request to join?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
          _showSnack('$username rejected', Colors.orange);
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          _showSnack('Failed to reject: $e', Colors.red);
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _changeUserRole(
      String userId, String username, String currentRole) async {
    final roleKey = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _RoleSelectionDialog(
        title: 'Change Role',
        subtitle: 'New role for $username',
      ),
    );
    if (roleKey != null && mounted) {
      setState(() => _isLoading = true);
      try {
        final orgApi = ref.read(organizationApiProvider);
        await orgApi.updateUserRole(widget.organizationId, userId, roleKey);
        if (mounted) {
          _showSnack('Role updated successfully', Colors.green);
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          _showSnack('Failed to update role: $e', Colors.red);
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _removeUser(String userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
            'Remove $username from ${widget.organizationName}? They will lose access immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
          _showSnack('$username removed', Colors.green);
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          _showSnack('Failed to remove: $e', Colors.red);
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  List<Map<String, dynamic>> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;
    return _members.where((m) {
      final name = (m['full_name'] as String? ?? '').toLowerCase();
      final username = (m['username'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery) || username.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orgInitial = widget.organizationName.isNotEmpty
        ? widget.organizationName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: theme.primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              widget.organizationName,
              style: const TextStyle(color: Colors.white, fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: _isLoading ? null : _loadData,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context, orgInitial),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: theme.primaryColor,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.people_outline, size: 18),
                      text: 'Members (${_members.length})',
                    ),
                    Tab(
                      icon: _pendingUsers.isNotEmpty
                          ? Badge(
                              label: Text('${_pendingUsers.length}'),
                              backgroundColor: Colors.red.shade300,
                              child: const Icon(
                                  Icons.pending_actions_outlined,
                                  size: 18),
                            )
                          : const Icon(Icons.pending_actions_outlined,
                              size: 18),
                      text: 'Pending (${_pendingUsers.length})',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMembersTab(),
                      _buildPendingTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String initial) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -15,
            child: Icon(Icons.corporate_fare,
                size: 150, color: Colors.white.withOpacity(0.06)),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.organizationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_members.length} members · ${_pendingUsers.length} pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Members Tab ─────────────────────────────────────────────────────────────

  Widget _buildMembersTab() {
    final filtered = _filteredMembers;
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(
                  icon: Icons.people_outline,
                  title: _searchQuery.isNotEmpty
                      ? 'No results for "$_searchQuery"'
                      : 'No members yet',
                  subtitle: _searchQuery.isNotEmpty
                      ? null
                      : 'Members will appear here',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => StaggeredItem(
                      index: index,
                      staggerMs: 60,
                      child: _MemberCard(
                        member: filtered[index],
                        onChangeRole: (m) => _changeUserRole(
                          m['user_id'],
                          m['username'],
                          m['role'] ?? '',
                        ),
                        onRemove: (m) =>
                            _removeUser(m['user_id'], m['username']),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
            bottom:
                BorderSide(color: theme.dividerColor.withOpacity(0.4))),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search members…',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon:
              Icon(Icons.search, size: 20, color: Colors.grey[400]),
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
    );
  }

  // ── Pending Tab ─────────────────────────────────────────────────────────────

  Widget _buildPendingTab() {
    if (_pendingUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        title: 'All caught up!',
        subtitle: 'No pending join requests',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _pendingUsers.length,
        itemBuilder: (context, index) {
          final user = _pendingUsers[index];
          return StaggeredItem(
            index: index,
            staggerMs: 70,
            child: _PendingCard(
              user: user,
              onApprove: () =>
                  _approveUser(user['user_id'], user['username']),
              onReject: () =>
                  _rejectUser(user['user_id'], user['username']),
            ),
          );
        },
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.error_outline,
                  size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(_error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
  }) {
    final color = iconColor ?? Colors.grey[400]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: color.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600])),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ],
      ),
    );
  }
}

// ─── Member Card ──────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final void Function(Map<String, dynamic>) onChangeRole;
  final void Function(Map<String, dynamic>) onRemove;

  const _MemberCard({
    required this.member,
    required this.onChangeRole,
    required this.onRemove,
  });

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
      Color(0xFFE65100),
      Color(0xFF37474F),
      Color(0xFFC62828),
      Color(0xFF0277BD),
    ];
    return colors[name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = member['full_name'] as String? ?? 'Unknown';
    final username = member['username'] as String? ?? '';
    final role = member['role'] as String? ?? 'No Role';
    final roleKey = member['role_key'] as String? ?? '';
    final isOwner = roleKey == 'fleet_management' || roleKey == 'load_owner';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    final color = _avatarColor(fullName);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOwner
              ? Colors.amber.withOpacity(0.4)
              : theme.dividerColor.withOpacity(0.35),
        ),
      ),
      color: isOwner ? Colors.amber.withOpacity(0.03) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isOwner
                    ? Colors.amber.withOpacity(0.15)
                    : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOwner
                      ? Colors.amber.withOpacity(0.4)
                      : color.withOpacity(0.25),
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isOwner ? Colors.amber[800] : color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 5),
                  _RoleChipSmall(role: role, isOwner: isOwner),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Action
            if (isOwner)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 13, color: Colors.amber[800]),
                    const SizedBox(width: 4),
                    Text(
                      'Owner',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                    ),
                  ],
                ),
              )
            else
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'change_role') onChangeRole(member);
                  if (v == 'remove') onRemove(member);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'change_role',
                    child: Row(children: [
                      Icon(Icons.swap_horiz_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Change Role'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(children: [
                      Icon(Icons.person_remove_outlined,
                          size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Remove',
                          style: TextStyle(color: Colors.red)),
                    ]),
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
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending Card ─────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = user['full_name'] as String? ?? 'Unknown';
    final username = user['username'] as String? ?? '';
    final email = user['email'] as String?;
    final phone = user['phone'] as String?;
    final requestedRole = user['requested_role'] as String?;
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
      color: Colors.orange.withOpacity(0.02),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.orange.withOpacity(0.15),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@$username',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                // Pending badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),

            // Contact + requested role
            if (email != null || phone != null || requestedRole != null) ...[
              const SizedBox(height: 10),
              if (email != null)
                _infoRow(Icons.email_outlined, email),
              if (phone != null)
                _infoRow(Icons.phone_outlined, phone),
              if (requestedRole != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: theme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge_outlined,
                          size: 14, color: theme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Requested: $requestedRole',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve & Assign Role'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Role Chip (small) ────────────────────────────────────────────────────────

class _RoleChipSmall extends StatelessWidget {
  final String role;
  final bool isOwner;

  const _RoleChipSmall({required this.role, required this.isOwner});

  Color get _color {
    if (isOwner) return Colors.amber;
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'dispatcher':
        return Colors.purple;
      case 'fleet_manager':
        return Colors.blue;
      case 'driver':
        return Colors.orange;
      case 'accountant':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

// ─── Role Selection Dialog ────────────────────────────────────────────────────

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

  final List<Map<String, dynamic>> _roles = [
    {
      'key': 'admin',
      'name': 'Admin',
      'icon': Icons.admin_panel_settings_outlined,
      'color': Colors.red,
      'description': 'Manage members & settings',
    },
    {
      'key': 'dispatcher',
      'name': 'Dispatcher',
      'icon': Icons.assignment_ind_outlined,
      'color': Colors.purple,
      'description': 'Manage trips & assignments',
    },
    {
      'key': 'user',
      'name': 'User',
      'icon': Icons.person_outline,
      'color': Colors.blue,
      'description': 'Standard access to features',
    },
    {
      'key': 'viewer',
      'name': 'Viewer',
      'icon': Icons.visibility_outlined,
      'color': Colors.blueGrey,
      'description': 'Read-only access',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.badge_outlined,
                      color: theme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Role options
            ..._roles.map((role) {
              final isSelected = _selectedRole == role['key'];
              final color = role['color'] as Color;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedRole = role['key']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(role['icon'] as IconData,
                            color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role['name'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected ? color : null,
                              ),
                            ),
                            Text(
                              role['description'] as String,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              size: 12, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedRole != null
                        ? () => Navigator.of(context).pop(_selectedRole)
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Assign Role'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
