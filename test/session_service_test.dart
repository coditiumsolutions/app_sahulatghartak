// Regression coverage for the "wrong contact details" investigation.
//
// Rules out one candidate explanation: that a previous account's session
// (username/mobileNo/profileId) could linger in secure storage and leak
// into a subsequent login on the same device. SessionService.saveSession()
// writes all fields unconditionally on every login and clearSession() wipes
// all fields on logout, so there should be zero bleed between accounts.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sahulat_ghar_tak/models/auth_data.dart';
import 'package:sahulat_ghar_tak/services/session_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = <String, String>{};

  setUp(() {
    store.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      final args = call.arguments as Map?;
      switch (call.method) {
        case 'write':
          store[args!['key'] as String] = args['value'] as String;
          return null;
        case 'read':
          return store[args!['key'] as String];
        case 'delete':
          store.remove(args!['key'] as String);
          return null;
        case 'deleteAll':
          store.clear();
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  AuthData account({required String username, required String mobileNo, required int providerUid}) {
    return AuthData(
      userId: providerUid,
      username: username,
      mobileNo: mobileNo,
      role: 'Customer',
      token: 'token-$username',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      providerUid: providerUid,
    );
  }

  test('logging in as a second account fully replaces the first, no field bleed', () async {
    final service = SessionService();

    await service.saveSession(account(username: 'ali', mobileNo: '03225040823', providerUid: 55));
    await service.saveSession(account(username: 'Coditium01', mobileNo: '03335191301', providerUid: 91));

    final restored = await service.getSession();

    expect(restored?.username, 'Coditium01');
    expect(restored?.mobileNo, '03335191301');
    expect(restored?.providerUid, 91);
    expect(restored?.username, isNot(equals('ali')));
    expect(restored?.mobileNo, isNot(equals('03225040823')));
  });

  test('clearSession (logout) removes every field so getSession returns null', () async {
    final service = SessionService();
    await service.saveSession(account(username: 'ali', mobileNo: '03225040823', providerUid: 55));

    await service.clearSession();

    expect(await service.getSession(), isNull);
  });
}
