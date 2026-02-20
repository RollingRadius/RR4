import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/profile_provider.dart';
import 'package:fleet_management/providers/company_provider.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditMode = false;

  // Text controllers for editable fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load profile status when screen loads
    Future.microtask(() {
      ref.read(profileProvider.notifier).getProfileStatus();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      if (!_isEditMode) {
        // Entering edit mode - populate controllers
        final profileState = ref.read(profileProvider);
        final authState = ref.read(authProvider);
        _fullNameController.text = profileState.profileData?['full_name'] ?? authState.user?.fullName ?? '';
        _emailController.text = profileState.profileData?['email'] ?? authState.user?.email ?? '';
        _phoneController.text = profileState.profileData?['phone'] ?? authState.user?.phone ?? '';
      }
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _saveProfile() async {
    // Validate inputs
    if (_fullNameController.text.trim().isEmpty) {
      _showError('Full name is required');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError('Email is required');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('Phone is required');
      return;
    }

    // Build update data
    final updateData = {
      'full_name': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    // Call API to update profile
    final success = await ref.read(profileProvider.notifier).updateProfile(updateData);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Refresh profile
        ref.read(profileProvider.notifier).getProfileStatus();
        ref.read(authProvider.notifier).loadUserProfile();

        setState(() {
          _isEditMode = false;
        });
      } else {
        final error = ref.read(profileProvider).error;
        _showError(error ?? 'Failed to update profile');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
              onPressed: _toggleEditMode,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: _toggleEditMode,
            ),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save',
              onPressed: _saveProfile,
            ),
          ],
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageEntrance(
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  ScaleFade(
                    delay: 0,
                    duration: 600,
                    child: Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                user?.username.substring(0, 2).toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (_isEditMode)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                    onPressed: () {
                                      // TODO: Implement photo upload
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Photo upload coming soon!')),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profileState.profileData?['full_name'] ?? user?.fullName ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user?.username ?? 'username'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),  // closes Center
                ),    // closes ScaleFade
                const SizedBox(height: 32),

                  // Edit Mode Banner
                  if (_isEditMode)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Edit mode active. Make your changes and tap the check icon to save.',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Profile Information Card
                  StaggeredItem(index: 0, staggerMs: 120, baseDelay: 200, child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Full Name
                          _isEditMode
                              ? TextField(
                                  controller: _fullNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                                    border: const OutlineInputBorder(),
                                  ),
                                )
                              : _buildInfoRow(
                                  Icons.person_outline,
                                  'Full Name',
                                  profileState.profileData?['full_name'] ?? user?.fullName ?? 'N/A',
                                ),
                          SizedBox(height: _isEditMode ? 16 : 0),
                          if (!_isEditMode) const Divider(height: 24),

                          // Username (non-editable)
                          _buildInfoRow(
                            Icons.alternate_email,
                            'Username',
                            user?.username ?? 'N/A',
                          ),
                          const Divider(height: 24),

                          // Email
                          _isEditMode
                              ? TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
                                    border: const OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                )
                              : _buildInfoRow(
                                  Icons.email_outlined,
                                  'Email',
                                  profileState.profileData?['email'] ?? user?.email ?? 'N/A',
                                ),
                          SizedBox(height: _isEditMode ? 16 : 0),
                          if (!_isEditMode) const Divider(height: 24),

                          // Phone
                          _isEditMode
                              ? TextField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Phone',
                                    prefixIcon: Icon(Icons.phone_outlined, color: Theme.of(context).primaryColor),
                                    border: const OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                )
                              : _buildInfoRow(
                                  Icons.phone_outlined,
                                  'Phone',
                                  profileState.profileData?['phone'] ?? user?.phone ?? 'N/A',
                                ),
                        ],
                      ),
                    ),
                  )),  // closes Personal Info Card + StaggeredItem
                  const SizedBox(height: 16),

                  // Role & Company Card
                  StaggeredItem(index: 1, staggerMs: 120, baseDelay: 200, child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Role & Organization',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if ((profileState.profileData?['role_type'] == 'independent' ||
                                      profileState.profileData?['role_type'] == 'pending_user') &&
                                  !_isEditMode)
                                TextButton.icon(
                                  onPressed: () => _showChangeRoleDialog(),
                                  icon: const Icon(Icons.swap_horiz, size: 18),
                                  label: const Text('Change Role'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.badge_outlined,
                            'Role',
                            profileState.profileData?['role'] ?? user?.role ?? 'Not assigned',
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.business_outlined,
                            'Company',
                            profileState.profileData?['company_name'] ?? user?.companyName ?? 'None',
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.verified_user_outlined,
                            'Profile Status',
                            profileState.profileCompleted ? 'Completed' : 'Incomplete',
                            valueColor: profileState.profileCompleted ? Colors.green : Colors.orange,
                          ),

                          // Role change options for Independent Users
                          if (profileState.profileCompleted &&
                              profileState.profileData?['role_type'] == 'independent' &&
                              !_isEditMode)
                            _buildRoleChangeOptions(
                              headerText: 'As an Independent User, you can:',
                              buttons: [
                                _buildRoleChangeButton('Join Organization', Icons.business,
                                    () => _showJoinOrganizationDialog()),
                                _buildRoleChangeButton('Create Organization', Icons.add_business,
                                    () => context.push('/organizations/create')),
                                _buildRoleChangeButton('Become Driver', Icons.local_shipping,
                                    () => _showBecomeDriverDialog()),
                              ],
                            )
                          // Role change options for Pending Users
                          else if (profileState.profileCompleted &&
                              profileState.profileData?['role_type'] == 'pending_user' &&
                              !_isEditMode)
                            _buildRoleChangeOptions(
                              headerText: 'Your request is pending approval. You can:',
                              headerColor: Colors.orange,
                              buttons: [
                                _buildRoleChangeButton('Change Organization', Icons.swap_horiz,
                                    () => _showJoinOrganizationDialog()),
                                _buildRoleChangeButton('Create Organization', Icons.add_business,
                                    () => context.push('/organizations/create')),
                                _buildRoleChangeButton('Go Back to Independent', Icons.person_outline,
                                    () => _confirmGoIndependent()),
                              ],
                            )
                          // Role is managed by org (active members, owners, drivers, etc.)
                          else if (profileState.profileCompleted && !_isEditMode)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your role is managed by your organization.',
                                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )),  // closes Role & Company Card + StaggeredItem
                  const SizedBox(height: 16),

                  // Account Status Card
                  StaggeredItem(index: 2, staggerMs: 120, baseDelay: 200, child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.security_outlined,
                            'Auth Method',
                            user?.authMethod == 'email' ? 'Email' : 'Security Questions',
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.check_circle_outline,
                            'Status',
                            user?.status ?? 'Unknown',
                            valueColor: user?.status == 'active' ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),

                  ),  // closes StaggeredItem for Account Status Card
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),  // closes PageEntrance
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
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
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChangeButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildRoleChangeOptions({
    required String headerText,
    required List<Widget> buttons,
    Color? headerColor,
  }) {
    final color = headerColor ?? Colors.green;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headerText,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: buttons),
          ],
        ),
      ),
    );
  }

  void _confirmGoIndependent() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Pending Request?'),
        content: const Text(
          'This will cancel your pending organization request and return you to Independent User status. You can join or create an organization again at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Pending'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(profileProvider.notifier)
                  .changeRole({'role_type': 'independent'});
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('You are now an Independent User.'),
                        ],
                      ),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                  ref.read(profileProvider.notifier).getProfileStatus();
                  ref.read(authProvider.notifier).loadUserProfile();
                } else {
                  final error = ref.read(profileProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Failed to update role'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Go Independent'),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog() {
    final isPending =
        ref.read(profileProvider).profileData?['role_type'] == 'pending_user';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Role'),
        content: Text(isPending
            ? 'Your request is pending. What would you like to do?'
            : 'Choose how you want to change your role:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (!isPending)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showBecomeDriverDialog();
              },
              child: const Text('Become Driver'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showJoinOrganizationDialog();
            },
            child: Text(isPending ? 'Change Organization' : 'Join Organization'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/organizations/create');
            },
            child: const Text('Create Organization'),
          ),
          if (isPending)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _confirmGoIndependent();
              },
              child: const Text('Go Independent', style: TextStyle(color: Colors.orange)),
            ),
        ],
      ),
    );
  }

  static const List<Map<String, String>> _predefinedRoles = [
    {'key': 'fleet_manager', 'label': 'Fleet Manager'},
    {'key': 'dispatcher', 'label': 'Dispatcher'},
    {'key': 'driver', 'label': 'Driver'},
    {'key': 'accountant', 'label': 'Accountant'},
    {'key': 'maintenance_manager', 'label': 'Maintenance Manager'},
    {'key': 'compliance_officer', 'label': 'Compliance Officer'},
    {'key': 'operations_manager', 'label': 'Operations Manager'},
    {'key': 'maintenance_technician', 'label': 'Maintenance Technician'},
    {'key': 'customer_service', 'label': 'Customer Service'},
    {'key': 'viewer_analyst', 'label': 'Viewer / Analyst'},
  ];

  void _showJoinOrganizationDialog() {
    final searchController = TextEditingController();
    List<dynamic> searchResults = [];   // local list — no provider reads inside builder
    String? selectedCompanyId;
    String? selectedCompanyName;
    String? selectedRoleKey;
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
          return AlertDialog(
            title: const Text('Join Organization'),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Search field ─────────────────────────────────────
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Search Company',
                      hintText: 'Enter at least 3 characters',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) async {
                      if (value.trim().length < 3) {
                        setDialogState(() => searchResults = []);
                        return;
                      }
                      setDialogState(() => isSearching = true);
                      try {
                        await ref
                            .read(companyProvider.notifier)
                            .searchCompanies(value.trim());
                        final results = ref.read(companyProvider).searchResults;
                        setDialogState(() {
                          searchResults = results;
                          isSearching = false;
                        });
                      } catch (_) {
                        setDialogState(() {
                          searchResults = [];
                          isSearching = false;
                        });
                      }
                    },
                  ),
                  // ── Results list ──────────────────────────────────────
                  if (searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(8),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final company = searchResults[i];
                            final isSel = selectedCompanyId == company.id;
                            return ListTile(
                              dense: true,
                              selected: isSel,
                              selectedTileColor: Colors.green.shade50,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: isSel
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                child: Icon(
                                  isSel ? Icons.check : Icons.business,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(company.companyName,
                                  style: const TextStyle(fontSize: 14)),
                              subtitle: Text(
                                  '${company.city}, ${company.state}',
                                  style: const TextStyle(fontSize: 12)),
                              onTap: () => setDialogState(() {
                                selectedCompanyId = company.id;
                                selectedCompanyName = company.companyName;
                              }),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  // ── Selected company chip ─────────────────────────────
                  if (selectedCompanyName != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedCompanyName!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // ── Role dropdown ─────────────────────────────────────
                  const SizedBox(height: 14),
                  const Text('Requested Role (Optional)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: selectedRoleKey,
                    isExpanded: true,
                    hint: const Text('No preference'),
                    underline: Container(
                        height: 1, color: Colors.grey.shade400),
                    items: [
                      const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No preference')),
                      ..._predefinedRoles.map((r) =>
                          DropdownMenuItem<String>(
                              value: r['key'],
                              child: Text(r['label']!))),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedRoleKey = v),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedCompanyId == null
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        final profileData = {
                          'role_type': 'join_company',
                          'company_id': selectedCompanyId,
                          if (selectedRoleKey != null)
                            'requested_role_key': selectedRoleKey,
                        };
                        final success = await ref
                            .read(profileProvider.notifier)
                            .changeRole(profileData);
                        if (mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.white),
                                  SizedBox(width: 12),
                                  Text(
                                      'Join request submitted! Awaiting approval.'),
                                ]),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                            ref
                                .read(profileProvider.notifier)
                                .getProfileStatus();
                            ref
                                .read(authProvider.notifier)
                                .loadUserProfile();
                          } else {
                            final error =
                                ref.read(profileProvider).error;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    error ?? 'Failed to join organization'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBecomeDriverDialog() {
    final licenseNumberController = TextEditingController();
    final licenseExpiryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Become a Driver'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your driver license details:'),
              const SizedBox(height: 16),
              TextField(
                controller: licenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: licenseExpiryController,
                decoration: const InputDecoration(
                  labelText: 'License Expiry (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: '2027-12-31',
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
          FilledButton(
            onPressed: () async {
              if (licenseNumberController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter license number')),
                );
                return;
              }
              if (licenseExpiryController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter license expiry date')),
                );
                return;
              }

              Navigator.pop(context);

              final profileData = {
                'role_type': 'driver',
                'license_number': licenseNumberController.text.trim(),
                'license_expiry': licenseExpiryController.text.trim(),
              };

              final success = await ref.read(profileProvider.notifier).changeRole(profileData);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Role changed to Driver successfully!'),
                        ],
                      ),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                  // Refresh profile status
                  ref.read(profileProvider.notifier).getProfileStatus();
                  // Refresh auth state
                  ref.read(authProvider.notifier).loadUserProfile();
                } else {
                  final error = ref.read(profileProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Failed to change role'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
