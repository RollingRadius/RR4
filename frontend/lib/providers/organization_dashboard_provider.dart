import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/organization_dashboard_api.dart';

/// Organization Dashboard State (for owner dashboard view)
class OrganizationDashboardState {
  final Map<String, dynamic>? organization;
  final Map<String, dynamic>? statistics;
  final List<Map<String, dynamic>> employees;
  final bool isLoading;
  final String? error;

  OrganizationDashboardState({
    this.organization,
    this.statistics,
    this.employees = const [],
    this.isLoading = false,
    this.error,
  });

  OrganizationDashboardState copyWith({
    Map<String, dynamic>? organization,
    Map<String, dynamic>? statistics,
    List<Map<String, dynamic>>? employees,
    bool? isLoading,
    String? error,
  }) {
    return OrganizationDashboardState(
      organization: organization ?? this.organization,
      statistics: statistics ?? this.statistics,
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Organization Dashboard Notifier (for owner dashboard operations)
class OrganizationDashboardNotifier extends StateNotifier<OrganizationDashboardState> {
  final OrganizationDashboardApi _organizationDashboardApi;

  OrganizationDashboardNotifier(this._organizationDashboardApi) : super(OrganizationDashboardState());

  /// Load organization details with statistics
  Future<void> loadMyOrganization() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _organizationDashboardApi.getMyOrganization();

      state = state.copyWith(
        organization: response['organization'],
        statistics: response['statistics'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load employees
  Future<void> loadEmployees({
    String? roleFilter,
    String statusFilter = 'active',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _organizationDashboardApi.getEmployees(
        roleFilter: roleFilter,
        statusFilter: statusFilter,
      );

      final employees = (response['employees'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      state = state.copyWith(
        employees: employees,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load statistics
  Future<void> loadStatistics() async {
    try {
      final response = await _organizationDashboardApi.getStatistics();

      state = state.copyWith(
        statistics: response['statistics'],
      );
    } catch (e) {
      // Don't set error state for statistics failure
      print('Failed to load statistics: $e');
    }
  }

  /// Update employee role
  Future<bool> updateEmployeeRole(String userOrgId, String newRoleId) async {
    try {
      await _organizationDashboardApi.updateEmployeeRole(userOrgId, newRoleId);

      // Reload employees to show updated role
      await loadEmployees();
      await loadStatistics();

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Remove employee
  Future<bool> removeEmployee(String userOrgId) async {
    try {
      await _organizationDashboardApi.removeEmployee(userOrgId);

      // Reload employees to show updated list
      await loadEmployees();
      await loadStatistics();

      return true;
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

/// Organization Dashboard Provider (for owner dashboard)
final organizationDashboardProvider =
    StateNotifierProvider<OrganizationDashboardNotifier, OrganizationDashboardState>((ref) {
  final organizationDashboardApi = ref.watch(organizationDashboardApiProvider);
  return OrganizationDashboardNotifier(organizationDashboardApi);
});
