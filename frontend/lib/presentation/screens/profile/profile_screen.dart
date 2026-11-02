import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/profile_provider.dart';
import 'package:fleet_management/providers/company_provider.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/animations/app_animations.dart';
import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

/// RR-web's brand blue (matches `_rrBlue` in lp_rr_ops_dashboard.dart) —
/// used on the Save action so it reads as "confirm/sync" against the
/// orange app-wide brand color used for Cancel/Edit.
const _rrWebBlue = Color(0xFF1B6CA8);

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _isUploadingPicture = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Staged picture change — not sent to the server until Save is tapped,
  // so picking a photo behaves the same as editing the name field.
  Uint8List? _pendingPictureBytes;
  String? _pendingPictureFilename;

  final _fullNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileProvider.notifier).getProfileStatus();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      if (!_isEditMode) {
        final profileState = ref.read(profileProvider);
        final authState = ref.read(authProvider);
        _fullNameController.text =
            profileState.profileData?['full_name'] ?? authState.user?.fullName ?? '';
      } else {
        // Leaving edit mode (Cancel, or after a successful Save) — discard
        // any picked-but-unsaved picture so it doesn't linger into the next
        // edit session.
        _pendingPictureBytes = null;
        _pendingPictureFilename = null;
      }
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    if (_fullNameController.text.trim().isEmpty) {
      _showError(l10n.profileFullNameRequired);
      return;
    }

    setState(() => _isSaving = true);

    if (_pendingPictureBytes != null) {
      final uploaded = await ref.read(profileProvider.notifier).uploadProfilePicture(
            _pendingPictureBytes!,
            _pendingPictureFilename!,
          );
      if (!uploaded) {
        if (mounted) {
          setState(() => _isSaving = false);
          final error = ref.read(profileProvider).error;
          _showError(error ?? l10n.profileUploadPictureFailed);
        }
        return;
      }
    }

    final updateData = {
      'full_name': _fullNameController.text.trim(),
    };

    final success = await ref.read(profileProvider.notifier).updateProfile(updateData);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text(l10n.profileUpdated),
            ]),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(profileProvider.notifier).getProfileStatus();
        ref.read(authProvider.notifier).loadUserProfile();
        _toggleEditMode();
      } else {
        final error = ref.read(profileProvider).error;
        _showError(error ?? l10n.profileUpdateFailed);
      }
    }
  }

  /// Picks a picture and stages it locally — it is only actually uploaded
  /// when the user taps Save (see _saveProfile), same as editing the name.
  Future<void> _pickProfilePicture() async {
    final l10n = AppLocalizations.of(context);
    XFile? image;
    try {
      image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      if (mounted) _showError(l10n.profileImageSelectError(e.toString()));
      return;
    }

    if (image == null) return;

    setState(() => _isUploadingPicture = true);

    try {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _pendingPictureBytes = bytes;
          _pendingPictureFilename = image!.name;
          _isUploadingPicture = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPicture = false);
        _showError(l10n.profileImageReadError(e.toString()));
      }
    }
  }

  Future<void> _confirmRemoveProfilePicture() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileRemovePictureTitle),
        content: Text(l10n.profileRemovePictureMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text(l10n.profileRemove),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploadingPicture = true);

    final success = await ref.read(profileProvider.notifier).deleteProfilePicture();

    if (mounted) {
      setState(() => _isUploadingPicture = false);
      if (success) {
        ref.read(authProvider.notifier).loadUserProfile();
      } else {
        final error = ref.read(profileProvider).error;
        _showError(error ?? l10n.profileRemovePictureFailed);
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
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
                      _ProfileAppBarPillButton(
                        icon: Icons.close_rounded,
                        tooltip: l10n.commonCancel,
                        color: AppTheme.primaryBlue,
                        onPressed: _isSaving ? null : _toggleEditMode,
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _ProfileAppBarPillButton(
                          icon: Icons.check_rounded,
                          label: l10n.commonSave,
                          filled: true,
                          isLoading: _isSaving,
                          color: _rrWebBlue,
                          onPressed: _isSaving ? null : _saveProfile,
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ProfileAppBarPillButton(
                      key: const ValueKey('view-action'),
                      icon: Icons.edit_outlined,
                      tooltip: l10n.profileEditTooltip,
                      onPressed: _toggleEditMode,
                    ),
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
    final l10n = AppLocalizations.of(context);
    final isActive = user?.status == 'active';
    final _raw = (user?.username ?? 'U').toUpperCase();
    final initials = _raw.length >= 2 ? _raw.substring(0, 2) : _raw;
    final rawPictureUrl =
        profileState.profileData?['profile_picture_url'] ?? user?.profilePictureUrl;
    final pictureUrl = (rawPictureUrl == null || rawPictureUrl.isEmpty)
        ? null
        : (rawPictureUrl.startsWith('http')
            ? rawPictureUrl
            : '${AppConfig.apiBaseUrl}$rawPictureUrl');
    ImageProvider? avatarImage;
    if (_pendingPictureBytes != null) {
      avatarImage = MemoryImage(_pendingPictureBytes!);
    } else if (pictureUrl != null) {
      avatarImage = NetworkImage(pictureUrl);
    }

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
                // Static ring for active users
                if (isActive)
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
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
                  child: GestureDetector(
                    onTap: _isEditMode && !_isUploadingPicture
                        ? _pickProfilePicture
                        : null,
                    onLongPress: _isEditMode &&
                            !_isUploadingPicture &&
                            _pendingPictureBytes == null &&
                            pictureUrl != null
                        ? _confirmRemoveProfilePicture
                        : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: AppTheme.primaryBlueDark,
                          backgroundImage: avatarImage,
                          child: _pendingPictureBytes == null && pictureUrl == null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        if (_isEditMode)
                          Positioned.fill(
                            child: ClipOval(
                              child: Container(
                                color: Colors.black.withOpacity(0.4),
                                child: _isUploadingPicture
                                    ? const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      )
                                    : const Icon(
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

          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _pendingPictureBytes != null
                    ? l10n.profileNewPhotoSelected
                    : pictureUrl != null
                        ? l10n.profilePhotoChangeHint
                        : l10n.profilePhotoAddHint,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── Name ────────────────────────────────────────────
          FadeSlide(
            delay: 180,
            beginOffset: const Offset(0, 0.25),
            child: Text(
              profileState.profileData?['full_name'] ?? user?.fullName ?? l10n.profileDefaultUser,
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
                    profileState.profileData?['role'] ?? user?.role ?? l10n.profileNoRole,
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
    final l10n = AppLocalizations.of(context);
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
              l10n.profileEditBanner,
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
    final l10n = AppLocalizations.of(context);
    return _buildSectionCard(
      icon: Icons.person_rounded,
      title: l10n.profilePersonalInfo,
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
        child: _isEditMode
            ? _buildEditFields(user, profileState)
            : _buildViewFields(user, profileState),
      ),
    );
  }

  Widget _buildViewFields(user, profileState) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('view-fields'),
      children: [
        _buildInfoTile(Icons.badge_rounded, l10n.profileFullName,
            profileState.profileData?['full_name'] ?? user?.fullName ?? l10n.profileNotAvailable),
        _buildDivider(),
        _buildInfoTile(Icons.alternate_email_rounded, l10n.profileUsername,
            user?.username ?? l10n.profileNotAvailable),
        _buildDivider(),
        _buildInfoTile(Icons.email_rounded, l10n.profileEmail,
            profileState.profileData?['email'] ?? user?.email ?? l10n.profileNotAvailable),
        _buildDivider(),
        _buildInfoTile(Icons.phone_rounded, l10n.profilePhone,
            profileState.profileData?['phone'] ?? user?.phone ?? l10n.profileNotAvailable),
      ],
    );
  }

  Widget _buildEditFields(user, profileState) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('edit-fields'),
      children: [
        TextField(
          controller: _fullNameController,
          decoration: InputDecoration(
            labelText: l10n.profileFullName,
            prefixIcon: const Icon(Icons.badge_rounded),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveProfile(),
        ),
        const SizedBox(height: 12),
        // Email and phone aren't user-editable right now — they double as
        // account-recovery credentials, and changing them without
        // re-verifying ownership (OTP / confirmation link) is a real
        // account-takeover risk. Shown read-only for context while editing.
        _buildInfoTile(Icons.email_rounded, l10n.profileEmail,
            profileState.profileData?['email'] ?? user?.email ?? l10n.profileNotAvailable),
        _buildDivider(),
        _buildInfoTile(Icons.phone_rounded, l10n.profilePhone,
            profileState.profileData?['phone'] ?? user?.phone ?? l10n.profileNotAvailable),
      ],
    );
  }

  Widget _buildRoleCard(user, profileState) {
    final l10n = AppLocalizations.of(context);
    return _buildSectionCard(
      icon: Icons.shield_rounded,
      title: l10n.profileRoleOrg,
      color: AppTheme.accentIndigo,
      trailing:
          (profileState.profileData?['role_type'] == 'independent' ||
                  profileState.profileData?['role_type'] == 'pending_user') &&
              !_isEditMode
          ? TextButton.icon(
              onPressed: _showChangeRoleDialog,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text(l10n.profileChange),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      child: Column(
        children: [
          _buildInfoTile(Icons.badge_outlined, l10n.profileRole,
              profileState.profileData?['role'] ?? user?.role ?? l10n.profileNotAssigned),
          _buildDivider(),
          _buildInfoTile(Icons.business_rounded, l10n.profileCompany,
              profileState.profileData?['company_name'] ?? user?.companyName ?? l10n.profileNone),
          _buildDivider(),
          _buildInfoTile(
            Icons.verified_user_rounded,
            l10n.profileStatus,
            profileState.profileCompleted ? l10n.profileStatusCompleted : l10n.profileStatusIncomplete,
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
              headerText: l10n.profileIndependentOptions,
              buttons: [
                _buildRoleChangeButton(l10n.profileJoinOrganization, Icons.business,
                    () => _showJoinOrganizationDialog()),
                _buildRoleChangeButton(l10n.profileCreateOrganization, Icons.add_business,
                    () => context.push('/organizations/create')),
                _buildRoleChangeButton(l10n.profileBecomeDriver, Icons.local_shipping,
                    () => _showBecomeDriverDialog()),
              ],
            ),
          ] else if (profileState.profileCompleted &&
              profileState.profileData?['role_type'] == 'pending_user' &&
              !_isEditMode) ...[
            const SizedBox(height: 16),
            _buildRoleChangeOptions(
              headerText: l10n.profilePendingOptions,
              headerColor: Colors.orange,
              buttons: [
                _buildRoleChangeButton(l10n.profileChangeOrganization, Icons.swap_horiz,
                    () => _showJoinOrganizationDialog()),
                _buildRoleChangeButton(l10n.profileCreateOrganization, Icons.add_business,
                    () => context.push('/organizations/create')),
                _buildRoleChangeButton(l10n.profileGoIndependent, Icons.person_outline,
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
                      l10n.profileRoleManaged,
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
    final l10n = AppLocalizations.of(context);
    return _buildSectionCard(
      icon: Icons.security_rounded,
      title: l10n.profileAccountStatus,
      color: AppTheme.accentCyan,
      child: Column(
        children: [
          _buildInfoTile(
            Icons.lock_rounded,
            l10n.profileAuthMethod,
            user?.authMethod == 'email' ? l10n.profileAuthEmailPassword : l10n.profileAuthSecurityQuestions,
          ),
          _buildDivider(),
          _buildInfoTile(
            Icons.circle_rounded,
            l10n.profileStatusLabel,
            user?.status ?? l10n.profileUnknown,
            valueColor:
                user?.status == 'active' ? AppTheme.statusActive : AppTheme.statusWarning,
            chip: true,
          ),
          if (user?.isSecurityQuestionsUser == true) ...[
            _buildDivider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.password_rounded,
                    size: 16, color: AppTheme.textSecondary),
              ),
              title: Text(l10n.profileChangePassword),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/profile/change-password'),
            ),
          ],
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
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileCancelPendingTitle),
        content: Text(l10n.profileCancelPendingMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.profileKeepPending),
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
                      content: Row(children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(l10n.profileNowIndependent),
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
                      content: Text(error ?? l10n.profileRoleUpdateFailed),
                      backgroundColor: AppTheme.errorColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
            child: Text(l10n.profileGoIndependent),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog() {
    final l10n = AppLocalizations.of(context);
    final isPending =
        ref.read(profileProvider).profileData?['role_type'] == 'pending_user';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileChangeRoleTitle),
        content: Text(isPending
            ? l10n.profileChangeRolePending
            : l10n.profileChangeRoleChoose),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          if (!isPending)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showBecomeDriverDialog();
              },
              child: Text(l10n.profileBecomeDriver),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showJoinOrganizationDialog();
            },
            child: Text(isPending ? l10n.profileChangeOrganization : l10n.profileJoinOrganization),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/organizations/create');
            },
            child: Text(l10n.profileCreateOrganization),
          ),
          if (isPending)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _confirmGoIndependent();
              },
              child: Text(l10n.profileGoIndependent,
                  style: const TextStyle(color: Colors.orange)),
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

  String _predefinedRoleLabel(AppLocalizations l10n, String key) => switch (key) {
        'fleet_manager' => l10n.profileRoleFleetManager,
        'dispatcher' => l10n.profileRoleDispatcher,
        'driver' => l10n.roleDriver,
        'accountant' => l10n.profileRoleAccountant,
        'maintenance_manager' => l10n.profileRoleMaintenanceManager,
        'compliance_officer' => l10n.profileRoleComplianceOfficer,
        'operations_manager' => l10n.profileRoleOperationsManager,
        'maintenance_technician' => l10n.profileRoleMaintenanceTechnician,
        'customer_service' => l10n.profileRoleCustomerService,
        'viewer_analyst' => l10n.profileRoleViewerAnalyst,
        _ => key,
      };

  void _showJoinOrganizationDialog() {
    final l10n = AppLocalizations.of(context);
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
            title: Text(l10n.profileJoinOrganization),
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
                      labelText: l10n.profileCompleteSearchCompany,
                      hintText: l10n.profileCompleteSearchHint,
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
                  Text(l10n.profileRequestedRole,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: selectedRoleKey,
                    isExpanded: true,
                    hint: Text(l10n.profileNoPreference),
                    underline:
                        Container(height: 1, color: Colors.grey.shade400),
                    items: [
                      DropdownMenuItem<String>(
                          value: null, child: Text(l10n.profileNoPreference)),
                      ..._predefinedRoles.map((r) => DropdownMenuItem<String>(
                          value: r['key'],
                          child: Text(_predefinedRoleLabel(l10n, r['key']!)))),
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
                child: Text(l10n.commonCancel),
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
                                content: Row(children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Text(l10n.profileJoinSubmitted),
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
                                content: Text(error ?? l10n.profileJoinFailed),
                                backgroundColor: AppTheme.errorColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      },
                child: Text(l10n.commonSubmit),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBecomeDriverDialog() {
    final l10n = AppLocalizations.of(context);
    final licenseNumberController = TextEditingController();
    final licenseExpiryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileBecomeDriverTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.profileDriverLicenseIntro),
              const SizedBox(height: 16),
              TextField(
                controller: licenseNumberController,
                decoration: InputDecoration(
                  labelText: l10n.profileLicenseNumber,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: licenseExpiryController,
                decoration: InputDecoration(
                  labelText: l10n.profileLicenseExpiry,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  hintText: '2027-12-31',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              if (licenseNumberController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.profileEnterLicenseNumber)),
                );
                return;
              }
              if (licenseExpiryController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.profileEnterLicenseExpiry)),
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
                      content: Row(children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(l10n.profileBecameDriver),
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
                      content: Text(error ?? l10n.profileChangeRoleFailed),
                      backgroundColor: AppTheme.errorColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
            child: Text(l10n.commonSubmit),
          ),
        ],
      ),
    );
  }
}

/// Small brand-tinted pill used for the AppBar's edit/save/cancel actions —
/// keeps the AppBar visually consistent with the orange `AppTheme` used
/// throughout the app (rounded, tinted "chip" buttons) instead of bare
/// Material `IconButton`s that read as generic/basic against the gradient
/// hero right below the AppBar.
class _ProfileAppBarPillButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? tooltip;
  final bool filled;
  final bool isLoading;
  final Color color;
  final VoidCallback? onPressed;

  const _ProfileAppBarPillButton({
    super.key,
    required this.icon,
    this.label,
    this.tooltip,
    this.filled = false,
    this.isLoading = false,
    this.color = AppTheme.primaryBlue,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final fg = filled
        ? Colors.white
        : color.withOpacity(disabled ? 0.4 : 1);
    final bg = filled
        ? color.withOpacity(disabled ? 0.5 : 1)
        : color.withOpacity(0.08);

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(
        horizontal: label != null ? 16 : 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: filled ? null : Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else
            Icon(icon, size: 18, color: fg),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(label!,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
          ],
        ],
      ),
    );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isLoading ? null : onPressed,
        child: child,
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}
