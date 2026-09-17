import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlucalendar/core/cache/cache_manager.dart';

/// Fake clock for deterministic tests
class FakeClock implements Clock {
  DateTime _now;
  FakeClock(this._now);

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
}

void main() {
  late FakeClock clock;
  late CacheManager cache;

  setUp(() {
    clock = FakeClock(DateTime(2025, 1, 1, 12, 0, 0));
    cache = CacheManager(clock: clock);
  });

  tearDown(() {
    cache.dispose();
  });

  // --- Core contract ---

  test('cache miss thì fetch và lưu dữ liệu', () async {
    final result = await cache.getData<String>(
      key: 'k',
      fetcher: () async => 'data',
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    expect(result.data, 'data');
    expect(result.isFromCache, isFalse);
    expect(result.isStale, isFalse);
    expect(cache.getCached<String>('k'), 'data');
  });

  test('cache fresh thì không gọi fetcher lần hai', () async {
    var fetchCount = 0;

    await cache.getData<String>(
      key: 'k',
      fetcher: () async { fetchCount++; return 'v'; },
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    final r = await cache.getData<String>(
      key: 'k',
      fetcher: () async { fetchCount++; return 'v2'; },
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    expect(r.data, 'v');
    expect(r.isFromCache, isTrue);
    expect(fetchCount, 1);
  });

  test('cache stale trả dữ liệu cũ ngay và refresh background', () async {
    final refreshStarted = Completer<void>();
    final releaseRefresh = Completer<void>();
    var fetchCount = 0;

    await cache.getData<String>(
      key: 'k',
      fetcher: () async => 'old',
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    // Make stale via helper (no Future.delayed)
    cache.markStale('k');

    final result = await cache.getData<String>(
      key: 'k',
      fetcher: () async {
        fetchCount++;
        refreshStarted.complete();
        await releaseRefresh.future;
        return 'new';
      },
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    expect(result.data, 'old');
    expect(result.isFromCache, isTrue);
    expect(result.isStale, isTrue);

    await refreshStarted.future;
    expect(fetchCount, 1);

    releaseRefresh.complete();
    await Future.delayed(Duration.zero); // let microtask settle

    expect(cache.getCached<String>('k'), 'new');
  });

  test('cache expired thì fetch blocking', () async {
    var fetchCount = 0;

    await cache.getData<String>(
      key: 'k',
      fetcher: () async => 'old',
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    cache.markExpired('k');

    final result = await cache.getData<String>(
      key: 'k',
      fetcher: () async { fetchCount++; return 'new'; },
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    expect(result.data, 'new');
    expect(result.isFromCache, isFalse);
    expect(fetchCount, 1);
  });

  test('force refresh bỏ qua cache', () async {
    var fetchCount = 0;

    await cache.getData<String>(
      key: 'k',
      fetcher: () async => 'old',
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    final result = await cache.getData<String>(
      key: 'k',
      fetcher: () async { fetchCount++; return 'new'; },
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
      forceRefresh: true,
    );

    expect(result.data, 'new');
    expect(result.isFromCache, isFalse);
    expect(fetchCount, 1);
  });

  test('fetch lỗi khi cache miss thì throw', () async {
    expect(
      () => cache.getData<String>(
        key: 'k',
        fetcher: () async => throw Exception('API down'),
        freshTtl: const Duration(hours: 1),
        staleTtl: const Duration(hours: 6),
      ),
      throwsA(isA<Exception>()),
    );

    expect(cache.hasCache('k'), isFalse);
  });

  test('refresh background lỗi vẫn giữ dữ liệu stale', () async {
    final refreshStarted = Completer<void>();

    await cache.getData<String>(
      key: 'k',
      fetcher: () async => 'old',
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    cache.markStale('k');

    final result = await cache.getData<String>(
      key: 'k',
      fetcher: () async {
        refreshStarted.complete();
        throw Exception('API down');
      },
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    expect(result.data, 'old');
    expect(result.isStale, isTrue);

    await refreshStarted.future;
    await Future.delayed(Duration.zero);

    expect(cache.getCached<String>('k'), 'old');
    expect(cache.lastRefreshError('k'), contains('API down'));
  });

  test('hai request đồng thời chỉ tạo một request API', () async {
    var fetchCount = 0;
    final fetchStarted = Completer<void>();
    final releaseFetch = Completer<void>();

    final f1 = cache.getData<String>(
      key: 'k',
      fetcher: () async {
        fetchCount++;
        fetchStarted.complete();
        await releaseFetch.future;
        return 'data';
      },
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    final f2 = cache.getData<String>(
      key: 'k',
      fetcher: () async { fetchCount++; return 'data2'; },
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    await fetchStarted.future;
    releaseFetch.complete();

    final results = await Future.wait([f1, f2]);

    expect(fetchCount, 1);
    expect(results[0].data, 'data');
    expect(results[1].data, 'data');
  });

  test('watchData phát current value trên listen rồi update sau refresh', () async {
    final releaseRefresh = Completer<void>();

    await cache.getData<String>(
      key: 'k',
      fetcher: () async => 'old',
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    cache.markStale('k');

    final values = <String>[];
    final sub = cache.watchData<String>('k').listen(values.add);

    // Trigger background refresh
    cache.getData<String>(
      key: 'k',
      fetcher: () async {
        await releaseRefresh.future;
        return 'new';
      },
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    // Let current value emit
    await Future.delayed(Duration.zero);
    expect(values, ['old']);

    releaseRefresh.complete();
    await Future.delayed(Duration.zero);
    expect(values, ['old', 'new']);

    await sub.cancel();
  });

  test('invalidatePattern chỉ xóa đúng namespace', () async {
    await cache.getData<String>(
      key: 'courses:1', fetcher: () async => 'a',
      freshTtl: Duration(hours: 1), staleTtl: Duration(hours: 6),
    );
    await cache.getData<String>(
      key: 'courses:2', fetcher: () async => 'b',
      freshTtl: Duration(hours: 1), staleTtl: Duration(hours: 6),
    );
    await cache.getData<String>(
      key: 'grades:1', fetcher: () async => 'c',
      freshTtl: Duration(hours: 1), staleTtl: Duration(hours: 6),
    );

    cache.invalidatePattern('courses:*');

    expect(cache.hasCache('courses:1'), isFalse);
    expect(cache.hasCache('courses:2'), isFalse);
    expect(cache.hasCache('grades:1'), isTrue);
  });

  test('invalidate xóa đúng một key', () async {
    await cache.getData<String>(
      key: 'a', fetcher: () async => '1',
      freshTtl: Duration(hours: 1), staleTtl: Duration(hours: 6),
    );
    await cache.getData<String>(
      key: 'b', fetcher: () async => '2',
      freshTtl: Duration(hours: 1), staleTtl: Duration(hours: 6),
    );

    cache.invalidate('a');

    expect(cache.hasCache('a'), isFalse);
    expect(cache.hasCache('b'), isTrue);
  });

  test('invalidateAll xóa toàn bộ', () async {
    await cache.getData<String>(
      key: 'a', fetcher: () async => '1',
      freshTtl: Duration(hours: 1), staleTtl: Duration(hours: 6),
    );
    await cache.getData<String>(
      key: 'b', fetcher: () async => '2',
      freshTtl: Duration(hours: 1), staleTtl: Duration(hours: 6),
    );

    cache.invalidateAll();

    expect(cache.hasCache('a'), isFalse);
    expect(cache.hasCache('b'), isFalse);
  });

  // --- Generation guard ---

  test('background refresh bị discard nếu invalidate gọi giữa chừng', () async {
    final releaseRefresh = Completer<void>();

    await cache.getData<String>(
      key: 'k',
      fetcher: () async => 'old',
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    cache.markStale('k');

    // Start background refresh (won't complete yet)
    cache.getData<String>(
      key: 'k',
      fetcher: () async {
        await releaseRefresh.future;
        return 'ghost';
      },
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    // Invalidate while refresh is in-flight
    cache.invalidate('k');

    // Now add fresh data via a new fetch
    await cache.getData<String>(
      key: 'k',
      fetcher: () async => 'fresh',
      freshTtl: const Duration(hours: 1),
      staleTtl: const Duration(hours: 6),
    );

    // Release the old background refresh
    releaseRefresh.complete();
    await Future.delayed(Duration.zero);

    // Ghost write should have been discarded
    expect(cache.getCached<String>('k'), 'fresh');
  });

  // --- Account scope ---

  test('setAccount cô lập cache giữa hai account', () async {
    cache.setAccount('userA');
    await cache.getData<String>(
      key: 'k',
      fetcher: () async => 'dataA',
      freshTtl: Duration(hours: 1),
      staleTtl: Duration(hours: 6),
    );

    cache.setAccount('userB');
    expect(cache.hasCache('k'), isFalse);

    final result = await cache.getData<String>(
      key: 'k',
      fetcher: () async => 'dataB',
      freshTtl: Duration(hours: 1),
      staleTtl: Duration(hours: 6),
    );

    expect(result.data, 'dataB');
    expect(result.isFromCache, isFalse);
  });

  test('preload đưa dữ liệu stale vào cache', () async {
    // freshTtl=1h, staleTtl=1d. fetchedAt=2h ago → stale (1h < 2h < 24h)
    cache.preload<List<int>>(
      key: 'k',
      data: [1, 2, 3],
      fetchedAt: clock.now().subtract(Duration(hours: 2)),
      freshTtl: Duration(hours: 1),
      staleTtl: Duration(days: 1),
    );

    expect(cache.hasCache('k'), isTrue);
    expect(cache.isStale('k'), isTrue);
    expect(cache.getCached<List<int>>('k'), [1, 2, 3]);
  });
}
