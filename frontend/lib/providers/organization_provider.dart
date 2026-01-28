import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/user_api.dart';
import 'package:fleet_management/data/services/organization_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Organization API Provider
final organizationApiProvider = Provider<OrganizationApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return OrganizationApi(apiService);
});

/// Organization State
class OrganizationState {
  final List<Map<String, dynamic>> organizations;
  final String? currentOrganizationId;
  final bool isLoading;
  final String? error;

  OrganizationState({
    this.organizations = const [],
    this.currentOrganizationId,
    this.isLoading = false,
    this.error,
  });

  OrganizationState copyWith({
    List<Map<String, dynamic>>? organizations,
    String? currentOrganizationId,
    bool? isLoading,
    String? error,
  }) {
    return OrganizationState(
      organizations: organizations ?? this.organizations,
      currentOrganizationId: currentOrganizationId ?? this.currentOrganizationId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  Map<String, dynamic>? get currentOrganization {
    if (currentOrganizationId == null) return null;
    try {
      return organizations.firstWhere(
        (org) => org['organization_id'] == currentOrganizationId,
      );
    } catch (e) {
      return null;
    }
  }

  bool get hasMultipleOrganizations => organizations.length > 1;

  List<Map<String, dynamic>> get activeOrganizations {
    return organizations.where((org) => org['is_active'] == true).toList();
  }
}

/// Organization Notifier
class OrganizationNotifier extends StateNotifier<OrganizationState> {
  final UserApi _userApi;

  OrganizationNotifier(this._userApi) : super(OrganizationState());

  /// Load user's organizations
  Future<void> loadOrganizations() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final organizations = await _userApi.getUserOrganizations();

      // Set the first active organization as current if not set
      String? currentOrgId = state.currentOrganizationId;
      if (currentOrgId == null && organizations.isNotEmpty) {
        final firstActive = organizations.firstWhere(
          (org) => org['is_active'] == true,
          orElse: () => organizations.first,
        );
        currentOrgId = firstActive['organization_id'];
      }

      state = state.copyWith(
        organizations: organizations,
        currentOrganizationId: currentOrgId,
        isLoading: false,
      );
    } catch (e) {
      // Silently fail if unauthorized (user not logged in)
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        state = state.copyWith(
          isLoading: false,
          organizations: [],
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  /// Switch to a different organization
  Future<bool> switchOrganization(String organizationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _userApi.setActiveOrganization(organizationId);

      state = state.copyWith(
        currentOrganizationId: organizationId,
        isLoading: false,
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

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Organization Provider
final organizationProvider = StateNotifierProvider<OrganizationNotifier, OrganizationState>((ref) {
  final userApi = ref.watch(userApiProvider);
  return OrganizationNotifier(userApi);
});
