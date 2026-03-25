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

  Stream<NotificationModel> get stream => _controller.stream;

  void connect(String token) {
    if (_currentToken == token && _channel != null) return; // already connected
    _currentToken = token;
    _shouldReconnect = true;
    _doConnect(token);
  }

  void _doConnect(String token) {
    if (!_shouldReconnect) return;
    _channel?.sink.close();

    // Convert http → ws, https → wss
    final wsBase = AppConfig.apiBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    final uri = Uri.parse('$wsBase/ws/notifications?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller.add(NotificationModel.fromJson(data));
          } catch (_) {}
        },
        onDone: () {
          // Auto-reconnect after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (_shouldReconnect && _currentToken != null) {
              _doConnect(_currentToken!);
            }
          });
        },
        onError: (_) {
          Future.delayed(const Duration(seconds: 5), () {
            if (_shouldReconnect && _currentToken != null) {
              _doConnect(_currentToken!);
            }
          });
        },
        cancelOnError: false,
      );
    } catch (_) {
      Future.delayed(const Duration(seconds: 5), () {
        if (_shouldReconnect && _currentToken != null) {
          _doConnect(_currentToken!);
        }
      });
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _currentToken = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
