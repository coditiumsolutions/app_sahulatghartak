import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_data.dart';

class SessionService {
  final _storage = const FlutterSecureStorage();

  static const _keys = ['userId', 'username', 'role', 'token', 'expiresAt'];

  Future<void> saveSession(AuthData authData) async {
    final map = authData.toStorageMap();
    for (final key in _keys) {
      await _storage.write(key: key, value: map[key]);
    }
  }

  Future<AuthData?> getSession() async {
    final map = <String, String>{};
    for (final key in _keys) {
      final value = await _storage.read(key: key);
      if (value == null) return null;
      map[key] = value;
    }

    final authData = AuthData.fromStorageMap(map);
    if (authData.expiresAt.isBefore(DateTime.now())) {
      await clearSession();
      return null;
    }
    return authData;
  }

  Future<void> clearSession() async {
    for (final key in _keys) {
      await _storage.delete(key: key);
    }
  }
}
