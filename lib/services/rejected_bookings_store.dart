import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/provider/service_booking.dart';

/// Persists rejected bookings on-device, per provider. The backend's
/// GET /service-bookings never returns "Rejected" status bookings (staff-only
/// per the API contract), so without this they'd only exist in memory for the
/// current session and vanish on app restart.
class RejectedBookingsStore {
  final _storage = const FlutterSecureStorage();

  String _keyFor(int providerUid) => 'rejectedBookings_$providerUid';
  String _seenCountKeyFor(int providerUid) => 'rejectedBookingsSeenCount_$providerUid';

  Future<List<ServiceBooking>> load(int providerUid) async {
    final raw = await _storage.read(key: _keyFor(providerUid));
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => ServiceBooking.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(int providerUid, ServiceBooking booking) async {
    final existing = await load(providerUid);
    final updated = [...existing.where((b) => b.uid != booking.uid), booking];
    await _storage.write(key: _keyFor(providerUid), value: jsonEncode(updated.map((b) => b.toJson()).toList()));
  }

  /// Number of rejected bookings that existed the last time the provider
  /// opened the Rejected Requests screen — used to only badge newly-rejected
  /// bookings added since then.
  Future<int> loadSeenCount(int providerUid) async {
    final raw = await _storage.read(key: _seenCountKeyFor(providerUid));
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> saveSeenCount(int providerUid, int count) async {
    await _storage.write(key: _seenCountKeyFor(providerUid), value: '$count');
  }
}
