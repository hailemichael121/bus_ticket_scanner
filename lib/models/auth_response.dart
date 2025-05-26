class AuthResponse {
  final bool success;
  final String message;
  final String status;
  final String token;
  final User user;

  AuthResponse({
    required this.success,
    required this.message,
    required this.status,
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'],
      message: json['message'],
      status: json['status'],
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }
}

class User {
  final String operatorId;
  final String name;
  final String email;
  final String tenantId;
  final String role;

  User({
    required this.operatorId,
    required this.name,
    required this.email,
    required this.tenantId,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      operatorId: json['operatorId'],
      name: json['name'],
      email: json['email'],
      tenantId: json['tenantId'],
      role: json['role'],
    );
  }
}
