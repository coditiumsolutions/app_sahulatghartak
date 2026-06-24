class AuthData {
  final int userId;
  final String username;
  final String role;
  final String token;
  final DateTime expiresAt;
  final int? categoryId;
  final String? categoryName;

  const AuthData({
    required this.userId,
    required this.username,
    required this.role,
    required this.token,
    required this.expiresAt,
    this.categoryId,
    this.categoryName,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      userId: json['userId'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
    );
  }

  AuthData copyWith({int? categoryId, String? categoryName}) {
    return AuthData(
      userId: userId,
      username: username,
      role: role,
      token: token,
      expiresAt: expiresAt,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  Map<String, String> toStorageMap() {
    return {
      'userId': userId.toString(),
      'username': username,
      'role': role,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
      'categoryId': categoryId?.toString() ?? '',
      'categoryName': categoryName ?? '',
    };
  }

  factory AuthData.fromStorageMap(Map<String, String> map) {
    return AuthData(
      userId: int.parse(map['userId']!),
      username: map['username']!,
      role: map['role']!,
      token: map['token']!,
      expiresAt: DateTime.parse(map['expiresAt']!),
      categoryId: (map['categoryId']?.isNotEmpty ?? false) ? int.parse(map['categoryId']!) : null,
      categoryName: (map['categoryName']?.isNotEmpty ?? false) ? map['categoryName'] : null,
    );
  }
}
