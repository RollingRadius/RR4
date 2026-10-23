import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/data/models/notification_model.dart';

/// Manages a single WebSocket connection for real-time push notifications.
/// Call [connect] once the user is authenticated; call [disconnect] on logout.
class NotificationWsService {
  WebSocketChannel? _channel;
  final _controller = StreamController<NotificationModel>.broadcast();
  String? _currentToken;
  bool _shouldReconnect = false;
  Timer? _retryTimer;
  int _attempts = 0;

  Stream<NotificationModel> get stream => _controller.stream;

  void connect(String token) {
    if (_currentToken == token && _channel != null) return; // already connected
    _currentToken = token;
    _shouldReconnect = true;
    _doConnect(token);
  }

  void _doConnect(String token) {
    if (!_shouldReconnect) return;
    _retryTimer?.cancel();
    final old = _channel;
    _channel = null;
    old?.sink.close();

    // Convert http → ws, https → wss
    final wsBase = AppConfig.apiBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    final uri = Uri.parse('$wsBase/ws/notifications?token=$token');
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      channel.stream.listen(
        (raw) {
          _attempts = 0;
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller.add(NotificationModel.fromJson(data));
          } catch (_) {}
        },
        onDone: () {
          // Close code 4001 = server permanently rejected (no role/org) — don't retry
          if (channel.closeCode == 4001) return;
          _scheduleReconnect(channel);
        },
        onError: (error) {
          // HTTP 403 during WebSocket upgrade = permanent rejection — don't retry
          final msg = error.toString();
          if (msg.contains('403') || msg.contains('401')) return;
          _scheduleReconnect(channel);
        },
        cancelOnError: false,
      );
    } catch (_) {
      _scheduleReconnect(_channel);
    }
  }

  /// Ignores events from superseded channels and keeps a single pending retry,
  /// backing off 5s → 60s so a failing server isn't hammered.
  void _scheduleReconnect(WebSocketChannel? channel) {
    if (!identical(channel, _channel)) return;
    _retryTimer?.cancel();
    final seconds = (5 * (1 << _attempts)).clamp(5, 60);
    if (_attempts < 4) _attempts++;
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (_shouldReconnect && _currentToken != null) {
        _doConnect(_currentToken!);
      }
    });
  }

  void disconnect() {
    _shouldReconnect = false;
    _retryTimer?.cancel();
    _attempts = 0;
    _currentToken = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
