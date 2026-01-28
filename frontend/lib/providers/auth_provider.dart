import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/data/services/auth_api.dart';
import 'package:fleet_management/data/services/user_api.dart';
import 'package:fleet_management/data/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fleet_management/core/config/app_config.dart';

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

  AuthNotifier(this._authApi, this._storage, this._apiService, this._userApi) : super(AuthState()) {
    _loadStoredAuth();
  }

  /// Load stored authentication
  Future<void> _loadStoredAuth() async {
    try {
      final token = await _storage.read(key: AppConfig.tokenKey);

      if (token != null) {
        // Set token in API service
        _apiService.setToken(token);

        // Load user profile
        await loadUserProfile();

        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          isInitialized: true,
        );
      } else {
        state = state.copyWith(isInitialized: true);
      }
    } catch (e) {
      print('Error loading stored auth: $e');
      state = state.copyWith(isInitialized: true);
    }
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

      final token = response['access_token'] as String;
      final user = UserModel.fromJson(response);

      print('🔐 Login successful for user: ${user.username}');

      // Store token
      await _storage.write(key: AppConfig.tokenKey, value: token);

      // Set token in API service
      _apiService.setToken(token);

      // Load user profile with updated organization info
      await loadUserProfile();

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isInitialized: true,
        user: user,
        token: token,
      );

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
    await _storage.delete(key: AppConfig.tokenKey);

    // Remove token from API service
    _apiService.removeToken();

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
      final user = UserModel.fromJson(userData);

      state = state.copyWith(
        user: user,
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
        final token = response['access_token'] as String;

        // Store new token
        await _storage.write(key: AppConfig.tokenKey, value: token);

        // Set token in API service
        _apiService.setToken(token);

        // Update user info from response
        final user = UserModel.fromJson(response);

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
  return AuthNotifier(authApi, storage, apiService, userApi);
});
