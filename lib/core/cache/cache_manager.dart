import 'dart:async';
import 'package:flutter/foundation.dart';

/// Clock abstraction — injectable for testing
abstract class Clock {
  DateTime now();
}

/// Production clock using DateTime.now()
class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

/// Cache entry with explicit freshness boundaries
class CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;
  final DateTime freshUntil;
  final DateTime staleUntil;
  final int generation;

  CacheEntry({
    required this.data,
    required this.fetchedAt,
    required this.freshUntil,
    required this.staleUntil,
    this.generation = 0,
  });

  bool isFresh(DateTime now) => now.isBefore(freshUntil);
  bool isStale(DateTime now) =>
      !isFresh(now) && now.isBefore(staleUntil);
  bool isExpired(DateTime now) => !now.isBefore(staleUntil);
}

/// Cache result with metadata
class CacheResult<T> {
  final T data;
  final bool isFromCache;
  final bool isStale;

  CacheResult({
    required this.data,
    required this.isFromCache,
    required this.isStale,
  });
}

/// Refresh status for background operations
enum RefreshStatus { idle, inProgress, succeeded, failed }

/// Cache Manager — central "bao cấp" infrastructure
///
/// Guarantees:
/// 1. Request coalescing — concurrent callers for the same key share one fetch
/// 2. Generation guard — stale writes after invalidate are discarded
/// 3. Account scope — keys are prefixed with user identity
/// 4. Typed preload API — no raw map access
/// 5. Injectable clock — deterministic tests
class CacheManager {
  static CacheManager? _singleton;
  static CacheManager get instance => _singleton ??= CacheManager();

  final Clock _clock;

  /// In-memory cache store
  final Map<String, CacheEntry> _cache = {};

  /// Stream controllers per key — emit on cache update
  final Map<String, StreamController<CacheEntry>> _streams = {};

  /// In-flight fetch futures — request coalescing for ALL fetch types
  final Map<String, Future<CacheResult<dynamic>>> _inFlight = {};

  /// Generation counter per key — discard stale writes after invalidate
  final Map<String, int> _generation = {};

  /// Background refresh error state per key
  final Map<String, String?> _lastRefreshError = {};

  /// Current account scope prefix
  String _accountPrefix = '';

  CacheManager({Clock? clock}) : _clock = clock ?? const SystemClock();

  /// Reset singleton (for testing)
  static void resetSingleton() {
    _singleton?.dispose();
    _singleton = null;
  }

  // --- Account scope ---

  /// Set account scope — all keys become `{account}:{rawKey}`
  void setAccount(String accountId) {
    if (_accountPrefix == 'acct:$accountId:') return;
    // Account changed — wipe everything from previous account
    invalidateAll();
    _accountPrefix = 'acct:$accountId:';
  }

  /// Clear account scope
  void clearAccount() {
    _accountPrefix = '';
  }

  String _scopedKey(String key) => '$_accountPrefix$key';

  // --- Core API ---

  /// Get data with cache-first strategy.
  ///
  /// Request coalescing: if N callers request the same key simultaneously
  /// during a cache miss, only ONE fetch is made. All N callers receive
  /// the same result.
  Future<CacheResult<T>> getData<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration freshTtl = const Duration(hours: 1),
    Duration staleTtl = const Duration(hours: 6),
    bool forceRefresh = false,
  }) async {
    final scopedKey = _scopedKey(key);
    final now = _clock.now();
    final cached = _cache[scopedKey];

    // Case 0: Force refresh → coalesced fetch
    if (forceRefresh) {
      return _coalescedFetch<T>(scopedKey, fetcher, freshTtl, staleTtl);
    }

    // Case 1: Fresh cache → return immediately
    if (cached != null && cached.isFresh(now)) {
      return CacheResult(
        data: cached.data as T,
        isFromCache: true,
        isStale: false,
      );
    }

    // Case 2: Stale cache → return stale + background refresh
    if (cached != null && cached.isStale(now)) {
      _triggerBackgroundRefresh(scopedKey, fetcher, freshTtl, staleTtl);
      return CacheResult(
        data: cached.data as T,
        isFromCache: true,
        isStale: true,
      );
    }

    // Case 3: Miss or expired → coalesced fetch
    return _coalescedFetch<T>(scopedKey, fetcher, freshTtl, staleTtl);
  }

  /// Watch a key for cache updates.
  /// Emits the current cached value immediately (if exists), then future updates.
  Stream<T> watchData<T>(String key) {
    final scopedKey = _scopedKey(key);
    _streams.putIfAbsent(
      scopedKey,
      () => StreamController<CacheEntry>.broadcast(),
    );

    // Emit current value immediately if cached
    final current = _cache[scopedKey];
    final controller = _streams[scopedKey]!;

    // Use a transformed stream that starts with current value if available
    Stream<CacheEntry> stream;
    if (current != null) {
      stream = controller.stream;
      // Emit current on next microtask so listener has time to subscribe
      scheduleMicrotask(() {
        if (!controller.isClosed) {
          controller.add(current);
        }
      });
    } else {
      stream = controller.stream;
    }

    return stream.map((entry) => entry.data as T);
  }

  /// Preload data into cache from a local source (e.g., SQLite).
  /// Uses explicit parameters — no raw map access.
  void preload<T>({
    required String key,
    required T data,
    required DateTime fetchedAt,
    required Duration freshTtl,
    required Duration staleTtl,
  }) {
    final scopedKey = _scopedKey(key);
    final gen = (_generation[scopedKey] ?? 0);
    _cache[scopedKey] = CacheEntry<T>(
      data: data,
      fetchedAt: fetchedAt,
      freshUntil: fetchedAt.add(freshTtl),
      staleUntil: fetchedAt.add(staleTtl),
      generation: gen,
    );
  }

  /// Invalidate a single key
  void invalidate(String key) {
    final scopedKey = _scopedKey(key);
    _cache.remove(scopedKey);
    _generation[scopedKey] = (_generation[scopedKey] ?? 0) + 1;
    _inFlight.remove(scopedKey);
  }

  /// Invalidate all keys in current scope
  void invalidateAll() {
    // Increment generation for all cached keys
    for (final key in _cache.keys) {
      _generation[key] = (_generation[key] ?? 0) + 1;
    }
    _cache.clear();
    _inFlight.clear();
  }

  /// Invalidate keys matching a glob pattern (e.g., 'courses_*')
  void invalidatePattern(String pattern) {
    final regex = RegExp('^${pattern.replaceAll('*', '.*')}\$');
    final keysToRemove = _cache.keys.where((k) => regex.hasMatch(k)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _generation[key] = (_generation[key] ?? 0) + 1;
      _inFlight.remove(key);
    }
  }

  /// Get cached value without triggering fetch
  T? getCached<T>(String key) {
    return _cache[_scopedKey(key)]?.data as T?;
  }

  /// Check if cache has a non-expired entry
  bool hasCache(String key) {
    final entry = _cache[_scopedKey(key)];
    if (entry == null) return false;
    return !entry.isExpired(_clock.now());
  }

  /// Check if cache entry is stale
  bool isStale(String key) {
    final entry = _cache[_scopedKey(key)];
    if (entry == null) return true;
    return entry.isStale(_clock.now());
  }

  /// Last background refresh error for a key (null if succeeded or never tried)
  String? lastRefreshError(String key) {
    return _lastRefreshError[_scopedKey(key)];
  }

  /// Cleanup expired entries
  void cleanup() {
    final now = _clock.now();
    _cache.removeWhere((_, entry) => entry.isExpired(now));
  }

  /// Dispose all resources
  void dispose() {
    for (final controller in _streams.values) {
      controller.close();
    }
    _streams.clear();
    _cache.clear();
    _generation.clear();
    _inFlight.clear();
    _lastRefreshError.clear();
  }

  /// Expose clock for sub-managers (package-private usage)
  Clock get clock => _clock;

  // --- Private ---

  /// Coalesced fetch — multiple callers for the same key share one Future
  Future<CacheResult<T>> _coalescedFetch<T>(
    String scopedKey,
    Future<T> Function() fetcher,
    Duration freshTtl,
    Duration staleTtl,
  ) async {
    final existing = _inFlight[scopedKey];
    if (existing != null) {
      return existing as Future<CacheResult<T>>;
    }

    final future = _fetchAndCache<T>(scopedKey, fetcher, freshTtl, staleTtl);
    _inFlight[scopedKey] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(scopedKey);
    }
  }

  /// Background refresh — fire-and-forget, generation-guarded
  void _triggerBackgroundRefresh<T>(
    String scopedKey,
    Future<T> Function() fetcher,
    Duration freshTtl,
    Duration staleTtl,
  ) {
    // Don't start duplicate background refresh
    if (_inFlight.containsKey(scopedKey)) return;

    final gen = _generation[scopedKey] ?? 0;

    _inFlight[scopedKey] = Future(() async {
      try {
        final data = await fetcher();

        // Generation guard: if invalidate was called while we were fetching,
        // discard this write
        if ((_generation[scopedKey] ?? 0) != gen) {
          debugPrint('[CacheManager] Discarded stale write for $scopedKey '
              '(generation mismatch: $gen vs ${_generation[scopedKey]})');
          return CacheResult<T>(
            data: data,
            isFromCache: false,
            isStale: false,
          );
        }

        _writeCache<T>(scopedKey, data, freshTtl, staleTtl);
        _lastRefreshError[scopedKey] = null;
        return CacheResult<T>(
          data: data,
          isFromCache: false,
          isStale: false,
        );
      } catch (e) {
        _lastRefreshError[scopedKey] = e.toString();
        debugPrint('[CacheManager] Background refresh failed: $scopedKey - $e');
        // Return current stale data if available
        final cached = _cache[scopedKey];
        if (cached != null) {
          return CacheResult<T>(
            data: cached.data as T,
            isFromCache: true,
            isStale: true,
          );
        }
        rethrow;
      } finally {
        _inFlight.remove(scopedKey);
      }
    }) as Future<CacheResult<dynamic>>;
  }

  /// Fetch, write to cache, and return result
  Future<CacheResult<T>> _fetchAndCache<T>(
    String scopedKey,
    Future<T> Function() fetcher,
    Duration freshTtl,
    Duration staleTtl,
  ) async {
    final data = await fetcher();
    _writeCache<T>(scopedKey, data, freshTtl, staleTtl);
    _lastRefreshError[scopedKey] = null;
    return CacheResult(
      data: data,
      isFromCache: false,
      isStale: false,
    );
  }

  /// Write to cache and notify stream listeners
  void _writeCache<T>(
    String scopedKey,
    T data,
    Duration freshTtl,
    Duration staleTtl,
  ) {
    final now = _clock.now();
    _cache[scopedKey] = CacheEntry<T>(
      data: data,
      fetchedAt: now,
      freshUntil: now.add(freshTtl),
      staleUntil: now.add(staleTtl),
      generation: _generation[scopedKey] ?? 0,
    );
    _streams[scopedKey]?.add(_cache[scopedKey]!);
  }

  // --- Test helpers ---

  @visibleForTesting
  void markStale(String key) {
    final scopedKey = _scopedKey(key);
    final entry = _cache[scopedKey];
    if (entry == null) return;
    _cache[scopedKey] = CacheEntry(
      data: entry.data,
      fetchedAt: entry.fetchedAt,
      freshUntil: _clock.now().subtract(const Duration(seconds: 1)),
      staleUntil: entry.staleUntil,
      generation: entry.generation,
    );
  }

  @visibleForTesting
  void markExpired(String key) {
    final scopedKey = _scopedKey(key);
    final entry = _cache[scopedKey];
    if (entry == null) return;
    final past = _clock.now().subtract(const Duration(seconds: 1));
    _cache[scopedKey] = CacheEntry(
      data: entry.data,
      fetchedAt: entry.fetchedAt,
      freshUntil: past,
      staleUntil: past,
      generation: entry.generation,
    );
  }
}
