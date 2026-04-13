import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:fleet_management/data/models/user_model.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Topic names — must match backend
  static const String topicAllUsers = 'all_users';
  static const String topicLoadOwners = 'load_owners';
  static const String topicFleetManagers = 'fleet_managers';
  static const String topicDrivers = 'drivers';
  static const String topicLpWorkers = 'lp_workers';
  static const String topicLoWorkers = 'lo_workers';

  Future<void> initialize() async {
    if (kIsWeb) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('FCM foreground: ${message.notification?.title} - ${message.notification?.body}');
    });

    // App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('FCM opened from notification: ${message.data}');
    });

    // App launched from terminated state via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      print('FCM launched app: ${initial.data}');
    }
  }

  Future<String?> getToken() async {
    if (kIsWeb) return null;
    final token = await _messaging.getToken();
    print('FCM Token: $token');
    return token;
  }

  void onTokenRefresh(Function(String) callback) {
    if (kIsWeb) return;
    _messaging.onTokenRefresh.listen(callback);
  }

  /// Subscribe to all_users topic — call at signup (role not yet known)
  Future<void> subscribeToAllUsers() async {
    if (kIsWeb) return;
    await _messaging.subscribeToTopic(topicAllUsers);
    print('FCM: subscribed to $topicAllUsers');
  }

  /// Subscribe to role-specific topic — call after login/signup when role is known
  Future<void> subscribeToRoleTopic(UserModel user) async {
    if (kIsWeb) return;

    // Always subscribed to all_users
    await _messaging.subscribeToTopic(topicAllUsers);

    if (user.isLoadOwner) {
      await _messaging.subscribeToTopic(topicLoadOwners);
      print('FCM: subscribed to $topicLoadOwners');
    } else if (user.isLogisticPartner) {
      await _messaging.subscribeToTopic(topicFleetManagers);
      print('FCM: subscribed to $topicFleetManagers');
    } else if (user.isDriver) {
      await _messaging.subscribeToTopic(topicDrivers);
      print('FCM: subscribed to $topicDrivers');
    } else if (user.isLogisticPartnerWorker) {
      await _messaging.subscribeToTopic(topicLpWorkers);
      print('FCM: subscribed to $topicLpWorkers');
    } else if (user.isLoadOwnerWorker) {
      await _messaging.subscribeToTopic(topicLoWorkers);
      print('FCM: subscribed to $topicLoWorkers');
    }
  }

  /// Unsubscribe from role topics on logout (keeps all_users)
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
    print('FCM: unsubscribed from role topics');
  }
}
