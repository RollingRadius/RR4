import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/settings_provider.dart';
import 'package:fleet_management/providers/location_tracking_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/data/services/location_service.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  // ─── Colors ──────────────────────────────────────────────────────────────────
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  // ─── Animations ───────────────────────────────────────────────────────────────
  late final AnimationController _ctrl;
  late final Animation<double> _fadeHdr, _fadeProfile, _fadeNotif,
      _fadeLocation, _fadeDisplay, _fadeData, _fadePrivacy, _fadeAbout,
      _fadeDanger;
  late final Animation<Offset> _slideHdr, _slideProfile, _slideNotif,
      _slideLocation, _slideDisplay, _slideData, _slidePrivacy, _slideAbout,
      _slideDanger;

  Animation<double> _f(double s, double e) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _ctrl, curve: Interval(s, e, curve: Curves.easeOut)),
      );

  Animation<Offset> _s(double s, double e) =>
      Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl, curve: Interval(s, e, curve: Curves.easeOut)),
      );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _fadeHdr = _f(0.00, 0.22);
    _slideHdr = _s(0.00, 0.22);
    _fadeProfile = _f(0.07, 0.30);
    _slideProfile = _s(0.07, 0.30);
    _fadeNotif = _f(0.15, 0.38);
    _slideNotif = _s(0.15, 0.38);
    _fadeLocation = _f(0.23, 0.46);
    _slideLocation = _s(0.23, 0.46);
    _fadeDisplay = _f(0.31, 0.54);
    _slideDisplay = _s(0.31, 0.54);
    _fadeData = _f(0.39, 0.62);
    _slideData = _s(0.39, 0.62);
    _fadePrivacy = _f(0.47, 0.70);
    _slidePrivacy = _s(0.47, 0.70);
    _fadeAbout = _f(0.55, 0.78);
    _slideAbout = _s(0.55, 0.78);
    _fadeDanger = _f(0.63, 0.86);
    _slideDanger = _s(0.63, 0.86);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _a(Animation<double> f, Animation<Offset> s, Widget child) =>
      FadeTransition(opacity: f, child: SlideTransition(position: s, child: child));

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authProvider).user;

    if (settings.isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              // ── Profile card ────────────────────────────────────────────────
              _a(_fadeProfile, _slideProfile, _buildProfileCard(user)),
              const SizedBox(height: 22),

              // ── Notifications ────────────────────────────────────────────────
              _a(
                _fadeNotif,
                _slideNotif,
                _buildSection(
                  icon: Icons.notifications_rounded,
                  color: _primary,
                  title: 'Notifications',
                  children: [
                    _SettingSwitch(
                      icon: Icons.notifications_active_rounded,
                      iconColor: _primary,
                      title: 'Push Notifications',
                      subtitle: 'Receive important app alerts',
                      value: settings.settings.notificationsEnabled,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .updateSetting('notificationsEnabled', v),
                    ),
                    if (settings.settings.notificationsEnabled) ...[
                      _div(),
                      _SettingSwitch(
                        icon: Icons.local_shipping_rounded,
                        iconColor: const Color(0xFF6366F1),
                        title: 'Trip Updates',
                        subtitle: 'Trip status changes',
                        value: settings.settings.tripNotifications,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .updateSetting('tripNotifications', v),
                        indented: true,
                      ),
                      _div(),
                      _SettingSwitch(
                        icon: Icons.person_rounded,
                        iconColor: const Color(0xFF06B6D4),
                        title: 'Driver Updates',
                        subtitle: 'Driver assignment alerts',
                        value: settings.settings.driverNotifications,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .updateSetting('driverNotifications', v),
                        indented: true,
                      ),
                      _div(),
                      _SettingSwitch(
                        icon: Icons.directions_car_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'Vehicle Alerts',
                        subtitle: 'Maintenance & status alerts',
                        value: settings.settings.vehicleNotifications,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .updateSetting('vehicleNotifications', v),
                        indented: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Location & Tracking ──────────────────────────────────────────
              _a(
                _fadeLocation,
                _slideLocation,
                _buildSection(
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFF10B981),
                  title: 'Location & Tracking',
                  children: [
                    _buildTrackingContent(settings),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Display ──────────────────────────────────────────────────────
              _a(
                _fadeDisplay,
                _slideDisplay,
                _buildSection(
                  icon: Icons.palette_rounded,
                  color: const Color(0xFF6366F1),
                  title: 'Display',
                  children: [
                    _ThemeSelector(
                      value: settings.settings.themeMode,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .updateSetting('themeMode', v),
                    ),
                    _div(),
                    _SettingSwitch(
                      icon: Icons.view_compact_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Compact View',
                      subtitle: 'Show more items on screen',
                      value: settings.settings.compactView,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .updateSetting('compactView', v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Data & Storage ───────────────────────────────────────────────
              _a(
                _fadeData,
                _slideData,
                _buildSection(
                  icon: Icons.storage_rounded,
                  color: const Color(0xFF06B6D4),
                  title: 'Data & Storage',
                  children: [
                    _SettingSwitch(
                      icon: Icons.sync_rounded,
                      iconColor: const Color(0xFF06B6D4),
                      title: 'Auto-sync Data',
                      subtitle: 'Sync automatically when online',
                      value: settings.settings.autoSync,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .updateSetting('autoSync', v),
                    ),
                    _div(),
                    _SettingSwitch(
                      icon: Icons.cloud_off_rounded,
                      iconColor: const Color(0xFF64748B),
                      title: 'Offline Mode',
                      subtitle: 'Cache data for offline access',
                      value: settings.settings.offlineMode,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .updateSetting('offlineMode', v),
                    ),
                    _div(),
                    _SettingTile(
                      icon: Icons.delete_sweep_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Clear Cache',
                      subtitle: 'Free up device storage space',
                      showArrow: true,
                      onTap: () => _showClearCacheDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Privacy & Security ────────────────────────────────────────────
              _a(
                _fadePrivacy,
                _slidePrivacy,
                _buildSection(
                  icon: Icons.shield_rounded,
                  color: const Color(0xFFF59E0B),
                  title: 'Privacy & Security',
                  children: [
                    _SettingSwitch(
                      icon: Icons.fingerprint_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Biometric Lock',
                      subtitle: 'Fingerprint or Face ID to unlock',
                      value: settings.settings.biometricLock,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .updateSetting('biometricLock', v),
                    ),
                    _div(),
                    _SettingSwitch(
                      icon: Icons.bar_chart_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Share Analytics',
                      subtitle: 'Help improve the app anonymously',
                      value: settings.settings.shareAnalytics,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .updateSetting('shareAnalytics', v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── About ─────────────────────────────────────────────────────────
              _a(
                _fadeAbout,
                _slideAbout,
                _buildSection(
                  icon: Icons.info_rounded,
                  color: const Color(0xFF64748B),
                  title: 'About',
                  children: [
                    _SettingTile(
                      icon: Icons.verified_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'App Version',
                      subtitle: '1.0.0 (Build 100)',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Up to date',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A))),
                      ),
                    ),
                    _div(),
                    _SettingTile(
                      icon: Icons.description_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Terms of Service',
                      showArrow: true,
                      onTap: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Terms of Service')),
                      ),
                    ),
                    _div(),
                    _SettingTile(
                      icon: Icons.privacy_tip_rounded,
                      iconColor: const Color(0xFF06B6D4),
                      title: 'Privacy Policy',
                      showArrow: true,
                      onTap: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Policy')),
                      ),
                    ),
                    _div(),
                    _SettingTile(
                      icon: Icons.help_rounded,
                      iconColor: _primary,
                      title: 'Help & Support',
                      showArrow: true,
                      onTap: () => context.push('/help'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Danger zone ───────────────────────────────────────────────────
              _a(_fadeDanger, _slideDanger,
                  _buildDangerZone(context)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return _a(
      _fadeHdr,
      _slideHdr,
      Container(
        color: _bg,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEC5B13), Color(0xFFBF4209)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: _primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.settings_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3)),
                  Text('Preferences & Configuration',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Profile card ─────────────────────────────────────────────────────────────

  Widget _buildProfileCard(dynamic user) {
    final name = (user?.fullName as String?) ?? 'Fleet Manager';
    final email = (user?.email as String?) ?? '';
    final role = (user?.role as String?) ?? 'Admin';
    final company = (user?.companyName as String?) ?? '';
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEC5B13), Color(0xFFBF4209)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(email,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_capitalize(role),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _primary)),
                    ),
                    if (company.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('· $company',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8)),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Edit button
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_rounded,
                      size: 13, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('Edit',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section wrapper ──────────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 9),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 7),
              Text(title.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.7)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 6)
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // ─── Tracking content ─────────────────────────────────────────────────────────

  Widget _buildTrackingContent(dynamic settingsState) {
    final trackingState = ref.watch(locationTrackingProvider);
    final isAdminEnabled = trackingState.trackingEnabled == true;

    return Column(
      children: [
        // Admin status banner
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isAdminEnabled
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFF7ED),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isAdminEnabled
                        ? const Color(0xFF16A34A).withOpacity(0.15)
                        : const Color(0xFFF59E0B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    isAdminEnabled
                        ? Icons.admin_panel_settings_rounded
                        : Icons.lock_outline_rounded,
                    size: 13,
                    color: isAdminEnabled
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAdminEnabled
                        ? 'GPS tracking enabled by administrator'
                        : 'GPS tracking disabled — contact administrator',
                    style: TextStyle(
                        fontSize: 12,
                        color: isAdminEnabled
                            ? const Color(0xFF15803D)
                            : const Color(0xFF92400E),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        // Live tracking indicator
        if (trackingState.isTracking)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFEFF6FF),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('Currently tracking location',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D4ED8))),
                const Spacer(),
                if (trackingState.lastUpdate != null)
                  Text(
                    _formatTime(trackingState.lastUpdate!),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),

        // GPS toggle
        _div(),
        _SettingSwitch(
          icon: Icons.location_on_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'GPS Tracking',
          subtitle: isAdminEnabled
              ? 'Enable location tracking for real-time updates'
              : 'Contact administrator to enable tracking',
          value: settingsState.settings.gpsTrackingEnabled &&
              isAdminEnabled,
          onChanged: isAdminEnabled
              ? (v) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateSetting('gpsTrackingEnabled', v);
                  if (v) {
                    ref
                        .read(locationTrackingProvider.notifier)
                        .startTracking();
                  } else {
                    ref
                        .read(locationTrackingProvider.notifier)
                        .stopTracking();
                  }
                }
              : null,
        ),

        // Sub-options when GPS is on
        if (settingsState.settings.gpsTrackingEnabled &&
            isAdminEnabled) ...[
          _div(),
          _SettingSwitch(
            icon: Icons.gps_fixed_rounded,
            iconColor: const Color(0xFF06B6D4),
            title: 'Background Tracking',
            subtitle: 'Continue tracking when app is in background',
            value: settingsState.settings.backgroundTracking,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .updateSetting('backgroundTracking', v),
            indented: true,
          ),
          _div(),
          _UpdateFrequencySelector(
            value: settingsState.settings.locationUpdateInterval,
            onChanged: (v) {
              if (v != null) {
                ref
                    .read(settingsProvider.notifier)
                    .updateSetting('locationUpdateInterval', v);
              }
            },
          ),
          _div(),
          _SettingTile(
            icon: Icons.map_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'View Live Tracking',
            subtitle: 'See your current location on map',
            showArrow: true,
            indented: true,
            onTap: () => context.push('/tracking/live'),
          ),
        ],

        // Permission status
        if (trackingState.permissionStatus != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: trackingState.permissionStatus!.isGranted
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  trackingState.permissionStatus!.isGranted
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  size: 14,
                  color: trackingState.permissionStatus!.isGranted
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location permission: ${trackingState.permissionStatus!.displayName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (!trackingState.permissionStatus!.isGranted)
                  GestureDetector(
                    onTap: () => ref
                        .read(locationTrackingProvider.notifier)
                        .requestPermission(),
                    child: const Text('Grant',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEC5B13))),
                  ),
              ],
            ),
          ),

        // Error
        if (trackingState.error != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFFEE2E2),
            child: Row(
              children: [
                const Icon(Icons.error_rounded,
                    color: Color(0xFFDC2626), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(trackingState.error!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF991B1B))),
                ),
                GestureDetector(
                  onTap: () => ref
                      .read(locationTrackingProvider.notifier)
                      .clearError(),
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: Color(0xFF991B1B)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Danger zone ──────────────────────────────────────────────────────────────

  Widget _buildDangerZone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 9),
          child: Row(
            children: [
              Icon(Icons.warning_rounded,
                  size: 13, color: Color(0xFFEF4444)),
              SizedBox(width: 7),
              Text('DANGER ZONE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFEF4444),
                      letterSpacing: 0.7)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withOpacity(0.04), blurRadius: 6)
            ],
          ),
          child: Column(
            children: [
              _SettingTile(
                icon: Icons.restart_alt_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Reset to Default Settings',
                subtitle: 'Restore all settings to factory defaults',
                showArrow: true,
                onTap: () => _showResetDialog(context),
              ),
              _div(),
              _SettingTile(
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                showArrow: true,
                onTap: () {
                  // TODO: sign out
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  Widget _div() => Divider(
      height: 1, indent: 56, color: Colors.grey.shade100);

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────────

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ActionDialog(
        icon: Icons.delete_sweep_rounded,
        iconColor: const Color(0xFFEF4444),
        title: 'Clear Cache',
        message:
            'This will clear all cached data and free up storage space. Your account data will not be affected.',
        confirmLabel: 'Clear Cache',
        confirmColor: const Color(0xFFEF4444),
        onConfirm: () async {
          await ref.read(settingsProvider.notifier).clearCache();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Cache cleared successfully'),
              ]),
              backgroundColor: AppTheme.successColor,
            ));
          }
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ActionDialog(
        icon: Icons.restart_alt_rounded,
        iconColor: const Color(0xFFEF4444),
        title: 'Reset Settings',
        message:
            'This will reset all settings to their default values. Are you sure you want to continue?',
        confirmLabel: 'Reset',
        confirmColor: const Color(0xFFEF4444),
        onConfirm: () async {
          await ref.read(settingsProvider.notifier).resetToDefaults();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Settings reset to defaults'),
              ]),
              backgroundColor: AppTheme.successColor,
            ));
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Setting row: switch
// ─────────────────────────────────────────────────────────────────────────────

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool indented;

  const _SettingSwitch({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.indented = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: indented ? 16 : 16, right: 16, top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: indented ? 13 : 14,
                        fontWeight: indented
                            ? FontWeight.w500
                            : FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          height: 1.4)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFEC5B13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Setting row: tappable tile
// ─────────────────────────────────────────────────────────────────────────────

class _SettingTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool showArrow;
  final bool indented;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.showArrow = false,
    this.indented = false,
    this.trailing,
    this.onTap,
  });

  @override
  State<_SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<_SettingTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.97,
        upperBound: 1.0,
        value: 1.0);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _press,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _press.reverse() : null,
        onTapUp: widget.onTap != null
            ? (_) {
                _press.forward();
                widget.onTap!();
              }
            : null,
        onTapCancel:
            widget.onTap != null ? () => _press.forward() : null,
        child: Padding(
          padding: EdgeInsets.only(
              left: widget.indented ? 32 : 16,
              right: 16,
              top: 12,
              bottom: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon,
                    color: widget.iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (widget.subtitle != null)
                      Text(widget.subtitle!,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              height: 1.4)),
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
              if (widget.showArrow)
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme selector (visual chips)
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ThemeSelector({required this.value, required this.onChanged});

  static const _options = [
    ('system', 'System', Icons.brightness_auto_rounded),
    ('light', 'Light', Icons.wb_sunny_rounded),
    ('dark', 'Dark', Icons.nightlight_round),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.palette_rounded,
                    color: Color(0xFF6366F1), size: 18),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Choose app appearance',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _options.map((opt) {
              final (key, label, icon) = opt;
              final sel = value == key;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: key != 'dark' ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => onChanged(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFFEC5B13)
                                .withOpacity(0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFFEC5B13)
                              : Colors.grey.shade200,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(icon,
                              size: 18,
                              color: sel
                                  ? const Color(0xFFEC5B13)
                                  : Colors.grey.shade500),
                          const SizedBox(height: 4),
                          Text(label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: sel
                                      ? const Color(0xFFEC5B13)
                                      : Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Update frequency selector (chips)
// ─────────────────────────────────────────────────────────────────────────────

class _UpdateFrequencySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int?> onChanged;

  const _UpdateFrequencySelector(
      {required this.value, required this.onChanged});

  static const _options = [
    (15, '15s', 'High'),
    (30, '30s', 'Balanced'),
    (60, '1m', 'Battery'),
    (120, '2m', 'Low'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.update_rounded,
                    color: Color(0xFF06B6D4), size: 18),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update Frequency',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('How often to update location',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: _options.map((opt) {
              final (secs, label, desc) = opt;
              final sel = value == secs;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: secs != 120 ? 6 : 0),
                  child: GestureDetector(
                    onTap: () => onChanged(secs),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF06B6D4)
                                .withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF06B6D4)
                              : Colors.grey.shade200,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(label,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: sel
                                      ? const Color(0xFF06B6D4)
                                      : Colors.grey.shade600)),
                          Text(desc,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: sel
                                      ? const Color(0xFF06B6D4)
                                          .withOpacity(0.7)
                                      : Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action confirmation dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ActionDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const _ActionDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(message,
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
