import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/auth_provider.dart';

String _extractOrgError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    return e.message ?? e.toString();
  }
  return e.toString();
}

class OrgMembersState {
  final bool isLoading;
  final String? error;
  final List<dynamic> members;

  const OrgMembersState({
    this.isLoading = false,
    this.error,
    this.members = const [],
  });

  OrgMembersState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? members,
  }) {
    return OrgMembersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      members: members ?? this.members,
    );
  }
}

class OrgMembersNotifier extends StateNotifier<OrgMembersState> {
  final Dio _dio;

  OrgMembersNotifier(this._dio) : super(const OrgMembersState());

  Future<void> loadMembers({String statusFilter = 'active'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.get(
        '/api/organization/employees',
        queryParameters: {'status_filter': statusFilter},
      );
      state = state.copyWith(
        isLoading: false,
        members: res.data['employees'] as List<dynamic>? ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractOrgError(e));
    }
  }

  Future<bool> updateMemberRole(String userOrgId, String newRoleId) async {
    try {
      await _dio.put(
        '/api/organization/employees/$userOrgId/role',
        queryParameters: {'new_role_id': newRoleId},
      );
      await loadMembers();
      return true;
    } catch (e) {
      state = state.copyWith(error: _extractOrgError(e));
      return false;
    }
  }
}

final orgMembersProvider =
    StateNotifierProvider<OrgMembersNotifier, OrgMembersState>((ref) {
  final dio = ref.watch(dioProvider);
  return OrgMembersNotifier(dio);
});
