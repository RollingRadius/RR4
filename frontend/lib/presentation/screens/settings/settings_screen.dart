import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/settings_provider.dart';
import 'package:fleet_management/providers/location_tracking_provider.dart';
import 'package:fleet_management/data/services/location_service.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Notifications Section
                FadeSlide(
                  delay: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Notifications'),
                      _buildSettingsCard(context, children: [
                    _buildSwitchTile(
                      context: context,
                      title: 'Push Notifications',
                      subtitle: 'Receive push notifications for important updates',
                      icon: Icons.notifications_outlined,
                      value: settingsState.settings.notificationsEnabled,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).updateSetting(
                              'notificationsEnabled',
                              value,
                            );
                      },
                    ),
                    if (settingsState.settings.notificationsEnabled) ...[
                      const Divider(height: 1),
                      _buildSwitchTile(
                        context: context,
                        title: 'Trip Updates',
                        subtitle: 'Notifications for trip status changes',
                        icon: Icons.local_shipping_outlined,
                        value: settingsState.settings.tripNotifications,
                        onChanged: (value) {
                          ref.read(settingsProvider.notifier).updateSetting(
                                'tripNotifications',
                                value,
                              );
                        },
                        indented: true,
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        context: context,
                        title: 'Driver Updates',
                        subtitle: 'Notifications about driver assignments',
                        icon: Icons.person_outline,
                        value: settingsState.settings.driverNotifications,
                        onChanged: (value) {
                          ref.read(settingsProvider.notifier).updateSetting(
                                'driverNotifications',
                                value,
                              );
                        },
                        indented: true,
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        context: context,
                        title: 'Vehicle Alerts',
                        subtitle: 'Maintenance and vehicle status alerts',
                        icon: Icons.directions_car_outlined,
                        value: settingsState.settings.vehicleNotifications,
                        onChanged: (value) {
                          ref.read(settingsProvider.notifier).updateSetting(
                                'vehicleNotifications',
                                value,
                              );
                        },
                        indented: true,
                      ),
                    ],
                  ]),
                    ],
                  ),
                ),  // closes FadeSlide for Notifications
                const SizedBox(height: 24),

                // Location & Tracking Section
                FadeSlide(
                  delay: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Location & Tracking'),
                      _buildTrackingSection(context, ref, settingsState),
                    ],
                  ),
                ),  // closes FadeSlide for Location
                const SizedBox(height: 24),

                // Display Section
                FadeSlide(
                  delay: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Display'),
                      _buildSettingsCard(context, children: [
                        _buildDropdownTile(
                          context: context,
                          title: 'Theme',
                          subtitle: 'Choose app appearance',
                          icon: Icons.palette_outlined,
                          value: settingsState.settings.themeMode,
                          items: const {
                            'system': 'System Default',
                            'light': 'Light',
                            'dark': 'Dark',
                          },
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(settingsProvider.notifier).updateSetting('themeMode', value);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          context: context,
                          title: 'Compact View',
                          subtitle: 'Show more items on screen',
                          icon: Icons.view_compact_outlined,
                          value: settingsState.settings.compactView,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateSetting('compactView', value);
                          },
                        ),
                      ]),
                    ],
                  ),
                ),  // closes FadeSlide for Display
                const SizedBox(height: 24),

                // Data & Storage Section
                FadeSlide(
                  delay: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Data & Storage'),
                      _buildSettingsCard(context, children: [
                        _buildSwitchTile(
                          context: context,
                          title: 'Auto-sync Data',
                          subtitle: 'Automatically sync data when online',
                          icon: Icons.sync,
                          value: settingsState.settings.autoSync,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateSetting('autoSync', value);
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          context: context,
                          title: 'Offline Mode',
                          subtitle: 'Cache data for offline access',
                          icon: Icons.cloud_off_outlined,
                          value: settingsState.settings.offlineMode,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateSetting('offlineMode', value);
                          },
                        ),
                        const Divider(height: 1),
                        _buildTile(
                          context: context,
                          title: 'Clear Cache',
                          subtitle: 'Free up storage space',
                          icon: Icons.delete_outline,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showClearCacheDialog(context, ref),
                        ),
                      ]),
                    ],
                  ),
                ),  // closes FadeSlide for Data & Storage
                const SizedBox(height: 24),

                // Privacy & Security Section
                FadeSlide(
                  delay: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Privacy & Security'),
                      _buildSettingsCard(context, children: [
                        _buildSwitchTile(
                          context: context,
                          title: 'Biometric Lock',
                          subtitle: 'Use fingerprint/face ID to unlock app',
                          icon: Icons.fingerprint,
                          value: settingsState.settings.biometricLock,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateSetting('biometricLock', value);
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          context: context,
                          title: 'Share Analytics',
                          subtitle: 'Help improve app with anonymous usage data',
                          icon: Icons.analytics_outlined,
                          value: settingsState.settings.shareAnalytics,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateSetting('shareAnalytics', value);
                          },
                        ),
                      ]),
                    ],
                  ),
                ),  // closes FadeSlide for Privacy
                const SizedBox(height: 24),

                // About Section
                FadeSlide(
                  delay: 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'About'),
                      _buildSettingsCard(context, children: [
                        _buildTile(
                          context: context,
                          title: 'App Version',
                          subtitle: '1.0.0',
                          icon: Icons.info_outline,
                        ),
                        const Divider(height: 1),
                        _buildTile(
                          context: context,
                          title: 'Terms of Service',
                          icon: Icons.description_outlined,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Terms of Service')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildTile(
                          context: context,
                          title: 'Privacy Policy',
                          icon: Icons.privacy_tip_outlined,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Privacy Policy')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildTile(
                          context: context,
                          title: 'Help & Support',
                          icon: Icons.help_outline,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/help'),
                        ),
                      ]),
                    ],
                  ),
                ),  // closes FadeSlide for About
                const SizedBox(height: 32),

                // Reset Settings Button
                FadeSlide(
                  delay: 600,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: OutlinedButton.icon(
                      onPressed: () => _showResetDialog(context, ref),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset to Default Settings'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    ValueChanged<bool>? onChanged,
    bool indented = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: indented ? 16.0 : 0),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            fontSize: indented ? 14 : 16,
            fontWeight: indented ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )
            : null,
        secondary: Icon(icon, color: Theme.of(context).primaryColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    bool indented = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: indented ? 14 : 16,
          fontWeight: indented ? FontWeight.normal : FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.only(
        left: indented ? 32.0 : 16.0,
        right: 16.0,
        top: 4,
        bottom: 4,
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
    bool indented = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: indented ? 16.0 : 0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: indented ? 14 : 16,
            fontWeight: indented ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 8),
            DropdownButtonFormField<T>(
              value: value,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: items.entries.map((entry) {
                return DropdownMenuItem<T>(
                  value: entry.key,
                  child: Text(entry.value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data and free up storage space. Your account data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(settingsProvider.notifier).clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Cache cleared successfully'),
                      ],
                    ),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to their default values. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(settingsProvider.notifier).resetToDefaults();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Settings reset to defaults'),
                      ],
                    ),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingSection(
    BuildContext context,
    WidgetRef ref,
    dynamic settingsState,
  ) {
    final trackingState = ref.watch(locationTrackingProvider);

    return _buildSettingsCard(
      context,
      children: [
        // Tracking Status Info
        if (trackingState.trackingEnabled != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: trackingState.trackingEnabled!
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  trackingState.trackingEnabled!
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: trackingState.trackingEnabled!
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trackingState.trackingEnabled!
                        ? 'GPS tracking enabled by administrator'
                        : 'GPS tracking disabled by administrator',
                    style: TextStyle(
                      fontSize: 13,
                      color: trackingState.trackingEnabled!
                          ? Colors.green.shade900
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Current Tracking Status
        if (trackingState.isTracking)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Currently tracking location',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (trackingState.lastUpdate != null)
                  Text(
                    'Last: ${_formatTime(trackingState.lastUpdate!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),

        // GPS Tracking Toggle
        _buildSwitchTile(
          context: context,
          title: 'GPS Tracking',
          subtitle: trackingState.trackingEnabled == true
              ? 'Enable location tracking for real-time updates'
              : 'Contact administrator to enable tracking',
          icon: Icons.location_on_outlined,
          value: settingsState.settings.gpsTrackingEnabled &&
              (trackingState.trackingEnabled ?? false),
          onChanged: trackingState.trackingEnabled == true
              ? (value) {
                  ref.read(settingsProvider.notifier).updateSetting(
                        'gpsTrackingEnabled',
                        value,
                      );
                  if (value) {
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

        // Background Tracking (only if GPS enabled)
        if (settingsState.settings.gpsTrackingEnabled &&
            (trackingState.trackingEnabled ?? false)) ...[
          const Divider(height: 1),
          _buildSwitchTile(
            context: context,
            title: 'Background Tracking',
            subtitle: 'Continue tracking when app is in background',
            icon: Icons.gps_fixed,
            value: settingsState.settings.backgroundTracking,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateSetting(
                    'backgroundTracking',
                    value,
                  );
              // TODO: Start/stop background service
            },
            indented: true,
          ),
          const Divider(height: 1),
          _buildDropdownTile(
            context: context,
            title: 'Update Frequency',
            subtitle: 'How often to update location',
            icon: Icons.update,
            value: settingsState.settings.locationUpdateInterval,
            items: const {
              15: '15 seconds (High accuracy)',
              30: '30 seconds (Balanced)',
              60: '1 minute (Battery saver)',
              120: '2 minutes (Low frequency)',
            },
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).updateSetting(
                      'locationUpdateInterval',
                      value,
                    );
              }
            },
            indented: true,
          ),
          const Divider(height: 1),
          _buildTile(
            context: context,
            title: 'View Live Tracking',
            subtitle: 'See your current location on map',
            icon: Icons.map_outlined,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tracking/live'),
            indented: true,
          ),
        ],

        // Permission Status
        if (trackingState.permissionStatus != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: trackingState.permissionStatus!.isGranted
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  trackingState.permissionStatus!.isGranted
                      ? Icons.check_circle
                      : Icons.error_outline,
                  size: 16,
                  color: trackingState.permissionStatus!.isGranted
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location permission: ${trackingState.permissionStatus!.displayName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (!trackingState.permissionStatus!.isGranted)
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(locationTrackingProvider.notifier)
                          .requestPermission();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Grant', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

        // Error Display
        if (trackingState.error != null)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade50,
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trackingState.error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    ref.read(locationTrackingProvider.notifier).clearError();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
