import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists request UIDs the customer has "deleted" from their device.
/// Deletion never touches the backend — the request stays in the database —
/// this store just remembers which UIDs to hide from this client's list.
class DeletedRequestsStore {
  final _storage = const FlutterSecureStorage();

  String _keyFor(int clientUid) => 'deletedRequests_$clientUid';

  Future<Set<int>> load(int clientUid) async {
    final raw = await _storage.read(key: _keyFor(clientUid));
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as int).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> hide(int clientUid, int requestUid) async {
    final existing = await load(clientUid);
    existing.add(requestUid);
    await _storage.write(key: _keyFor(clientUid), value: jsonEncode(existing.toList()));
  }
}
