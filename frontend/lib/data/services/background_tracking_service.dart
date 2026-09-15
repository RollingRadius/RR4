import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import 'package:fleet_management/core/config/app_config.dart';

/// Background Tracking Service
///
/// Durable GPS tracking for drivers who've granted "Always Allow" location
/// permission — survives the app being force-killed (swiped from Recents,
/// see android:stopWithTask="false" on this service in AndroidManifest.xml)
/// and survives the driver explicitly logging out of the app.
///
/// This runs in its own OS-level isolate with no access to the main app's
/// Riverpod providers, in-memory auth state, or ApiService/Dio singleton —
/// it holds its own persisted, auth-session-independent credential
/// (`trackingRefreshTokenKey`/`trackingDriverIdKey`, deliberately separate
/// from the main session's AppConfig.tokenKey/refreshTokenKey so a normal
/// logout doesn't touch them) and its own lightweight Dio client.
///
/// Per an explicit product decision: this is NOT covert. The persistent
/// foreground-service notification stays visible on the driver's phone the
/// whole time, even after they've logged out of the app itself.
// Required alongside the @pragma on onStart below — the plugin spawns
// onStart in a fresh engine via a native callback-handle lookup (not normal
// Dart code reachability), which needs the enclosing class annotated too,
// not just the static method, or native code can't resolve it at all
// (see incident this fixes: "must be annotated" DartVM error, 2026-09-15).
@pragma('vm:entry-point')
class BackgroundTrackingService {
  static const String _notificationChannelId = 'fleet_tracking';

  /// Secure-storage keys for the durable tracking credential — deliberately
  /// separate from AppConfig.tokenKey/refreshTokenKey (the main session),
  /// so AuthNotifier.logout() can clear the main session without touching
  /// these, and this service keeps running regardless of app login state.
  static const String trackingRefreshTokenKey = 'tracking_refresh_token';
  static const String trackingDriverIdKey = 'tracking_driver_id';

  static const _storage = FlutterSecureStorage();

  /// Initialize background service (register with the OS; does not start it)
  static Future<void> initialize() async {
    // flutter_background_service only supports Android/iOS — every method
    // on its platform instance throws on web (and this app's driver
    // dashboard can be opened in a browser for testing/admin use), so every
    // public entry point below no-ops there instead of crashing.
    if (kIsWeb) return;

    // Android 8.0+ (API 26+) requires this channel to exist before
    // startForeground() is ever called for it — AndroidConfiguration's
    // notificationChannelId below is a reference, not a creation call.
    // Skipping this crashes the whole process (not just the service) with
    // "RemoteServiceException: Bad notification for startForeground" the
    // moment a driver grants "Always Allow" and tracking actually tries to
    // start (incident: 2026-09-15, crashed on-device for a whileInUse→always
    // permission upgrade).
    const channel = AndroidNotificationChannel(
      _notificationChannelId,
      'Fleet Tracking',
      description: 'Shows while your location is being tracked in the background',
      importance: Importance.low,
    );
    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        // Explicit, not relying on the package default: the plugin's own
        // bundled BootReceiver (merged into our manifest automatically)
        // restarts this service after a device reboot when this is true —
        // re-entering onStart, which reads the persisted tracking
        // credential from secure storage independently of any Dart/app
        // state, so tracking resumes correctly with zero app interaction.
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Fleet Tracking Active',
        initialNotificationContent: 'Your location is being tracked',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Persist the durable tracking credential for a driver and start the
  /// service. Call whenever a driver with "Always Allow" permission logs in
  /// or refreshes their session — safe to call repeatedly (idempotent).
  static Future<bool> startForDriver({
    required String driverId,
    required String refreshToken,
  }) async {
    // Credential is still worth persisting on web (harmless, and keeps
    // currentDriverId()'s foreign-driver check meaningful), but there's no
    // actual background service to start there.
    await _storage.write(key: trackingDriverIdKey, value: driverId);
    await _storage.write(key: trackingRefreshTokenKey, value: refreshToken);
    if (kIsWeb) return false;
    final service = FlutterBackgroundService();
    if (await service.isRunning()) return true;
    return service.startService();
  }

  /// Stop background tracking and forget the persisted credential —
  /// call when a DIFFERENT driver logs in on this device (foreign-driver
  /// safety), not on a normal same-driver logout.
  static Future<void> stopAndClearCredential() async {
    await stop();
    await _storage.delete(key: trackingDriverIdKey);
    await _storage.delete(key: trackingRefreshTokenKey);
  }

  /// Start the service using whatever credential is already persisted —
  /// use this once startForDriver() has already been called for the current
  /// driver; a no-op if already running.
  static Future<bool> start() async {
    if (kIsWeb) return false;
    final service = FlutterBackgroundService();
    if (await service.isRunning()) return true;
    return service.startService();
  }

  /// Stop background tracking, keeping the persisted credential intact —
  /// this is what a normal in-app "stop tracking" toggle should call, since
  /// the credential is what lets tracking resume for the same driver.
  static Future<bool> stop() async {
    if (kIsWeb) return false;
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    if (isRunning) {
      service.invoke('stop');
      return true;
    }
    return false;
  }

  /// Check if service is running
  static Future<bool> isRunning() async {
    if (kIsWeb) return false;
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// The driver id currently associated with the persisted tracking
  /// credential, if any — used for the foreign-driver-on-this-device check.
  /// Safe on web (just secure-storage, no platform-service call involved).
  static Future<String?> currentDriverId() async {
    return _storage.read(key: trackingDriverIdKey);
  }

  // ========================================================================
  // Background Service Entry Point
  // ========================================================================

  /// Service entry point (Android)
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stop').listen((event) {
      service.stopSelf();
    });

    service.on('updateNotification').listen((event) {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: event!['title'] ?? 'Fleet Tracking Active',
          content: event['content'] ?? 'Tracking your location',
        );
      }
    });

    _startLocationTracking(service);
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Exchange the persisted tracking refresh token for a fresh access
  /// token, persisting whatever new refresh token comes back (the endpoint
  /// rotates it) so the credential chain stays alive indefinitely — well
  /// under the server's 7-day refresh-token expiry, since this isolate
  /// calls this at least once per upload cycle (~60s). Returns null (and
  /// leaves the stored credential untouched) on a transient failure (e.g.
  /// no network) — that shouldn't wipe out a still-valid refresh token.
  /// Throws [_RefreshTokenRevoked] on a definitive 401 — e.g. the driver
  /// was removed from their org (which revokes all their refresh tokens,
  /// see organization_management.py's remove_employee) or their password
  /// changed — retrying that forever would just drain battery with a
  /// permanently-stuck "Tracking Active" notification.
  static Future<String?> _refreshAccessToken(Dio dio) async {
    final refreshToken = await _storage.read(key: trackingRefreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final resp = await dio.post('/api/auth/refresh', data: {'refresh_token': refreshToken});
      final data = resp.data as Map<String, dynamic>;
      final newRefresh = data['refresh_token'] as String?;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _storage.write(key: trackingRefreshTokenKey, value: newRefresh);
      }
      return data['access_token'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        debugPrint('❌ Background tracking: refresh token revoked, cannot recover');
        throw _RefreshTokenRevoked();
      }
      debugPrint('❌ Background tracking: refresh failed (transient): $e');
      return null;
    } catch (e) {
      debugPrint('❌ Background tracking: refresh failed: $e');
      return null;
    }
  }

  /// Main location tracking loop
  static void _startLocationTracking(ServiceInstance service) async {
    final driverId = await _storage.read(key: trackingDriverIdKey);
    if (driverId == null || driverId.isEmpty) {
      debugPrint('❌ Background tracking: no driver credential persisted');
      service.stopSelf();
      return;
    }

    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // Refreshed lazily by sendQueuedLocations() — cached in-memory for this
    // isolate's lifetime rather than refreshed on every single upload.
    String? accessToken;

    final List<Map<String, dynamic>> locationQueue = [];
    const maxQueueSize = 10;
    const uploadInterval = Duration(seconds: 60);

    Timer? uploadTimer;

    Future<bool> uploadBatch(String token) async {
      await dio.post(
        '/api/v1/tracking/locations/batch',
        data: {'locations': List<Map<String, dynamic>>.from(locationQueue)},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    }

    // On a definitive "this credential is dead" signal, stop retrying
    // forever (which would just drain battery with a permanently-stuck
    // notification) — forget the credential and shut the service down.
    Future<void> handleRevoked() async {
      uploadTimer?.cancel();
      await _storage.delete(key: trackingDriverIdKey);
      await _storage.delete(key: trackingRefreshTokenKey);
      service.stopSelf();
    }

    Future<void> sendQueuedLocations() async {
      if (locationQueue.isEmpty) return;

      try {
        accessToken ??= await _refreshAccessToken(dio);
      } on _RefreshTokenRevoked {
        await handleRevoked();
        return;
      }
      if (accessToken == null) {
        // No valid credential right now (transient — e.g. network down) —
        // leave the queue for the next cycle.
        debugPrint('⚠️ Background tracking: no access token, will retry next cycle');
        return;
      }

      try {
        await uploadBatch(accessToken!);
        locationQueue.clear();
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Fleet Tracking Active',
            content: 'Last sync: ${DateTime.now().toLocal().toString().substring(11, 16)}',
          );
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          // Access token expired mid-cycle — force a fresh one and retry once.
          try {
            accessToken = await _refreshAccessToken(dio);
          } on _RefreshTokenRevoked {
            await handleRevoked();
            return;
          }
          if (accessToken != null) {
            try {
              await uploadBatch(accessToken!);
              locationQueue.clear();
            } catch (e2) {
              debugPrint('❌ Background tracking: retry upload failed: $e2');
            }
          }
        } else {
          debugPrint('❌ Background tracking: upload failed: $e');
        }
      } catch (e) {
        debugPrint('❌ Background tracking: upload failed: $e');
      }
    }

    uploadTimer = Timer.periodic(uploadInterval, (_) {
      sendQueuedLocations();
    });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      timeLimit: Duration(seconds: 30),
    );

    await for (final position in Geolocator.getPositionStream(
      locationSettings: locationSettings,
    )) {
      final ts = position.timestamp;
      locationQueue.add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': ts.toUtc().toIso8601String(),
        'is_mock_location': position.isMocked,
      });

      debugPrint('📍 Background location: ${position.latitude}, ${position.longitude}');

      if (locationQueue.length >= maxQueueSize) {
        await sendQueuedLocations();
      }

      if (service is AndroidServiceInstance) {
        final now = DateTime.now();
        service.setForegroundNotificationInfo(
          title: 'Fleet Tracking Active',
          content: 'Last update: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        );
      }
    }

    uploadTimer.cancel();
    await sendQueuedLocations();
  }
}

/// Thrown by [BackgroundTrackingService._refreshAccessToken] when the
/// persisted refresh token is definitively rejected (401) rather than
/// failing transiently — e.g. the driver was removed from their org, or
/// their password changed. Signals the isolate to give up and shut down
/// instead of retrying forever against a credential that will never work
/// again.
class _RefreshTokenRevoked implements Exception {}
