import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleet_management/data/models/notification_model.dart';
import 'package:fleet_management/data/services/notification_service.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// ─── WS service singleton ────────────────────────────────────────────────────

final notificationWsServiceProvider = Provider<NotificationWsService>((ref) {
  final svc = NotificationWsService();
  ref.onDispose(svc.dispose);
  return svc;
});

// ─── State ────────────────────────────────────────────────────────────────────

class NotificationsState {
  final List<NotificationModel> items;
  final bool loading;

  const NotificationsState({this.items = const [], this.loading = false});

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<NotificationModel>? items,
    bool? loading,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationWsService _ws;
  final Dio _dio;
  StreamSubscription<NotificationModel>? _sub;

  NotificationsNotifier(this._ws, this._dio) : super(const NotificationsState());

  /// Call once authentication is confirmed. Safe to call repeatedly.
  void start(String token) {
    _ws.connect(token);
    _sub ??= _ws.stream.listen(_onPush);
    _fetchAll();
  }

  void _onPush(NotificationModel notif) {
    // Prepend real-time notification; deduplicate by id
    if (state.items.any((n) => n.id == notif.id)) return;
    state = state.copyWith(items: [notif, ...state.items]);
  }

  Future<void> _fetchAll() async {
    state = state.copyWith(loading: true);
    try {
      final resp = await _dio.get('/api/notifications');
      final list = (resp.data['notifications'] as List)
          .map((j) => NotificationModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(items: list, loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> refresh() => _fetchAll();

  Future<void> markRead(String id) async {
    // Optimistic update
    state = state.copyWith(
      items: state.items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
    try {
      await _dio.patch('/api/notifications/$id/read');
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    state = state.copyWith(
      items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
    );
    try {
      await _dio.patch('/api/notifications/read-all');
    } catch (_) {}
  }

  Future<void> deleteOne(String id) async {
    state = state.copyWith(
      items: state.items.where((n) => n.id != id).toList(),
    );
    try {
      await _dio.delete('/api/notifications/$id');
    } catch (_) {}
  }

  Future<void> clearAll() async {
    state = state.copyWith(items: []);
    try {
      await _dio.delete('/api/notifications');
    } catch (_) {}
  }

  void stop() {
    _ws.disconnect();
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final ws  = ref.watch(notificationWsServiceProvider);
  final dio = ref.watch(dioProvider);
  final notifier = NotificationsNotifier(ws, dio);

  // Auto-start whenever the user becomes authenticated
  ref.listen<AuthState>(authProvider, (_, next) {
    if (next.isAuthenticated && next.token != null) {
      notifier.start(next.token!);
    } else {
      notifier.stop();
    }
  }, fireImmediately: true);

  return notifier;
});
