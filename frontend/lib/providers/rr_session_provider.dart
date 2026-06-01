import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Session model ────────────────────────────────────────────────────────────

class RrSession {
  final String token;
  final String rrUserId;
  final DateTime expiresAt;

  const RrSession({
    required this.token,
    required this.rrUserId,
    required this.expiresAt,
  });

  /// True while the token is still valid (14-min window, 1 min before RR expiry).
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class RrSessionNotifier extends StateNotifier<RrSession?> {
  RrSessionNotifier() : super(null);

  void setSession({required String token, required String rrUserId}) {
    state = RrSession(
      token: token,
      rrUserId: rrUserId,
      expiresAt: DateTime.now().add(const Duration(minutes: 14)),
    );
  }

  void clear() => state = null;
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final rrSessionProvider =
    StateNotifierProvider<RrSessionNotifier, RrSession?>(
  (_) => RrSessionNotifier(),
);
