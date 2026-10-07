import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repositories/notification_repository.dart';
import 'version_compare.dart';

/// Data keys the `app_update` push carries (all strings, see `api.txt`):
/// `latest_version` (required, e.g. "1.0.5") and `store_url` (optional).
const _typeKey = 'type';
const _versionKey = 'latest_version';
const _storeUrlKey = 'store_url';
const _forceKey = 'force_update';
const _sentAtKey = 'sent_at';

/// Silent admin push that voids every block created at or before its
/// `sent_at` (see `api.txt`, "Admin release of update blocks").
const _unblockType = 'app_unblock';

class _Announcement {
  const _Announcement(this.version, this.storeUrl, {required this.force});
  final String version;
  final String storeUrl;
  final bool force;
}

/// A non-forced update announcement waiting to be shown as a dialog.
class UpdatePrompt {
  const UpdatePrompt(this.version, this.storeUrl, this.message);
  final String version;
  final String storeUrl;
  final String? message;
}

/// Persists the pending update so the block survives an app restart, and so
/// the background push handler (a separate isolate) can record it too.
class UpdateBlockStore {
  const UpdateBlockStore();
  static const _storage = FlutterSecureStorage();
  static const _versionStorageKey = 'pending_update_version';
  static const _urlStorageKey = 'pending_update_store_url';
  static const _clearedStorageKey = 'update_block_cleared_at';
  static const _blockedAtStorageKey = 'pending_update_blocked_at';

  Future<(String?, String?)> read() async => (
        await _storage.read(key: _versionStorageKey),
        await _storage.read(key: _urlStorageKey),
      );

  /// [blockedAt] is when the block was created (server `sent_at`, else the
  /// receive time). Omit it to keep the stored value, e.g. when only the
  /// store url changes. Blocks written by older builds have none.
  Future<void> write(String version, String storeUrl,
      {DateTime? blockedAt}) async {
    await _storage.write(key: _versionStorageKey, value: version);
    await _storage.write(key: _urlStorageKey, value: storeUrl);
    if (blockedAt != null) {
      await _storage.write(
          key: _blockedAtStorageKey,
          value: blockedAt.toUtc().toIso8601String());
    }
  }

  Future<DateTime?> readBlockedAt() async =>
      DateTime.tryParse(await _storage.read(key: _blockedAtStorageKey) ?? '');

  Future<void> clear() async {
    await _storage.delete(key: _versionStorageKey);
    await _storage.delete(key: _urlStorageKey);
    await _storage.delete(key: _blockedAtStorageKey);
  }

  /// Latest admin release seen (server `sent_at`). Announcements sent at or
  /// before it are ignored, so one still in flight cannot re-block.
  Future<DateTime?> readClearedAt() async =>
      DateTime.tryParse(await _storage.read(key: _clearedStorageKey) ?? '');

  Future<void> writeClearedAt(DateTime at) => _storage.write(
      key: _clearedStorageKey, value: at.toUtc().toIso8601String());
}

/// Blocks the whole app while the installed version is older than the version
/// announced by an `app_update` push. The comparison happens on the device
/// against the version embedded in the push, so no network call is needed.
class UpdateBlock extends ChangeNotifier {
  UpdateBlock({
    UpdateBlockStore store = const UpdateBlockStore(),
    Future<String> Function()? installedVersion,
    Future<String> Function()? fetchStoreUrl,
    Future<bool> Function(String url)? launch,
  })  : _store = store,
        _installedVersion = installedVersion ?? _packageVersion,
        _fetchStoreUrl = fetchStoreUrl ?? _configStoreUrl,
        _launch = launch ?? _launchExternal;

  final UpdateBlockStore _store;
  final Future<String> Function() _installedVersion;
  final Future<String> Function() _fetchStoreUrl;
  final Future<bool> Function(String url) _launch;

  String? _requiredVersion;
  String _storeUrl = '';
  DateTime? _blockedAt;
  Future<void>? _loading;

  bool get isBlocked => _requiredVersion != null;
  String? get requiredVersion => _requiredVersion;
  String get storeUrl => _storeUrl;

  /// Restores a pending update from storage. Clears it if the app has since
  /// been updated. Never throws.
  Future<void> load() => _loading = _load();

  Future<void> _load() async {
    try {
      final (version, url) = await _store.read();
      if (version == null || version.isEmpty) return;
      await _apply(version, url ?? '', blockedAt: await _store.readBlockedAt());
    } catch (e) {
      debugPrint('Update block load failed: $e');
    }
  }

  /// Pulls the latest admin release time (`last_unblock_at` from app config)
  /// and releases the block if it is older. The silent push is best effort on
  /// iOS, so this runs on launch and resume. [fetch] returns null when there
  /// is nothing to apply. Fails open: any error changes nothing. A block
  /// stored by an older build has no creation time and is never released
  /// from here.
  Future<void> pullRelease(Future<DateTime?> Function() fetch) async {
    try {
      await _loading;
      if (!isBlocked) return;
      final releasedAt = await fetch();
      if (releasedAt == null) return;
      final blockedAt = _blockedAt;
      if (blockedAt == null || !releasedAt.toUtc().isAfter(blockedAt)) return;
      debugPrint('Update block: release pulled from app config, releasing');
      await _release({'sent_at': releasedAt.toUtc().toIso8601String()});
    } catch (e) {
      debugPrint('Update block pull failed: $e');
    }
  }

  /// Re-reads storage on resume. The background push handler runs in its own
  /// isolate and can release (or set) a block while this isolate keeps its
  /// old in-memory state, so a release delivered in the background would
  /// otherwise leave the block showing until the next cold start.
  Future<void> syncFromStore() async {
    try {
      final (version, url) = await _store.read();
      if (version == null || version.isEmpty) {
        if (_requiredVersion != null) {
          _requiredVersion = null;
          _blockedAt = null;
          notifyListeners();
        }
        return;
      }
      await _apply(version, url ?? '', blockedAt: await _store.readBlockedAt());
    } catch (e) {
      debugPrint('Update block sync failed: $e');
    }
  }

  /// Call with every push (foreground, tap, cold start); [message] is the
  /// notification body. Ignores anything that is not an `app_update` carrying
  /// a version. `force_update` "false" queues a dismissable prompt instead of
  /// a block (see [takePrompt]); "true" or a missing key blocks.
  Future<void> record(Map<String, dynamic> data, {String? message}) async {
    try {
      if (data[_typeKey]?.toString() == _unblockType) {
        debugPrint('Update block: app_unblock received, releasing');
        await _release(data);
        return;
      }
      final parsed = _parse(data);
      if (parsed == null) return;
      if (await _voided(data, _store)) return;
      // A push for a version we already have must not clear a still-valid
      // pending block for a newer one; only load() clears stale state.
      if (compareVersions(await _installedVersion(), parsed.version) >= 0) {
        return;
      }
      if (parsed.force) {
        await _apply(parsed.version, parsed.storeUrl, blockedAt: _sentAt(data));
      } else if (!isBlocked) {
        _pendingPrompt = UpdatePrompt(parsed.version, parsed.storeUrl, message);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update block record failed: $e');
    }
  }

  /// For the background handler: only persist, the app compares on next start.
  /// A non-forced announcement is not persisted (it is only a prompt).
  static Future<void> persistFromData(Map<String, dynamic> data,
      {UpdateBlockStore store = const UpdateBlockStore()}) async {
    try {
      if (data[_typeKey]?.toString() == _unblockType) {
        debugPrint('Update block: app_unblock received in background');
        await _storeRelease(data, store);
        return;
      }
      final parsed = _parse(data);
      if (parsed != null && parsed.force && !await _voided(data, store)) {
        await store.write(parsed.version, parsed.storeUrl,
            blockedAt: _sentAt(data));
      }
    } catch (e) {
      debugPrint('Update block persist failed: $e');
    }
  }

  static DateTime _sentAt(Map<String, dynamic> data) =>
      DateTime.tryParse((data[_sentAtKey] ?? '').toString())?.toUtc() ??
      DateTime.now().toUtc();

  /// True when an admin release at or after this push's `sent_at` already
  /// voided it. A push with no usable `sent_at` is never voided.
  static Future<bool> _voided(
      Map<String, dynamic> data, UpdateBlockStore store) async {
    final sent = DateTime.tryParse((data[_sentAtKey] ?? '').toString());
    if (sent == null) return false;
    final cleared = await store.readClearedAt();
    return cleared != null && !sent.toUtc().isAfter(cleared);
  }

  static Future<void> _storeRelease(
      Map<String, dynamic> data, UpdateBlockStore store) async {
    final at = _sentAt(data);
    final cleared = await store.readClearedAt();
    if (cleared == null || at.isAfter(cleared)) await store.writeClearedAt(at);
    await store.clear();
  }

  /// Admin release: forget the block and any queued prompt, show nothing.
  Future<void> _release(Map<String, dynamic> data) async {
    await _storeRelease(data, _store);
    _pendingPrompt = null;
    if (_requiredVersion != null) {
      _requiredVersion = null;
      _blockedAt = null;
      notifyListeners();
    }
  }

  static _Announcement? _parse(Map<String, dynamic> data) {
    if (data[_typeKey]?.toString() != 'app_update') return null;
    final version = (data[_versionKey] ?? '').toString().trim();
    if (version.isEmpty) return null;
    return _Announcement(
      version,
      (data[_storeUrlKey] ?? '').toString().trim(),
      // Anything but an explicit "false" blocks, matching older behaviour.
      force: (data[_forceKey] ?? '').toString().trim().toLowerCase() != 'false',
    );
  }

  UpdatePrompt? _pendingPrompt;
  String? _promptedVersion;
  bool _uiReady = false;

  /// The first real screen is up, so a dialog can be shown safely (a dialog
  /// over the splash would be swallowed by its `pushReplacement`).
  void setUiReady() {
    _uiReady = true;
    notifyListeners();
  }

  /// Records that the prompt for [version] was already shown (e.g. by the
  /// splash config check) so the push does not show it a second time.
  void markPrompted(String version) => _promptedVersion = version;

  /// The queued non-forced prompt, once, when the UI can show it.
  UpdatePrompt? takePrompt() {
    final prompt = _pendingPrompt;
    if (!_uiReady || prompt == null || isBlocked) return null;
    _pendingPrompt = null;
    if (_promptedVersion == prompt.version) return null;
    _promptedVersion = prompt.version;
    return prompt;
  }

  Future<void> _apply(String version, String url, {DateTime? blockedAt}) async {
    final installed = await _installedVersion();
    if (compareVersions(installed, version) >= 0) {
      // Already on this version or newer: nothing to block, drop stale state.
      await _store.clear();
      if (_requiredVersion != null) {
        _requiredVersion = null;
        _blockedAt = null;
        notifyListeners();
      }
      return;
    }
    // Keep the highest version if two announcements arrive.
    final current = _requiredVersion;
    if (current != null && compareVersions(current, version) > 0) return;
    _requiredVersion = version;
    _blockedAt = blockedAt;
    _storeUrl = url.isNotEmpty ? url : _storeUrl;
    await _store.write(version, _storeUrl, blockedAt: blockedAt);
    notifyListeners();
  }

  /// Opens the store listing: the URL from the push, else the server config.
  Future<void> openStore() async {
    try {
      var url = _storeUrl;
      if (url.isEmpty) {
        url = await _fetchStoreUrl();
        if (url.isNotEmpty) {
          _storeUrl = url;
          await _store.write(_requiredVersion ?? '', url);
        }
      }
      if (url.isNotEmpty) await _launch(url);
    } catch (e) {
      debugPrint('Open store failed: $e');
    }
  }

  static Future<String> _packageVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  static Future<String> _configStoreUrl() async {
    final config = await NotificationRepository().fetchAppConfig(
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
    return config.storeUrl;
  }

  static Future<bool> _launchExternal(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

final updateBlock = UpdateBlock();
