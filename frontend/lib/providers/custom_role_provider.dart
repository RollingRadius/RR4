import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/custom_role_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';

String _extractError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    return e.message ?? e.toString();
  }
  return e.toString();
}

// API Provider
final customRoleApiProvider = Provider<CustomRoleApi>((ref) {
  final dio = ref.watch(dioProvider);
  return CustomRoleApi(dio);
});

// State class
class CustomRoleState {
  final bool isLoading;
  final String? error;
  final List<dynamic> customRoles;
  final Map<String, dynamic>? selectedRole;
  final Map<String, dynamic>? impactAnalysis;

  CustomRoleState({
    this.isLoading = false,
    this.error,
    this.customRoles = const [],
    this.selectedRole,
    this.impactAnalysis,
  });

  CustomRoleState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? customRoles,
    Map<String, dynamic>? selectedRole,
    Map<String, dynamic>? impactAnalysis,
  }) {
    return CustomRoleState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      customRoles: customRoles ?? this.customRoles,
      selectedRole: selectedRole ?? this.selectedRole,
      impactAnalysis: impactAnalysis ?? this.impactAnalysis,
    );
  }
}

// State Notifier
class CustomRoleNotifier extends StateNotifier<CustomRoleState> {
  final CustomRoleApi _api;

  CustomRoleNotifier(this._api) : super(CustomRoleState());

  Future<void> loadCustomRoles({bool includeTemplates = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getAllCustomRoles(includeTemplates: includeTemplates);
      state = state.copyWith(
        isLoading: false,
        customRoles: response['custom_roles'] as List<dynamic>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  Future<void> loadCustomRole(String customRoleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getCustomRole(customRoleId);
      state = state.copyWith(
        isLoading: false,
        selectedRole: response['custom_role'] as Map<String, dynamic>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  Future<bool> createCustomRole({
    required String roleName,
    String? description,
    required Map<String, String> capabilities,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.createCustomRole(
        roleName: roleName,
        description: description,
        capabilities: capabilities,
      );
      state = state.copyWith(isLoading: false);
      await loadCustomRoles();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<bool> createFromTemplate({
    required String roleName,
    required List<String> templateKeys,
    String? description,
    Map<String, String>? customizations,
    String mergeStrategy = 'union',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.createFromTemplate(
        roleName: roleName,
        templateKeys: templateKeys,
        description: description,
        customizations: customizations,
        mergeStrategy: mergeStrategy,
      );
      state = state.copyWith(isLoading: false);
      await loadCustomRoles();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<bool> updateCustomRole(
    String customRoleId, {
    String? roleName,
    String? description,
    Map<String, String>? capabilities,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.updateCustomRole(
        customRoleId,
        roleName: roleName,
        description: description,
        capabilities: capabilities,
      );
      state = state.copyWith(
        isLoading: false,
        selectedRole: response['custom_role'] as Map<String, dynamic>,
      );
      await loadCustomRoles();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<bool> deleteCustomRole(String customRoleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.deleteCustomRole(customRoleId);
      state = state.copyWith(isLoading: false);
      await loadCustomRoles();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<bool> cloneCustomRole(String customRoleId, String newRoleName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.cloneCustomRole(customRoleId, newRoleName);
      state = state.copyWith(isLoading: false);
      await loadCustomRoles();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<void> loadImpactAnalysis(String customRoleId) async {
    try {
      final response = await _api.getImpactAnalysis(customRoleId);
      state = state.copyWith(
        impactAnalysis: response['impact_analysis'] as Map<String, dynamic>,
      );
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
    }
  }

  Future<bool> saveAsTemplate(
    String customRoleId,
    String templateName, {
    String? templateDescription,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.saveAsTemplate(
        customRoleId,
        templateName,
        templateDescription: templateDescription,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }
}

// Provider
final customRoleProvider = StateNotifierProvider<CustomRoleNotifier, CustomRoleState>((ref) {
  final api = ref.watch(customRoleApiProvider);
  return CustomRoleNotifier(api);
});
