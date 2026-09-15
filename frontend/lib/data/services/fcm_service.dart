import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fleet_management/data/models/user_model.dart';

// ── Notification channel definition ──────────────────────────────────────────

const _kChannelId   = 'fleet_notifications';
const _kChannelName = 'Fleet Notifications';
const _kChannelDesc = 'Trip updates, load assignments, and alerts';

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  _kChannelId,
  _kChannelName,
  description: _kChannelDesc,
  importance: Importance.high,
);

const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
  _kChannelId,
  _kChannelName,
  channelDescription: _kChannelDesc,
  importance: Importance.high,
  priority: Priority.high,
  icon: '@mipmap/ic_launcher',
);

const NotificationDetails _notificationDetails = NotificationDetails(
  android: _androidDetails,
);

// ── Local notifications plugin (module-level singleton) ───────────────────────

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

// ── Service class ─────────────────────────────────────────────────────────────

class FcmService {
  // Lazy getter — only accessed inside methods that are already guarded by kIsWeb checks.
  // Avoids calling FirebaseMessaging.instance at construction time on web.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  // Topic names — must match backend constants
  static const String topicAllUsers     = 'all_users';
  static const String topicLoadOwners   = 'load_owners';
  static const String topicFleetManagers = 'fleet_managers';
  static const String topicDrivers      = 'drivers';
  static const String topicLpWorkers    = 'lp_workers';
  static const String topicLoWorkers    = 'lo_workers';

  /// Set once from the widget tree (where a Ref is available — FcmService
  /// itself has none) to react to a silent, data-only "trip_reassigned" push
  /// (see backend's driver_link_service.py:_nudge_driver_refresh). This is a
  /// best-effort latency nudge only — the existing periodic poll remains the
  /// source of truth whether or not this ever fires.
  static void Function()? onTripReassignedNudge;

  Future<void> initialize() async {
    if (kIsWeb) return;

    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize flutter_local_notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Create the notification channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Show a local notification for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Silent data-only nudge — no visible banner, just an instant refresh
      // trigger. Handled before the notification-payload early-return below,
      // since this message type intentionally carries no `notification` block.
      if (message.data['type'] == 'trip_reassigned') {
        onTripReassignedNudge?.call();
      }

      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        _notificationDetails,
      );
    });

    // App opened from background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Navigate based on message.data if needed in the future
    });

    // App launched from terminated state via notification tap
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      // Handle cold-start navigation here if needed
    }
  }

  Future<String?> getToken() async {
    if (kIsWeb) return null;
    return await _messaging.getToken();
  }

  void onTokenRefresh(Function(String) callback) {
    if (kIsWeb) return;
    _messaging.onTokenRefresh.listen(callback);
  }

  /// Subscribe to all_users topic — call at signup (role not yet known)
  Future<void> subscribeToAllUsers() async {
    if (kIsWeb) return;
    await _messaging.subscribeToTopic(topicAllUsers);
  }

  /// Subscribe to role-specific topic — call after login/signup when role is known
  Future<void> subscribeToRoleTopic(UserModel user) async {
    if (kIsWeb) return;

    await _messaging.subscribeToTopic(topicAllUsers);

    if (user.isLoadOwner) {
      await _messaging.subscribeToTopic(topicLoadOwners);
    } else if (user.isLogisticPartner) {
      await _messaging.subscribeToTopic(topicFleetManagers);
    } else if (user.isDriver) {
      await _messaging.subscribeToTopic(topicDrivers);
    } else if (user.isLogisticPartnerWorker) {
      await _messaging.subscribeToTopic(topicLpWorkers);
    } else if (user.isLoadOwnerWorker) {
      await _messaging.subscribeToTopic(topicLoWorkers);
    }
  }

  /// Unsubscribe from role topics on logout
  Future<void> unsubscribeFromRoleTopics() async {
    if (kIsWeb) return;
    for (final topic in [
      topicLoadOwners,
      topicFleetManagers,
      topicDrivers,
      topicLpWorkers,
      topicLoWorkers,
    ]) {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }
}
