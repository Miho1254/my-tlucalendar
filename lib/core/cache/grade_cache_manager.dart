import 'package:flutter/foundation.dart';
import 'cache_manager.dart';
import '../../features/grades/domain/entities/student_mark.dart';
import '../../features/grades/domain/repositories/grade_repository.dart';

class GradeCacheManager {
  final GradeRepository _repository;
  final CacheManager _cache;

  static const Duration gradesFresh = Duration(hours: 1);
  static const Duration gradesStale = Duration(days: 2);

  static const String _gradesKey = 'grades:all';

  GradeCacheManager(this._repository, {CacheManager? cache})
      : _cache = cache ?? CacheManager.instance;

  Future<CacheResult<List<StudentMark>>> getGrades(
    String accessToken, {
    bool forceRefresh = false,
  }) {
    return _cache.getData(
      key: _gradesKey,
      fetcher: () async {
        final result = await _repository.getGrades(accessToken);
        return result.fold((f) => throw f, (g) => g);
      },
      freshTtl: gradesFresh,
      staleTtl: gradesStale,
      forceRefresh: forceRefresh,
    );
  }

  void invalidateAll() {
    _cache.invalidate(_gradesKey);
  }

  Future<void> preloadFromLocal() async {
    try {
      final result = await _repository.getCachedGrades();
      result.fold((_) {}, (grades) {
        if (grades.isNotEmpty) {
          _cache.preload<List<StudentMark>>(
            key: _gradesKey,
            data: grades,
            fetchedAt: _cache.clock.now()
                .subtract(gradesFresh)
                .subtract(const Duration(seconds: 1)),
            freshTtl: gradesFresh,
            staleTtl: gradesStale,
          );
        }
      });
    } catch (e) {
      debugPrint('[GradeCacheManager] Preload failed: $e');
    }
  }
}
