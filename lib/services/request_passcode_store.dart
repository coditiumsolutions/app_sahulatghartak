import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists each request's completion passcode on-device once it's been
/// received from the API, so the customer can still view it (e.g. via
/// "Show Passcode") even without a live connection — the passcode itself
/// never changes once the booking is accepted.
class RequestPasscodeStore {
  final _storage = const FlutterSecureStorage();

  String _keyFor(int requestUid) => 'requestPasscode_$requestUid';

  Future<void> save(int requestUid, String passcode) async {
    await _storage.write(key: _keyFor(requestUid), value: passcode);
  }

  Future<String?> load(int requestUid) async {
    return _storage.read(key: _keyFor(requestUid));
  }
}
