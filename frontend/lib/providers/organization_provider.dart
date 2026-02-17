import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/organization_api.dart';
import 'package:fleet_management/providers/theme_provider.dart';

/// Organization State (for multi-organization switching)
class OrganizationState {
  final String? currentOrganizationId;
  final Map<String, dynamic>? currentOrganization;
  final List<Map<String, dynamic>> organizations;
  final bool isLoading;
  final String? error;

  OrganizationState({
    this.currentOrganizationId,
    this.currentOrganization,
    this.organizations = const [],
    this.isLoading = false,
    this.error,
  });

  /// Get active organizations (status == 'active')
  List<Map<String, dynamic>> get activeOrganizations {
    return organizations.where((org) => org['status'] == 'active').toList();
  }

  OrganizationState copyWith({
    String? currentOrganizationId,
    Map<String, dynamic>? currentOrganization,
    List<Map<String, dynamic>>? organizations,
    bool? isLoading,
    String? error,
  }) {
    return OrganizationState(
      currentOrganizationId: currentOrganizationId ?? this.currentOrganizationId,
      currentOrganization: currentOrganization ?? this.currentOrganization,
      organizations: organizations ?? this.organizations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Organization Notifier (for multi-organization management)
class OrganizationNotifier extends StateNotifier<OrganizationState> {
  final OrganizationApi _organizationApi;
  final Ref _ref;

  OrganizationNotifier(this._organizationApi, this._ref) : super(OrganizationState());

  /// Load all organizations the user belongs to
  Future<void> loadOrganizations() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _organizationApi.getUserOrganizations();

      final organizations = (response['organizations'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // Find current organization (the first active one or first in list)
      final currentOrg = organizations.isNotEmpty
          ? organizations.firstWhere(
              (org) => org['status'] == 'active',
              orElse: () => organizations.first,
            )
          : null;

      state = state.copyWith(
        organizations: organizations,
        currentOrganizationId: currentOrg?['organization_id'],
        currentOrganization: currentOrg,
        isLoading: false,
      );

      // Load branding for current organization
      if (currentOrg != null) {
        _ref.read(themeProvider.notifier).loadBranding();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Switch to a different organization
  Future<bool> switchOrganization(String organizationId) async {
    try {
      await _organizationApi.switchOrganization(organizationId);

      // Find the organization in the list
      final org = state.organizations.firstWhere(
        (o) => o['organization_id'] == organizationId,
        orElse: () => {},
      );

      if (org.isNotEmpty) {
        state = state.copyWith(
          currentOrganizationId: organizationId,
          currentOrganization: org,
        );

        // Load branding for new organization
        _ref.read(themeProvider.notifier).loadBranding();

        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Organization Provider (for multi-organization management)
final organizationProvider =
    StateNotifierProvider<OrganizationNotifier, OrganizationState>((ref) {
  final organizationApi = ref.watch(organizationApiProvider);
  return OrganizationNotifier(organizationApi, ref);
});
