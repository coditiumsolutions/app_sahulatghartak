import 'dart:convert';

class AuthData {
  final int userId;
  final String username;
  final String mobileNo;
  final String role;
  final String token;
  final DateTime expiresAt;
  final int? categoryId;
  final String? categoryName;
  final int? providerUid;

  const AuthData({
    required this.userId,
    required this.username,
    required this.mobileNo,
    required this.role,
    required this.token,
    required this.expiresAt,
    this.categoryId,
    this.categoryName,
    this.providerUid,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String? ?? '';
    return AuthData(
      userId: json['userId'] as int,
      username: json['fullName'] as String? ?? '',
      mobileNo: json['mobileNo'] as String? ?? '',
      role: json['userType'] as String,
      token: token,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : (token.isNotEmpty ? _expiryFromToken(token) : DateTime.now().add(const Duration(days: 30))),
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      providerUid: json['profileId'] as int?,
    );
  }

  static DateTime _expiryFromToken(String token) {
    try {
      final payload = token.split('.')[1];
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      final exp = (jsonDecode(decoded) as Map<String, dynamic>)['exp'] as int;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return DateTime.now().add(const Duration(days: 1));
    }
  }

  AuthData copyWith({String? mobileNo, int? categoryId, String? categoryName, int? providerUid}) {
    return AuthData(
      userId: userId,
      username: username,
      mobileNo: mobileNo ?? this.mobileNo,
      role: role,
      token: token,
      expiresAt: expiresAt,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      providerUid: providerUid ?? this.providerUid,
    );
  }

  Map<String, String> toStorageMap() {
    return {
      'userId': userId.toString(),
      'username': username,
      'mobileNo': mobileNo,
      'role': role,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
      'categoryId': categoryId?.toString() ?? '',
      'categoryName': categoryName ?? '',
      'providerUid': providerUid?.toString() ?? '',
    };
  }

  factory AuthData.fromStorageMap(Map<String, String> map) {
    return AuthData(
      userId: int.parse(map['userId']!),
      username: map['username']!,
      mobileNo: map['mobileNo'] ?? '',
      role: map['role']!,
      token: map['token']!,
      expiresAt: DateTime.parse(map['expiresAt']!),
      categoryId: (map['categoryId']?.isNotEmpty ?? false) ? int.parse(map['categoryId']!) : null,
      categoryName: (map['categoryName']?.isNotEmpty ?? false) ? map['categoryName'] : null,
      providerUid: (map['providerUid']?.isNotEmpty ?? false) ? int.parse(map['providerUid']!) : null,
    );
  }
}
