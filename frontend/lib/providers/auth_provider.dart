import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/data/services/auth_api.dart';
import 'package:fleet_management/data/services/user_api.dart';
import 'package:fleet_management/data/services/fcm_service.dart';
import 'package:fleet_management/data/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/providers/rr_session_provider.dart';

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());

/// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Dio Provider (for services that use Dio directly)
final dioProvider = Provider<Dio>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.dio;
});

/// Auth API Provider
final authApiProvider = Provider<AuthApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthApi(apiService);
});

/// Secure Storage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Auth State
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isInitialized;
  final UserModel? user;
  final String? token;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isInitialized = false,
    this.user,
    this.token,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isInitialized,
    UserModel? user,
    String? token,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error,
    );
  }
}

/// User API Provider
final userApiProvider = Provider<UserApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserApi(apiService);
});

/// Auth Provider
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;
  final FlutterSecureStorage _storage;
  final ApiService _apiService;
  final UserApi _userApi;
  final FcmService _fcmService;
  final Ref _ref;

  Timer? _expiryTimer;
  Timer? _preRefreshTimer;
  Future<bool>? _refreshInFlight;

  AuthNotifier(this._authApi, this._storage, this._apiService, this._userApi, this._fcmService, this._ref) : super(AuthState()) {
    // The interceptor's 401-recovery must use the long-lived refresh-token
    // exchange (_restoreViaRefreshToken → /api/auth/refresh), NOT the
    // org-context refreshToken() below (/api/user/refresh-token) — that
    // endpoint requires a STILL-VALID access token, so it can never recover
    // from the exact case it was wired to handle (genuine token expiry).
    // Every 401 caused by real expiry was silently forcing a full logout
    // instead of the silent session restore that's already implemented and
    // working at cold-start via _loadStoredAuth.
    _apiService.setAuthCallbacks(onRefresh: _restoreViaRefreshTokenDeduped, onLogout: logout);
    _loadStoredAuth();
  }

  /// Decode the `exp` claim from a JWT without any extra package.
  DateTime? _getTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      // Normalize base64url padding
      var payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
    } catch (_) {
      return null;
    }
  }

  /// Cancel any existing expiry timers and set new ones.
  /// - 10 min before expiry: silently refresh so active users are never interrupted.
  /// - At expiry: logout (only reached if the silent refresh failed).
  void _scheduleExpiryLogout(String token) {
    _expiryTimer?.cancel();
    _preRefreshTimer?.cancel();
    final expiry = _getTokenExpiry(token);
    if (expiry == null) return;
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) {
      logout();
      return;
    }

    // Silent pre-expiry refresh — fires 10 min before expiry
    const preRefreshBuffer = Duration(minutes: 10);
    final preRefreshIn = remaining - preRefreshBuffer;
    if (preRefreshIn > Duration.zero) {
      _preRefreshTimer = Timer(preRefreshIn, () async {
        print('⏱️ Pre-expiry refresh triggered');
        final ok = await refreshToken();
        if (!ok) {
          // Refresh failed — hard logout at actual expiry (timer still running)
          print('⚠️ Pre-expiry refresh failed — will logout at expiry');
        }
      });
    }

    // Hard logout at expiry (cancelled if pre-refresh succeeds and reschedules)
    _expiryTimer = Timer(remaining, () {
      print('⏱️ Token expired — auto-logout');
      logout();
    });
    print('⏱️ Session: expires in ${remaining.inMinutes} min, refresh in ${preRefreshIn > Duration.zero ? (preRefreshIn.inMinutes) : 0} min');
  }

  /// Called on app resume to verify the stored token hasn't expired in the background.
  void checkTokenExpiry() {
    final token = state.token;
    if (token == null || !state.isAuthenticated) return;
    final expiry = _getTokenExpiry(token);
    if (expiry == null) return;
    if (DateTime.now().isAfter(expiry)) {
      print('⏱️ Token expired while app was in background — logging out');
      logout();
    } else {
      // Reschedule in case OS killed the timer while suspended
      _scheduleExpiryLogout(token);
    }
  }

  /// Load stored authentication
  Future<void> _loadStoredAuth() async {
    try {
      final rawToken = await _storage.read(key: AppConfig.tokenKey);
      final token = rawToken?.replaceAll(RegExp(r'\s+'), '');

      if (token != null && token.isNotEmpty) {
        final expiry = _getTokenExpiry(token);
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          // Access token itself has expired (e.g. app wasn't opened for a
          // day or more) — try the long-lived refresh token before giving
          // up, so this doesn't force a fresh login just because of a gap
          // longer than the access token's own lifetime.
          print('⏱️ Stored access token expired — trying refresh token');
          final restored = await _restoreViaRefreshTokenDeduped();
          if (!restored) {
            await _storage.delete(key: AppConfig.tokenKey);
            await _storage.delete(key: AppConfig.refreshTokenKey);
            state = state.copyWith(isInitialized: true);
          }
          return;
        }

        await _applyRestoredSession(token);
      } else {
        state = state.copyWith(isInitialized: true);
      }
    } catch (e) {
      print('Error loading stored auth: $e');
      // Undecryptable secure-storage entry (e.g. Keystore key rotated after
      // reinstall) would otherwise fail identically on every future launch.
      await _storage.delete(key: AppConfig.tokenKey);
      await _storage.delete(key: AppConfig.refreshTokenKey);
      state = state.copyWith(isInitialized: true);
    }
  }

  /// Shared by _loadStoredAuth's "still valid" path and the refresh-token
  /// restore path below — sets up everything a freshly-restored session
  /// needs, identically either way.
  Future<void> _applyRestoredSession(String token) async {
    _apiService.setToken(token);
    await loadUserProfile();
    _scheduleExpiryLogout(token);

    state = state.copyWith(
      isAuthenticated: true,
      token: token,
      isInitialized: true,
    );

    final user = state.user;
    if (user != null) {
      await _subscribeToTopicsIfNeeded(user);
      _sendFcmTokenToBackend();
    }
  }

  /// The access token has expired — use the long-lived refresh token (if
  /// any is stored) to get a fresh pair without showing a login screen.
  /// Returns true if the session was successfully restored this way.
  Future<bool> _restoreViaRefreshToken() async {
    final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _authApi.refreshSession(refreshToken);
      final rawToken = response['access_token'] as String;
      final newToken = rawToken.replaceAll(RegExp(r'\s+'), '');
      final newRefreshToken = response['refresh_token'] as String?;

      await _storage.write(key: AppConfig.tokenKey, value: newToken);
      if (newRefreshToken != null) {
        await _storage.write(key: AppConfig.refreshTokenKey, value: newRefreshToken);
      }

      await _applyRestoredSession(newToken);
      print('🔄 Session restored via long-lived refresh token');
      return true;
    } catch (e) {
      // Refresh token itself expired/revoked — genuinely needs a fresh login.
      print('⚠️ Refresh token restore failed: $e');
      return false;
    }
  }

  /// The refresh token is single-use (rotated server-side on every exchange)
  /// — if several requests 401 around the same time (common right after
  /// resume, when multiple screens fetch data in parallel), each one calling
  /// _restoreViaRefreshToken independently would race: the first call's
  /// rotation revokes the token the second call is still holding, failing it
  /// even though the session is actually fine. This makes every concurrent
  /// caller share one in-flight attempt instead.
  Future<bool> _restoreViaRefreshTokenDeduped() {
    return _refreshInFlight ??= _restoreViaRefreshToken().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  /// Login
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authApi.login(
        username: username,
        password: password,
      );

      final rawToken = response['access_token'] as String;
      // Strip ALL whitespace to prevent Android Keystore base64-wrap corruption
      final token = rawToken.replaceAll(RegExp(r'\s+'), '');
      final user = UserModel.fromJson(response);

      print('🔐 Login successful for user: ${user.username}');

      // Store cleaned token
      await _storage.write(key: AppConfig.tokenKey, value: token);

      // Long-lived refresh token — lets a future launch restore this session
      // even after the access token itself has genuinely expired.
      final refreshToken = response['refresh_token'] as String?;
      if (refreshToken != null) {
        await _storage.write(key: AppConfig.refreshTokenKey, value: refreshToken);
      }

      // Set token in API service
      _apiService.setToken(token);

      // Set state with login-response user FIRST so role-based routing
      // (isLoadOwner, isLogisticPartner) is always correct before navigation.
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isInitialized: true,
        user: user,
        token: token,
      );

      _scheduleExpiryLogout(token);

      // Enrich profile with full_name / phone in the background.
      // loadUserProfile now preserves role_key if the server omits it.
      await loadUserProfile();

      // Subscribe to role topics (once) + sync FCM token if changed
      final updatedUser = state.user;
      if (updatedUser != null) {
        await _subscribeToTopicsIfNeeded(updatedUser);
        _sendFcmTokenToBackend();
      }

      // When Firebase rotates the token, send the new one to backend
      _fcmService.onTokenRefresh((newToken) {
        _apiService.dio.post('/api/user/fcm-token', data: {'fcm_token': newToken});
      });

      return true;
    } catch (e) {
      print('❌ Login failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Signup
  Future<Map<String, dynamic>?> signup(Map<String, dynamic> signupData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authApi.signup(signupData);

      state = state.copyWith(isLoading: false);

      // Subscribe to all_users at signup — role not yet known.
      // Role-specific topics are subscribed on first login once role is assigned.
      final alreadySubscribed = await _storage.read(key: 'fcm_topics_subscribed');
      if (alreadySubscribed != 'true') {
        await _fcmService.subscribeToAllUsers();
      }

      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _preRefreshTimer?.cancel();
    _preRefreshTimer = null;

    // Revoke server-side (best-effort) so this session actually ends, not
    // just on this device — read before deleting, otherwise there's nothing
    // left to send.
    final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
    unawaited(_authApi.logout(refreshToken));

    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);

    // FCM token stays in DB and topic subscriptions stay active on the device —
    // push notifications continue to reach this device even when logged out.

    _apiService.removeToken();
    _ref.read(rrSessionProvider.notifier).clear();
    state = AuthState();
  }

  /// Verify email
  Future<bool> verifyEmail(String token) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authApi.verifyEmail(token);

      state = state.copyWith(isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Verify email with 6-digit code
  Future<bool> verifyEmailCode(String verificationCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authApi.verifyEmailCode(verificationCode);

      state = state.copyWith(isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Load user profile
  Future<void> loadUserProfile() async {
    try {
      final userData = await _userApi.getCurrentUser();
      final profileUser = UserModel.fromJson(userData);

      // If the server didn't return role/businessType, preserve what we
      // already have in state so routing decisions stay correct.
      final current = state.user;
      final mergedRoleKey = profileUser.roleKey ?? current?.roleKey;
      final mergedBusinessType =
          profileUser.businessType ?? current?.businessType;

      final mergedUser = (mergedRoleKey != profileUser.roleKey ||
              mergedBusinessType != profileUser.businessType)
          ? UserModel(
              userId: profileUser.userId,
              username: profileUser.username,
              email: profileUser.email,
              fullName: profileUser.fullName,
              phone: profileUser.phone,
              authMethod: profileUser.authMethod,
              status: profileUser.status,
              profileCompleted: profileUser.profileCompleted,
              companyId: profileUser.companyId,
              companyName: profileUser.companyName,
              businessType: mergedBusinessType,
              role: profileUser.role,
              roleKey: mergedRoleKey,
            )
          : profileUser;

      state = state.copyWith(
        user: mergedUser,
        isAuthenticated: true,
      );
    } catch (e) {
      print('❌ Failed to load user profile: $e');
      // Don't throw error, user is still authenticated
    }
  }

  /// Refresh token - Get new JWT token with updated organization context
  Future<bool> refreshToken() async {
    try {
      final response = await _userApi.refreshToken();

      if (response['access_token'] != null) {
        final token = (response['access_token'] as String).replaceAll(RegExp(r'\s+'), '');

        // Store new token
        await _storage.write(key: AppConfig.tokenKey, value: token);

        // Set token in API service
        _apiService.setToken(token);

        // Update user info from response
        final user = UserModel.fromJson(response);

        _scheduleExpiryLogout(token);

        state = state.copyWith(
          token: token,
          user: user,
        );

        print('🔄 Token refreshed successfully');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Failed to refresh token: $e');
      return false;
    }
  }

  /// Send FCM token to backend on every login so each user account on this
  /// device has their token registered (multiple users can share one device).
  Future<void> _sendFcmTokenToBackend() async {
    try {
      final token = await _fcmService.getToken();
      if (token == null) return;
      await _apiService.dio.post('/api/user/fcm-token', data: {'fcm_token': token});
      print('✅ FCM token sent to backend');
    } catch (e) {
      print('⚠️ FCM token send failed (non-critical): $e');
    }
  }

  /// Subscribe to role topics only once (persisted in secure storage).
  /// Firebase subscriptions survive app restarts, so this only runs once
  /// per device install when the user's role is first known.
  Future<void> _subscribeToTopicsIfNeeded(UserModel user) async {
    try {
      final alreadySubscribed =
          await _storage.read(key: 'fcm_topics_subscribed');
      if (alreadySubscribed == 'true') return;
      await _fcmService.subscribeToRoleTopic(user);
      await _storage.write(key: 'fcm_topics_subscribed', value: 'true');
      print('✅ FCM role topics subscribed');
    } catch (e) {
      // A stale/undecryptable secure-storage entry (e.g. Keystore key
      // rotated after reinstall) must not fail the calling login flow.
      print('⚠️ FCM topic subscription check failed (non-critical): $e');
      await _storage.delete(key: 'fcm_topics_subscribed');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authApi = ref.watch(authApiProvider);
  final storage = ref.watch(secureStorageProvider);
  final apiService = ref.watch(apiServiceProvider);
  final userApi = ref.watch(userApiProvider);
  final fcmService = ref.watch(fcmServiceProvider);
  return AuthNotifier(authApi, storage, apiService, userApi, fcmService, ref);
});
