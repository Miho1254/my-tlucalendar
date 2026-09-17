import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_manager.dart';
import '../../features/tuition/domain/entities/tuition_fee.dart';
import '../../features/tuition/domain/repositories/tuition_repository.dart';
import '../../features/tuition/data/models/tuition_fee_model.dart';

class TuitionCacheManager {
  final TuitionRepository _repository;
  final CacheManager _cache;
  final SharedPreferences _prefs;

  static const Duration tuitionFresh = Duration(hours: 1);
  static const Duration tuitionStale = Duration(days: 7);

  static const String _tuitionKey = 'tuition:fee';
  static const String _prefsKey = 'cached_tuition_fee_v2';

  TuitionCacheManager(
    this._repository, {
    required SharedPreferences prefs,
    CacheManager? cache,
  })  : _prefs = prefs,
        _cache = cache ?? CacheManager.instance;

  Future<CacheResult<TuitionFee>> getTuitionFee(
    String accessToken, {
    bool forceRefresh = false,
  }) async {
    final result = await _cache.getData<TuitionFee>(
      key: _tuitionKey,
      fetcher: () async {
        final result = await _repository.getTuitionFee(accessToken);
        return result.fold((f) => throw f, (fee) {
          _saveToPrefs(fee);
          return fee;
        });
      },
      freshTtl: tuitionFresh,
      staleTtl: tuitionStale,
      forceRefresh: forceRefresh,
    );
    return result;
  }

  void invalidateAll() {
    _cache.invalidate(_tuitionKey);
  }

  Future<void> preloadFromLocal() async {
    try {
      final cachedString = _prefs.getString(_prefsKey);
      if (cachedString != null) {
        final fee = TuitionFeeModel.fromCacheJson(jsonDecode(cachedString));
        _cache.preload<TuitionFee>(
          key: _tuitionKey,
          data: fee,
          fetchedAt: _cache.clock.now()
              .subtract(tuitionFresh)
              .subtract(const Duration(seconds: 1)),
          freshTtl: tuitionFresh,
          staleTtl: tuitionStale,
        );
      }
    } catch (e) {
      debugPrint('[TuitionCacheManager] Preload failed: $e');
    }
  }

  void _saveToPrefs(TuitionFee fee) {
    try {
      if (fee is TuitionFeeModel) {
        _prefs.setString(_prefsKey, jsonEncode(fee.toJson()));
      }
    } catch (_) {}
  }
}
