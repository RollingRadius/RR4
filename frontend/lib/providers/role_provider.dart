import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/models/role_model.dart';
import 'package:fleet_management/data/services/role_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Roles State
class RolesState {
  final List<RoleModel> roles;
  final List<PendingRoleRequest> pendingRequests;
  final bool isLoading;
  final String? error;

  RolesState({
    this.roles = const [],
    this.pendingRequests = const [],
    this.isLoading = false,
    this.error,
  });

  RolesState copyWith({
    List<RoleModel>? roles,
    List<PendingRoleRequest>? pendingRequests,
    bool? isLoading,
    String? error,
  }) {
    return RolesState(
      roles: roles ?? this.roles,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Roles Notifier
class RolesNotifier extends StateNotifier<RolesState> {
  final RoleApi _roleApi;

  RolesNotifier(this._roleApi) : super(RolesState());

  /// Load available roles from API
  Future<void> loadAvailableRoles() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _roleApi.getAvailableRoles();

      final roles = (response['roles'] as List)
          .map((r) => RoleModel.fromJson(r))
          .toList();

      state = state.copyWith(
        roles: roles,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load pending role requests (for owners)
  Future<void> loadPendingRequests() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _roleApi.getPendingRoleRequests();

      final requests = (response['pending_requests'] as List)
          .map((r) => PendingRoleRequest.fromJson(r))
          .toList();

      state = state.copyWith(
        pendingRequests: requests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Approve a role request
  Future<bool> approveRoleRequest(
    String userOrgId, {
    String? approvedRoleId,
  }) async {
    try {
      await _roleApi.approveRoleRequest(userOrgId, approvedRoleId: approvedRoleId);

      // Reload pending requests
      await loadPendingRequests();

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Reject a role request
  Future<bool> rejectRoleRequest(String userOrgId) async {
    try {
      await _roleApi.rejectRoleRequest(userOrgId);

      // Reload pending requests
      await loadPendingRequests();

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

/// Roles Provider
final rolesProvider = StateNotifierProvider<RolesNotifier, RolesState>((ref) {
  final roleApi = ref.watch(roleApiProvider);
  return RolesNotifier(roleApi);
});
