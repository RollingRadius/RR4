import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._();

  late final FirebaseRemoteConfig _config;

  // ── Default values (used before fetch or if fetch fails) ─────────────────
  static const _defaults = {
    'update_enabled': true,
    'latest_version': '1.0.0',
    'min_version': '1.0.0',
    'apk_url': '',
    'maintenance_mode': false,
    'maintenance_message': 'The app is under maintenance. Please try again later.',
  };

  Future<void> initialize() async {
    if (kIsWeb) return;

    _config = FirebaseRemoteConfig.instance;

    await _config.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 15),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    await _config.setDefaults(_defaults);

    try {
      await _config.fetchAndActivate();
    } catch (_) {
      // Defaults are used if fetch fails — app still works
    }
  }

  bool get updateEnabled    => kIsWeb ? false : _config.getBool('update_enabled');
  String get latestVersion  => kIsWeb ? '1.0.0' : _config.getString('latest_version');
  String get minVersion     => kIsWeb ? '1.0.0' : _config.getString('min_version');
  String get apkUrl         => kIsWeb ? '' : _config.getString('apk_url');
  bool get maintenanceMode  => kIsWeb ? false : _config.getBool('maintenance_mode');
  String get maintenanceMessage => kIsWeb ? '' : _config.getString('maintenance_message');
}
