import 'package:flutter_test/flutter_test.dart';
import 'package:sahulat_ghar_tak/models/app_config.dart';

void main() {
  test('last_unblock_at parses UTC, and null or garbage becomes null', () {
    expect(
        AppConfig.fromJson({'last_unblock_at': '2026-10-07T09:00:00.1234567Z'})
            .lastUnblockAt,
        DateTime.utc(2026, 10, 7, 9, 0, 0, 123, 456));
    expect(AppConfig.fromJson({'last_unblock_at': null}).lastUnblockAt, isNull);
    expect(AppConfig.fromJson({}).lastUnblockAt, isNull);
    expect(
        AppConfig.fromJson({'last_unblock_at': 'soon'}).lastUnblockAt, isNull);
  });
}
