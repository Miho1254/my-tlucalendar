import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_manager.dart';
import '../../features/education_program/domain/entities/education_program.dart';
import '../../features/education_program/domain/repositories/education_program_repository.dart';
import '../../features/education_program/data/models/education_program_model.dart';

class EducationProgramCacheManager {
  final EducationProgramRepository _repository;
  final CacheManager _cache;
  final SharedPreferences _prefs;

  static const Duration programFresh = Duration(hours: 1);
  static const Duration programStale = Duration(days: 30);

  static const String _programKey = 'education_program';
  static const String _prefsKey = 'cached_education_program';

  EducationProgramCacheManager(
    this._repository, {
    required SharedPreferences prefs,
    CacheManager? cache,
  })  : _prefs = prefs,
        _cache = cache ?? CacheManager.instance;

  Future<CacheResult<EducationProgram>> getProgram(
    String accessToken, {
    bool forceRefresh = false,
  }) async {
    return _cache.getData<EducationProgram>(
      key: _programKey,
      fetcher: () async {
        final result = await _repository.getEducationProgram(accessToken);
        return result.fold((f) => throw f, (program) {
          _saveToPrefs(program);
          return program;
        });
      },
      freshTtl: programFresh,
      staleTtl: programStale,
      forceRefresh: forceRefresh,
    );
  }

  void invalidateAll() {
    _cache.invalidate(_programKey);
  }

  Future<void> preloadFromLocal() async {
    try {
      final cachedString = _prefs.getString(_prefsKey);
      if (cachedString != null) {
        final program =
            EducationProgramModel.fromCacheJson(jsonDecode(cachedString));
        _cache.preload<EducationProgram>(
          key: _programKey,
          data: program,
          fetchedAt: _cache.clock.now()
              .subtract(programFresh)
              .subtract(const Duration(seconds: 1)),
          freshTtl: programFresh,
          staleTtl: programStale,
        );
      }
    } catch (e) {
      debugPrint('[EducationProgramCacheManager] Preload failed: $e');
    }
  }

  void _saveToPrefs(EducationProgram program) {
    try {
      if (program is EducationProgramModel) {
        _prefs.setString(_prefsKey, jsonEncode(program.toJson()));
      }
    } catch (_) {}
  }
}
