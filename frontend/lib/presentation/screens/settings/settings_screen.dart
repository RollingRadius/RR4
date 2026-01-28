import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/settings_provider.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

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
                _buildSectionHeader(context, 'Notifications'),
                _buildSettingsCard(
                  context,
                  children: [
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
                  ],
                ),
                const SizedBox(height: 24),

                // Location & Tracking Section
                _buildSectionHeader(context, 'Location & Tracking'),
                _buildSettingsCard(
                  context,
                  children: [
                    _buildSwitchTile(
                      context: context,
                      title: 'GPS Tracking',
                      subtitle: 'Enable location tracking for real-time updates',
                      icon: Icons.location_on_outlined,
                      value: settingsState.settings.gpsTrackingEnabled,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).updateSetting(
                              'gpsTrackingEnabled',
                              value,
                            );
                      },
                    ),
                    if (settingsState.settings.gpsTrackingEnabled) ...[
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
                          5: '5 seconds (High accuracy)',
                          15: '15 seconds (Balanced)',
                          30: '30 seconds (Battery saver)',
                          60: '1 minute (Low frequency)',
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
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Display Section
                _buildSectionHeader(context, 'Display'),
                _buildSettingsCard(
                  context,
                  children: [
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
                          ref.read(settingsProvider.notifier).updateSetting(
                                'themeMode',
                                value,
                              );
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
                        ref.read(settingsProvider.notifier).updateSetting(
                              'compactView',
                              value,
                            );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Data & Storage Section
                _buildSectionHeader(context, 'Data & Storage'),
                _buildSettingsCard(
                  context,
                  children: [
                    _buildSwitchTile(
                      context: context,
                      title: 'Auto-sync Data',
                      subtitle: 'Automatically sync data when online',
                      icon: Icons.sync,
                      value: settingsState.settings.autoSync,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).updateSetting(
                              'autoSync',
                              value,
                            );
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
                        ref.read(settingsProvider.notifier).updateSetting(
                              'offlineMode',
                              value,
                            );
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
                  ],
                ),
                const SizedBox(height: 24),

                // Privacy & Security Section
                _buildSectionHeader(context, 'Privacy & Security'),
                _buildSettingsCard(
                  context,
                  children: [
                    _buildSwitchTile(
                      context: context,
                      title: 'Biometric Lock',
                      subtitle: 'Use fingerprint/face ID to unlock app',
                      icon: Icons.fingerprint,
                      value: settingsState.settings.biometricLock,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).updateSetting(
                              'biometricLock',
                              value,
                            );
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
                        ref.read(settingsProvider.notifier).updateSetting(
                              'shareAnalytics',
                              value,
                            );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // About Section
                _buildSectionHeader(context, 'About'),
                _buildSettingsCard(
                  context,
                  children: [
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
                        // TODO: Open terms of service
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
                        // TODO: Open privacy policy
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
                  ],
                ),
                const SizedBox(height: 32),

                // Reset Settings Button
                Padding(
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
    required ValueChanged<bool> onChanged,
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
}
