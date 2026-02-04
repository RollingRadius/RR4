import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Temporarily disabled
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background Tracking Service
/// Handles persistent location tracking when app is in background
class BackgroundTrackingService {
  static const String _serviceKey = 'background_tracking_service';
  static const String _notificationChannelId = 'fleet_tracking';
  static const String _notificationChannelName = 'Fleet Tracking';

  /// Initialize background service
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Create notification channel for Android
    // Temporarily disabled - flutter_local_notifications causing build issues
    /*
    const androidChannel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'Active GPS tracking for fleet management',
      importance: Importance.low,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    */

    // Configure background service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
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

  /// Start background tracking
  static Future<bool> start() async {
    final service = FlutterBackgroundService();
    return await service.startService();
  }

  /// Stop background tracking
  static Future<bool> stop() async {
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
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// Update notification
  static void updateNotification({
    required String title,
    required String content,
  }) {
    final service = FlutterBackgroundService();
    service.invoke('updateNotification', {
      'title': title,
      'content': content,
    });
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

    // Handle stop command
    service.on('stop').listen((event) {
      service.stopSelf();
    });

    // Handle notification update
    service.on('updateNotification').listen((event) {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: event!['title'] ?? 'Fleet Tracking Active',
          content: event['content'] ?? 'Tracking your location',
        );
      }
    });

    // Start location tracking loop
    _startLocationTracking(service);
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Main location tracking loop
  static void _startLocationTracking(ServiceInstance service) async {
    // Load configuration from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final apiUrl = prefs.getString('api_url') ?? '';
    final authToken = prefs.getString('auth_token') ?? '';

    if (apiUrl.isEmpty || authToken.isEmpty) {
      debugPrint('❌ Background tracking: Missing API credentials');
      service.stopSelf();
      return;
    }

    // Location queue for batch uploads
    final List<Map<String, dynamic>> locationQueue = [];
    const maxQueueSize = 10;
    const uploadInterval = Duration(minutes: 5);

    Timer? uploadTimer;

    // Function to send queued locations
    Future<void> sendQueuedLocations() async {
      if (locationQueue.isEmpty) return;

      try {
        // TODO: Implement actual API call
        // For now, just clear queue
        debugPrint('📤 Sending ${locationQueue.length} locations from background');
        locationQueue.clear();

        // Update notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Fleet Tracking Active',
            content: 'Last sync: ${DateTime.now().toLocal().toString().substring(11, 16)}',
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to send locations: $e');
      }
    }

    // Start periodic upload timer
    uploadTimer = Timer.periodic(uploadInterval, (_) {
      sendQueuedLocations();
    });

    // Location stream
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      timeLimit: Duration(seconds: 30),
    );

    await for (final position in Geolocator.getPositionStream(
      locationSettings: locationSettings,
    )) {
      // Check if service should stop
      if (!(await service.isRunning())) {
        uploadTimer?.cancel();
        break;
      }

      // Add location to queue
      locationQueue.add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': position.timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'is_mock_location': position.isMocked,
      });

      debugPrint('📍 Background location: ${position.latitude}, ${position.longitude}');

      // Send if queue is full
      if (locationQueue.length >= maxQueueSize) {
        await sendQueuedLocations();
      }

      // Update notification with last location time
      if (service is AndroidServiceInstance) {
        final now = DateTime.now();
        service.setForegroundNotificationInfo(
          title: 'Fleet Tracking Active',
          content: 'Last update: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        );
      }
    }

    // Clean up
    uploadTimer?.cancel();
    await sendQueuedLocations();
  }
}

/// Background Tracking Configuration
class BackgroundTrackingConfig {
  final Duration updateInterval;
  final double distanceFilter;
  final LocationAccuracy accuracy;

  const BackgroundTrackingConfig({
    this.updateInterval = const Duration(seconds: 30),
    this.distanceFilter = 10.0,
    this.accuracy = LocationAccuracy.high,
  });

  /// Save config to preferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bg_tracking_interval', updateInterval.inSeconds);
    await prefs.setDouble('bg_tracking_distance', distanceFilter);
    await prefs.setString('bg_tracking_accuracy', accuracy.toString());
  }

  /// Load config from preferences
  static Future<BackgroundTrackingConfig> load() async {
    final prefs = await SharedPreferences.getInstance();

    final interval = prefs.getInt('bg_tracking_interval') ?? 30;
    final distance = prefs.getDouble('bg_tracking_distance') ?? 10.0;
    final accuracyStr = prefs.getString('bg_tracking_accuracy') ?? 'LocationAccuracy.high';

    LocationAccuracy accuracy = LocationAccuracy.high;
    if (accuracyStr.contains('best')) {
      accuracy = LocationAccuracy.best;
    } else if (accuracyStr.contains('medium')) {
      accuracy = LocationAccuracy.medium;
    } else if (accuracyStr.contains('low')) {
      accuracy = LocationAccuracy.low;
    }

    return BackgroundTrackingConfig(
      updateInterval: Duration(seconds: interval),
      distanceFilter: distance,
      accuracy: accuracy,
    );
  }
}
