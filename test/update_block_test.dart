import 'package:flutter_test/flutter_test.dart';
import 'package:sahulat_ghar_tak/utils/update_block.dart';

class _FakeStore extends UpdateBlockStore {
  String? version;
  String? url;
  DateTime? clearedAt;
  DateTime? blockedAt;

  @override
  Future<DateTime?> readClearedAt() async => clearedAt;

  @override
  Future<void> writeClearedAt(DateTime at) async => clearedAt = at;

  @override
  Future<(String?, String?)> read() async => (version, url);

  @override
  Future<void> write(String v, String u, {DateTime? blockedAt}) async {
    version = v;
    url = u;
    if (blockedAt != null) this.blockedAt = blockedAt;
  }

  @override
  Future<DateTime?> readBlockedAt() async => blockedAt;

  @override
  Future<void> clear() async {
    version = null;
    url = null;
    blockedAt = null;
  }
}

Map<String, dynamic> _push(
        {String version = '1.0.5',
        String url = '',
        String? force,
        String? sentAt}) =>
    {
      'type': 'app_update',
      if (sentAt != null) 'sent_at': sentAt,
      'latest_version': version,
      'store_url': url,
      if (force != null) 'force_update': force,
    };

void main() {
  late _FakeStore store;
  String installed = '1.0.4';
  String? launched;
  var configCalls = 0;

  UpdateBlock make() => UpdateBlock(
        store: store,
        installedVersion: () async => installed,
        fetchStoreUrl: () async {
          configCalls++;
          return 'https://store/config';
        },
        launch: (url) async {
          launched = url;
          return true;
        },
      );

  setUp(() {
    store = _FakeStore();
    installed = '1.0.4';
    launched = null;
    configCalls = 0;
  });

  test('blocks an older install and persists the requirement', () async {
    final block = make();
    await block.record(_push(url: 'https://store/push'));
    expect(block.isBlocked, isTrue);
    expect(store.version, '1.0.5');
    expect(store.url, 'https://store/push');
  });

  test('does not block the same or a newer install', () async {
    final block = make();
    installed = '1.0.5';
    await block.record(_push());
    expect(block.isBlocked, isFalse);
    installed = '1.0.10';
    await block.record(_push(version: '1.0.9'));
    expect(block.isBlocked, isFalse);
  });

  test('a push for an already-installed version keeps a pending newer block',
      () async {
    final block = make();
    await block.record(_push(version: '1.0.7'));
    installed = '1.0.6';
    await block.record(_push(version: '1.0.5'));
    expect(block.isBlocked, isTrue);
    expect(store.version, '1.0.7');
  });

  test('ignores other types and pushes without a version', () async {
    final block = make();
    await block.record({'type': 'job_assigned', 'latest_version': '9.9.9'});
    await block.record({'type': 'app_update'});
    expect(block.isBlocked, isFalse);
  });

  test('load restores a pending block, and clears it once updated', () async {
    store.version = '1.0.5';
    store.url = 'https://store/push';
    final block = make();
    await block.load();
    expect(block.isBlocked, isTrue);

    installed = '1.0.5';
    final updated = make();
    await updated.load();
    expect(updated.isBlocked, isFalse);
    expect(store.version, isNull);
  });

  test('keeps the highest announced version', () async {
    final block = make();
    await block.record(_push(version: '1.0.7'));
    await block.record(_push(version: '1.0.6'));
    expect(block.requiredVersion, '1.0.7');
  });

  test('openStore uses the pushed url, else falls back to the config',
      () async {
    final withUrl = make();
    await withUrl.record(_push(url: 'https://store/push'));
    await withUrl.openStore();
    expect(launched, 'https://store/push');
    expect(configCalls, 0);

    store = _FakeStore();
    final noUrl = make();
    await noUrl.record(_push());
    await noUrl.openStore();
    expect(launched, 'https://store/config');
  });

  test('force_update "true" or missing blocks', () async {
    final a = make();
    await a.record(_push(force: 'true'));
    expect(a.isBlocked, isTrue);
    final b = make();
    await b.record(_push());
    expect(b.isBlocked, isTrue);
  });

  test('force_update "false" queues a prompt, no block, nothing persisted',
      () async {
    final block = make();
    await block.record(_push(force: 'false', url: 'https://store/push'),
        message: 'Fresh look');
    expect(block.isBlocked, isFalse);
    expect(store.version, isNull);
    expect(block.takePrompt(), isNull); // UI not ready yet
    block.setUiReady();
    final prompt = block.takePrompt();
    expect(prompt?.version, '1.0.5');
    expect(prompt?.message, 'Fresh look');
    expect(prompt?.storeUrl, 'https://store/push');
    expect(block.takePrompt(), isNull); // once
  });

  test('a prompt is not repeated for a version already prompted', () async {
    final block = make()..setUiReady();
    block.markPrompted('1.0.5');
    await block.record(_push(force: 'false'));
    expect(block.takePrompt(), isNull);
  });

  test('a non-forced push never replaces or weakens an existing block',
      () async {
    final block = make()..setUiReady();
    await block.record(_push(force: 'true'));
    await block.record(_push(version: '1.0.6', force: 'false'));
    expect(block.isBlocked, isTrue);
    expect(block.takePrompt(), isNull);
  });

  test('non-forced push for an installed version shows nothing', () async {
    final block = make()..setUiReady();
    installed = '1.0.5';
    await block.record(_push(force: 'false'));
    expect(block.takePrompt(), isNull);
  });

  test('background persist ignores a non-forced announcement', () async {
    await UpdateBlock.persistFromData(_push(force: 'false'), store: store);
    expect(store.version, isNull);
  });

  test('background persist stores a valid app_update only', () async {
    await UpdateBlock.persistFromData({'type': 'job_assigned'}, store: store);
    expect(store.version, isNull);
    await UpdateBlock.persistFromData(_push(), store: store);
    expect(store.version, '1.0.5');
  });

  group('release pull (last_unblock_at)', () {
    final blockedAt = DateTime.utc(2026, 10, 7, 8);

    Future<UpdateBlock> blocked() async {
      final block = make();
      await block.record(_push(sentAt: blockedAt.toIso8601String()));
      expect(block.isBlocked, isTrue);
      expect(store.blockedAt, blockedAt);
      return block;
    }

    test('a release after the block clears it and raises cleared-at', () async {
      final block = await blocked();
      final at = DateTime.utc(2026, 10, 7, 9);
      await block.pullRelease(() async => at);
      expect(block.isBlocked, isFalse);
      expect(store.version, isNull);
      expect(store.clearedAt, at);
    });

    test('a release before the block, null, or equal time changes nothing',
        () async {
      final block = await blocked();
      await block.pullRelease(() async => DateTime.utc(2026, 10, 7, 7));
      await block.pullRelease(() async => null);
      await block.pullRelease(() async => blockedAt);
      expect(block.isBlocked, isTrue);
    });

    test('a failing fetch leaves the block alone', () async {
      final block = await blocked();
      await block.pullRelease(() async => throw Exception('offline'));
      expect(block.isBlocked, isTrue);
    });

    test('a block from an older build (no created time) is not released',
        () async {
      store.version = '1.0.5';
      final block = make();
      await block.load();
      expect(block.isBlocked, isTrue);
      await block.pullRelease(() async => DateTime.utc(2030));
      expect(block.isBlocked, isTrue);
    });

    test('a block created after the release blocks again', () async {
      final block = await blocked();
      await block.pullRelease(() async => DateTime.utc(2026, 10, 7, 9));
      await block.record(_push(sentAt: '2026-10-07T10:00:00Z'));
      expect(block.isBlocked, isTrue);
    });

    test('an announcement sent before a pulled release is ignored', () async {
      final block = await blocked();
      await block.pullRelease(() async => DateTime.utc(2026, 10, 7, 9));
      await block.record(_push(sentAt: '2026-10-07T08:30:00Z'));
      expect(block.isBlocked, isFalse);
    });
  });

  group('admin release (app_unblock)', () {
    test('syncFromStore drops a block another isolate released', () async {
      final block = make();
      await block.record(_push());
      expect(block.isBlocked, isTrue);
      await store.clear(); // background handler cleared storage
      await block.syncFromStore();
      expect(block.isBlocked, isFalse);
    });

    const release = {'type': 'app_unblock', 'sent_at': '2026-10-06T08:00:00Z'};

    test('clears a stored block and records the release time', () async {
      final block = make();
      await block.record(_push(sentAt: '2026-10-06T07:00:00Z'));
      expect(block.isBlocked, isTrue);
      await block.record(release);
      expect(block.isBlocked, isFalse);
      expect(store.version, isNull);
      expect(store.clearedAt, DateTime.utc(2026, 10, 6, 8));
    });

    test('an announcement sent before the release is ignored', () async {
      final block = make();
      await block.record(release);
      await block.record(_push(sentAt: '2026-10-06T07:59:00Z'));
      expect(block.isBlocked, isFalse);
      expect(store.version, isNull);
    });

    test('an announcement sent after the release blocks again', () async {
      final block = make();
      await block.record(release);
      await block.record(_push(sentAt: '2026-10-06T08:01:00Z'));
      expect(block.isBlocked, isTrue);
    });

    test('a push without sent_at is never voided', () async {
      final block = make();
      await block.record(release);
      await block.record(_push());
      expect(block.isBlocked, isTrue);
    });

    test('release also drops a queued prompt', () async {
      final block = make()..setUiReady();
      await block.record(_push(force: 'false', sentAt: '2026-10-06T07:00:00Z'));
      await block.record(release);
      expect(block.takePrompt(), isNull);
    });

    test('background handler clears the block and records the release',
        () async {
      await UpdateBlock.persistFromData(_push(), store: store);
      expect(store.version, '1.0.5');
      await UpdateBlock.persistFromData(release, store: store);
      expect(store.version, isNull);
      await UpdateBlock.persistFromData(_push(sentAt: '2026-10-06T07:00:00Z'),
          store: store);
      expect(store.version, isNull);
    });

    test('an older release does not move the cleared time back', () async {
      final block = make();
      await block.record(release);
      await block
          .record({'type': 'app_unblock', 'sent_at': '2026-10-05T00:00:00Z'});
      expect(store.clearedAt, DateTime.utc(2026, 10, 6, 8));
    });
  });
}
