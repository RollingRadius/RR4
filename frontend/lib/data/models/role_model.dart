/// Role Model
class RoleModel {
  final String id;
  final String roleName;
  final String roleKey;
  final String? description;
  final bool isSystemRole;
  final bool isCustomRole;

  RoleModel({
    required this.id,
    required this.roleName,
    required this.roleKey,
    this.description,
    required this.isSystemRole,
    this.isCustomRole = false,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as String,
      roleName: json['role_name'] as String,
      roleKey: json['role_key'] as String,
      description: json['description'] as String?,
      isSystemRole: json['is_system_role'] as bool,
      isCustomRole: json['is_custom_role'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_name': roleName,
      'role_key': roleKey,
      'description': description,
      'is_system_role': isSystemRole,
      'is_custom_role': isCustomRole,
    };
  }
}

/// Pending Role Request Model
class PendingRoleRequest {
  final String userOrganizationId;
  final String userId;
  final String userName;
  final String username;
  final String? email;
  final String? phone;
  final String joinedAt;
  final RoleInfo currentRole;
  final RoleInfo? requestedRole;

  PendingRoleRequest({
    required this.userOrganizationId,
    required this.userId,
    required this.userName,
    required this.username,
    this.email,
    this.phone,
    required this.joinedAt,
    required this.currentRole,
    this.requestedRole,
  });

  factory PendingRoleRequest.fromJson(Map<String, dynamic> json) {
    return PendingRoleRequest(
      userOrganizationId: json['user_organization_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      joinedAt: json['joined_at'] as String,
      currentRole: RoleInfo.fromJson(json['current_role'] as Map<String, dynamic>),
      requestedRole: json['requested_role'] != null
          ? RoleInfo.fromJson(json['requested_role'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Role Info (simplified for nested objects)
class RoleInfo {
  final String id;
  final String name;
  final String key;
  final String? description;

  RoleInfo({
    required this.id,
    required this.name,
    required this.key,
    this.description,
  });

  factory RoleInfo.fromJson(Map<String, dynamic> json) {
    return RoleInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      key: json['key'] as String,
      description: json['description'] as String?,
    );
  }
}
