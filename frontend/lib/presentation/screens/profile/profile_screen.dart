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

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditMode = false;
  bool _isSaving = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.microtask(() {
      ref.read(profileProvider.notifier).getProfileStatus();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      if (!_isEditMode) {
        final profileState = ref.read(profileProvider);
        final authState = ref.read(authProvider);
        _fullNameController.text =
            profileState.profileData?['full_name'] ?? authState.user?.fullName ?? '';
        _emailController.text =
            profileState.profileData?['email'] ?? authState.user?.email ?? '';
        _phoneController.text =
            profileState.profileData?['phone'] ?? authState.user?.phone ?? '';
      }
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _saveProfile() async {
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

    setState(() => _isSaving = true);

    final updateData = {
      'full_name': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    final success = await ref.read(profileProvider.notifier).updateProfile(updateData);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Profile updated successfully!'),
            ]),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(profileProvider.notifier).getProfileStatus();
        ref.read(authProvider.notifier).loadUserProfile();
        setState(() => _isEditMode = false);
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _isEditMode
                ? Row(
                    key: const ValueKey('edit-actions'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Cancel',
                        onPressed: _isSaving ? null : _toggleEditMode,
                      ),
                      _isSaving
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.check_rounded),
                              tooltip: 'Save',
                              onPressed: _saveProfile,
                            ),
                    ],
                  )
                : IconButton(
                    key: const ValueKey('view-action'),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Profile',
                    onPressed: _toggleEditMode,
                  ),
          ),
        ],
      ),
      body: profileState.isLoading
          ? _buildLoadingSkeleton()
          : PageEntrance(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Gradient Hero ──────────────────────────────
                    _buildProfileHero(user, profileState),

                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // ── Edit Mode Banner ───────────────────
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, -0.4),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutCubic,
                                )),
                                child: child,
                              ),
                            ),
                            child: _isEditMode
                                ? _buildEditBanner()
                                : const SizedBox.shrink(key: ValueKey('no-banner')),
                          ),
                          if (_isEditMode) const SizedBox(height: 12),

                          // ── Personal Information ───────────────
                          StaggeredItem(
                            index: 0,
                            staggerMs: 100,
                            baseDelay: 80,
                            child: _buildPersonalInfoCard(user, profileState),
                          ),
                          const SizedBox(height: 12),

                          // ── Role & Organization ────────────────
                          StaggeredItem(
                            index: 1,
                            staggerMs: 100,
                            baseDelay: 80,
                            child: _buildRoleCard(user, profileState),
                          ),
                          const SizedBox(height: 12),

                          // ── Account Status ─────────────────────
                          StaggeredItem(
                            index: 2,
                            staggerMs: 100,
                            baseDelay: 80,
                            child: _buildAccountCard(user),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HERO HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildProfileHero(user, profileState) {
    final isActive = user?.status == 'active';
    final _raw = (user?.username ?? 'U').toUpperCase();
    final initials = _raw.length >= 2 ? _raw.substring(0, 2) : _raw;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          // ── Avatar with pulse ring ───────────────────────────
          ScaleFade(
            delay: 80,
            duration: 500,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring for active users
                if (isActive)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, __) => Container(
                      width: 128 + (_pulseAnimation.value * 10),
                      height: 128 + (_pulseAnimation.value * 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(
                          0.18 - (_pulseAnimation.value * 0.14),
                        ),
                      ),
                    ),
                  ),

                // Avatar with shadow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppTheme.primaryBlueDark,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_isEditMode)
                        Positioned.fill(
                          child: ClipOval(
                            child: Container(
                              color: Colors.black.withOpacity(0.4),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Online status dot
                if (isActive)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.statusActive.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.statusActive,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Name ────────────────────────────────────────────
          FadeSlide(
            delay: 180,
            beginOffset: const Offset(0, 0.25),
            child: Text(
              profileState.profileData?['full_name'] ?? user?.fullName ?? 'User',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 4),

          // ── Username ─────────────────────────────────────────
          FadeSlide(
            delay: 240,
            beginOffset: const Offset(0, 0.25),
            child: Text(
              '@${user?.username ?? 'username'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.78),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Role chip ────────────────────────────────────────
          FadeSlide(
            delay: 300,
            beginOffset: const Offset(0, 0.25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    profileState.profileCompleted
                        ? Icons.verified_rounded
                        : Icons.pending_rounded,
                    size: 14,
                    color: profileState.profileCompleted
                        ? Colors.greenAccent.shade100
                        : Colors.amber.shade200,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    profileState.profileData?['role'] ?? user?.role ?? 'No Role',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  // ─────────────────────────────────────────────────────────────────────────
  // EDIT BANNER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEditBanner() {
    return Container(
      key: const ValueKey('edit-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.edit_note_rounded, color: Colors.orange.shade700, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Edit mode — tap ✓ in the toolbar to save changes',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARDS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPersonalInfoCard(user, profileState) {
    return _buildSectionCard(
      icon: Icons.person_rounded,
      title: 'Personal Information',
      color: AppTheme.primaryBlue,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: _isEditMode ? _buildEditFields() : _buildViewFields(user, profileState),
      ),
    );
  }

  Widget _buildViewFields(user, profileState) {
    return Column(
      key: const ValueKey('view-fields'),
      children: [
        _buildInfoTile(Icons.badge_rounded, 'Full Name',
            profileState.profileData?['full_name'] ?? user?.fullName ?? 'N/A'),
        _buildDivider(),
        _buildInfoTile(Icons.alternate_email_rounded, 'Username',
            user?.username ?? 'N/A'),
        _buildDivider(),
        _buildInfoTile(Icons.email_rounded, 'Email',
            profileState.profileData?['email'] ?? user?.email ?? 'N/A'),
        _buildDivider(),
        _buildInfoTile(Icons.phone_rounded, 'Phone',
            profileState.profileData?['phone'] ?? user?.phone ?? 'N/A'),
      ],
    );
  }

  Widget _buildEditFields() {
    return Column(
      key: const ValueKey('edit-fields'),
      children: [
        TextField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.badge_rounded),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_rounded),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            prefixIcon: Icon(Icons.phone_rounded),
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveProfile(),
        ),
      ],
    );
  }

  Widget _buildRoleCard(user, profileState) {
    return _buildSectionCard(
      icon: Icons.shield_rounded,
      title: 'Role & Organization',
      color: AppTheme.accentIndigo,
      trailing:
          (profileState.profileData?['role_type'] == 'independent' ||
                  profileState.profileData?['role_type'] == 'pending_user') &&
              !_isEditMode
          ? TextButton.icon(
              onPressed: _showChangeRoleDialog,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('Change'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      child: Column(
        children: [
          _buildInfoTile(Icons.badge_outlined, 'Role',
              profileState.profileData?['role'] ?? user?.role ?? 'Not assigned'),
          _buildDivider(),
          _buildInfoTile(Icons.business_rounded, 'Company',
              profileState.profileData?['company_name'] ?? user?.companyName ?? 'None'),
          _buildDivider(),
          _buildInfoTile(
            Icons.verified_user_rounded,
            'Profile Status',
            profileState.profileCompleted ? 'Completed' : 'Incomplete',
            valueColor:
                profileState.profileCompleted ? AppTheme.statusActive : AppTheme.statusWarning,
            chip: true,
          ),

          // Role action options
          if (profileState.profileCompleted &&
              profileState.profileData?['role_type'] == 'independent' &&
              !_isEditMode) ...[
            const SizedBox(height: 16),
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
            ),
          ] else if (profileState.profileCompleted &&
              profileState.profileData?['role_type'] == 'pending_user' &&
              !_isEditMode) ...[
            const SizedBox(height: 16),
            _buildRoleChangeOptions(
              headerText: 'Your request is pending approval. You can:',
              headerColor: Colors.orange,
              buttons: [
                _buildRoleChangeButton('Change Organization', Icons.swap_horiz,
                    () => _showJoinOrganizationDialog()),
                _buildRoleChangeButton('Create Organization', Icons.add_business,
                    () => context.push('/organizations/create')),
                _buildRoleChangeButton('Go Independent', Icons.person_outline,
                    () => _confirmGoIndependent()),
              ],
            ),
          ] else if (profileState.profileCompleted && !_isEditMode) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue.shade600, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your role is managed by your organization.',
                      style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountCard(user) {
    return _buildSectionCard(
      icon: Icons.security_rounded,
      title: 'Account Status',
      color: AppTheme.accentCyan,
      child: Column(
        children: [
          _buildInfoTile(
            Icons.lock_rounded,
            'Auth Method',
            user?.authMethod == 'email' ? 'Email & Password' : 'Security Questions',
          ),
          _buildDivider(),
          _buildInfoTile(
            Icons.circle_rounded,
            'Status',
            user?.status ?? 'Unknown',
            valueColor:
                user?.status == 'active' ? AppTheme.statusActive : AppTheme.statusWarning,
            chip: true,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED COMPONENTS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool chip = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.bgTertiary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                chip && valueColor != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: valueColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: valueColor,
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: valueColor ?? AppTheme.textPrimary,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHIMMER LOADING SKELETON
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero skeleton
          Container(
            height: 230,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  ShimmerBox(width: 108, height: 108, radius: 54),
                  SizedBox(height: 16),
                  ShimmerBox(width: 150, height: 18, radius: 8),
                  SizedBox(height: 8),
                  ShimmerBox(width: 100, height: 13, radius: 6),
                  SizedBox(height: 12),
                  ShimmerBox(width: 120, height: 30, radius: 15),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _skeletonCard(rows: 4),
                const SizedBox(height: 12),
                _skeletonCard(rows: 3),
                const SizedBox(height: 12),
                _skeletonCard(rows: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonCard({required int rows}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                ShimmerBox(width: 36, height: 36, radius: 10),
                SizedBox(width: 10),
                ShimmerBox(width: 130, height: 16, radius: 6),
              ],
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < rows; i++) ...[
              const Row(
                children: [
                  ShimmerBox(width: 32, height: 32, radius: 8),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 60, height: 10, radius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(height: 15, radius: 6),
                      ],
                    ),
                  ),
                ],
              ),
              if (i < rows - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ROLE CHANGE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRoleChangeButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildRoleChangeOptions({
    required String headerText,
    required List<Widget> buttons,
    Color? headerColor,
  }) {
    final color = headerColor ?? Colors.green;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: color, size: 18),
              const SizedBox(width: 8),
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
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: buttons),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────────────────────────────────

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
                      content: const Row(children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('You are now an Independent User.'),
                      ]),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
              child: const Text('Go Independent',
                  style: TextStyle(color: Colors.orange)),
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
    List<dynamic> searchResults = [];
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
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final company = searchResults[i];
                            final isSel = selectedCompanyId == company.id;
                            return ListTile(
                              dense: true,
                              selected: isSel,
                              selectedTileColor: Colors.green.shade50,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    isSel ? Colors.green : Colors.grey.shade300,
                                child: Icon(
                                  isSel ? Icons.check : Icons.business,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(company.companyName,
                                  style: const TextStyle(fontSize: 14)),
                              subtitle: Text('${company.city}, ${company.state}',
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
                  if (selectedCompanyName != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
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
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text('Requested Role (Optional)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: selectedRoleKey,
                    isExpanded: true,
                    hint: const Text('No preference'),
                    underline:
                        Container(height: 1, color: Colors.grey.shade400),
                    items: [
                      const DropdownMenuItem<String>(
                          value: null, child: Text('No preference')),
                      ..._predefinedRoles.map((r) => DropdownMenuItem<String>(
                          value: r['key'], child: Text(r['label']!))),
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
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Join request submitted! Awaiting approval.'),
                                ]),
                                backgroundColor: AppTheme.successColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                            ref.read(profileProvider.notifier).getProfileStatus();
                            ref.read(authProvider.notifier).loadUserProfile();
                          } else {
                            final error = ref.read(profileProvider).error;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error ?? 'Failed to join organization'),
                                backgroundColor: AppTheme.errorColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
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

              final success =
                  await ref.read(profileProvider.notifier).changeRole(profileData);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Role changed to Driver successfully!'),
                      ]),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  ref.read(profileProvider.notifier).getProfileStatus();
                  ref.read(authProvider.notifier).loadUserProfile();
                } else {
                  final error = ref.read(profileProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Failed to change role'),
                      backgroundColor: AppTheme.errorColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
