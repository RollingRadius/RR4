import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/profile_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Profile API Provider
final profileApiProvider = Provider<ProfileApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProfileApi(apiService);
});

/// Profile State
class ProfileState {
  final bool isLoading;
  final bool profileCompleted;
  final String? error;
  final Map<String, dynamic>? profileData;

  ProfileState({
    this.isLoading = false,
    this.profileCompleted = false,
    this.error,
    this.profileData,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? profileCompleted,
    String? error,
    Map<String, dynamic>? profileData,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      error: error,
      profileData: profileData ?? this.profileData,
    );
  }
}

/// Profile Notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileApi _profileApi;

  ProfileNotifier(this._profileApi) : super(ProfileState());

  /// Get profile status
  Future<bool> getProfileStatus() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _profileApi.getProfileStatus();

      state = state.copyWith(
        isLoading: false,
        profileCompleted: response['profile_completed'] as bool,
        profileData: response,
      );

      return response['profile_completed'] as bool;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Complete profile
  Future<bool> completeProfile(Map<String, dynamic> profileData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _profileApi.completeProfile(profileData);

      state = state.copyWith(
        isLoading: false,
        profileCompleted: true,
        profileData: response,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Change user role (for Independent Users only)
  Future<bool> changeRole(Map<String, dynamic> profileData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _profileApi.changeRole(profileData);

      state = state.copyWith(
        isLoading: false,
        profileData: response,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update user profile information
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _profileApi.updateProfile(profileData);

      state = state.copyWith(
        isLoading: false,
        profileData: response,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

/// Profile Provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final profileApi = ref.watch(profileApiProvider);
  return ProfileNotifier(profileApi);
});
