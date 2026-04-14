import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── User ──────────────────────────────────────────────────────────────────

  Future<void> setUser(String userId, String role) async {
    if (kIsWeb) return;
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'role', value: role);
  }

  Future<void> clearUser() async {
    if (kIsWeb) return;
    await _analytics.setUserId(id: null);
  }

  // ── Auth events ───────────────────────────────────────────────────────────

  Future<void> logLogin(String role) async {
    if (kIsWeb) return;
    await _analytics.logLogin(loginMethod: role);
  }

  Future<void> logSignUp(String role) async {
    if (kIsWeb) return;
    await _analytics.logSignUp(signUpMethod: role);
  }

  // ── Load events ───────────────────────────────────────────────────────────

  Future<void> logLoadPosted() async {
    if (kIsWeb) return;
    await _analytics.logEvent(name: 'load_posted');
  }

  Future<void> logLoadAccepted() async {
    if (kIsWeb) return;
    await _analytics.logEvent(name: 'load_accepted');
  }

  // ── Trip events ───────────────────────────────────────────────────────────

  Future<void> logTripCreated() async {
    if (kIsWeb) return;
    await _analytics.logEvent(name: 'trip_created');
  }

  Future<void> logStageCompleted(int stage) async {
    if (kIsWeb) return;
    await _analytics.logEvent(
      name: 'stage_completed',
      parameters: {'stage': stage},
    );
  }

  Future<void> logTripCompleted() async {
    if (kIsWeb) return;
    await _analytics.logEvent(name: 'trip_completed');
  }

  // ── Screen tracking (manual, for screens not in the navigator) ────────────

  Future<void> logScreen(String screenName) async {
    if (kIsWeb) return;
    await _analytics.logScreenView(screenName: screenName);
  }
}
