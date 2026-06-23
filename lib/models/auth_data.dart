class AuthData {
  final int userId;
  final String username;
  final String role;
  final String token;
  final DateTime expiresAt;

  const AuthData({
    required this.userId,
    required this.username,
    required this.role,
    required this.token,
    required this.expiresAt,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      userId: json['userId'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, String> toStorageMap() {
    return {
      'userId': userId.toString(),
      'username': username,
      'role': role,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory AuthData.fromStorageMap(Map<String, String> map) {
    return AuthData(
      userId: int.parse(map['userId']!),
      username: map['username']!,
      role: map['role']!,
      token: map['token']!,
      expiresAt: DateTime.parse(map['expiresAt']!),
    );
  }
}
