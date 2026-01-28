/// User Data Model
class UserModel {
  final String userId;
  final String username;
  final String? email;
  final String fullName;
  final String phone;
  final String authMethod;
  final String status;
  final bool profileCompleted;
  final String? companyId;
  final String? companyName;
  final String? role;

  UserModel({
    required this.userId,
    required this.username,
    this.email,
    required this.fullName,
    required this.phone,
    required this.authMethod,
    required this.status,
    required this.profileCompleted,
    this.companyId,
    this.companyName,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      authMethod: json['auth_method'] as String? ?? 'email',
      status: json['status'] as String? ?? 'pending_verification',
      profileCompleted: json['profile_completed'] as bool? ?? false,
      companyId: json['company_id'] as String?,
      companyName: json['company_name'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'auth_method': authMethod,
      'status': status,
      'profile_completed': profileCompleted,
      'company_id': companyId,
      'company_name': companyName,
      'role': role,
    };
  }

  bool get isEmailVerified => authMethod == 'email' && status == 'active';
  bool get isSecurityQuestionsUser => authMethod == 'security_questions';
  bool get canLogin => status == 'active';
}
