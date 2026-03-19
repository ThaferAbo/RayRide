class AuthResponse {
  final String id;
  final String userName;
  final String email;
  final List<String> roles;
  final bool isVerified;
  final String jwToken;
  final String? refreshToken;

  AuthResponse({
    required this.id,
    required this.userName,
    required this.email,
    required this.roles,
    required this.isVerified,
    required this.jwToken,
    this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      id: json['id'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      isVerified: json['isVerified'] ?? false,
      jwToken: json['jwToken'] ?? json['token'] ?? '',
      refreshToken: json['refreshToken'],
    );
  }
}
