import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cache_manager.dart';
import '../../features/schedule/domain/entities/course.dart';
import '../../features/schedule/domain/entities/course_hour.dart';
import '../../features/schedule/domain/entities/school_year.dart';
import '../../features/schedule/domain/entities/semester.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';

/// Schedule Cache Manager — adapter between repository and CacheManager
///
/// Responsibilities:
/// - Translate repository calls into CacheManager API
/// - Define TTL policy for each data type
/// - Preload from local storage (SQLite) into memory cache
class ScheduleCacheManager {
  final ScheduleRepository _repository;
  final CacheManager _cache;

  // TTL policy: (freshTtl, staleTtl)
  // fresh: data is considered fresh, no background refresh
  // stale: data is usable but background refresh is triggered
  // expired (> staleTtl): data is discarded, blocking fetch
  static const Duration schoolYearsFresh = Duration(hours: 1);
  static const Duration schoolYearsStale = Duration(days: 2);

  static const Duration courseHoursFresh = Duration(hours: 1);
  static const Duration courseHoursStale = Duration(days: 2);

  static const Duration coursesFresh = Duration(hours: 1);
  static const Duration coursesStale = Duration(hours: 12);

  // Cache keys (raw — CacheManager applies account scope)
  static const String _schoolYearsKey = 'schedule:school_years';
  static const String _courseHoursKey = 'schedule:course_hours';
  static const String _coursesKeyPrefix = 'schedule:courses:';
  static const String _currentSemesterKey = 'schedule:current_semester';

  ScheduleCacheManager(
    this._repository, {
    CacheManager? cache,
  }) : _cache = cache ?? CacheManager.instance;

  // --- Public API ---

  Future<CacheResult<List<SchoolYear>>> getSchoolYears(
    String accessToken, {
    bool forceRefresh = false,
  }) {
    return _cache.getData(
      key: _schoolYearsKey,
      fetcher: () async {
        final result = await _repository.getSchoolYears(accessToken);
        return result.fold((f) => throw f, (years) => years);
      },
      freshTtl: schoolYearsFresh,
      staleTtl: schoolYearsStale,
      forceRefresh: forceRefresh,
    );
  }

  Future<CacheResult<List<CourseHour>>> getCourseHours(
    String accessToken, {
    bool forceRefresh = false,
  }) {
    return _cache.getData(
      key: _courseHoursKey,
      fetcher: () async {
        final result = await _repository.getCourseHours(accessToken);
        return result.fold((f) => throw f, (hours) => hours);
      },
      freshTtl: courseHoursFresh,
      staleTtl: courseHoursStale,
      forceRefresh: forceRefresh,
    );
  }

  Future<CacheResult<List<Course>>> getCourses(
    int semesterId,
    String accessToken, {
    bool forceRefresh = false,
  }) {
    return _cache.getData(
      key: '$_coursesKeyPrefix$semesterId',
      fetcher: () async {
        final result = await _repository.getCourses(semesterId, accessToken);
        return result.fold((f) => throw f, (courses) => courses);
      },
      freshTtl: coursesFresh,
      staleTtl: coursesStale,
      forceRefresh: forceRefresh,
    );
  }

  Future<CacheResult<Semester>> getCurrentSemester(
    String accessToken, {
    bool forceRefresh = false,
  }) {
    return _cache.getData(
      key: _currentSemesterKey,
      fetcher: () async {
        final result = await _repository.getCurrentSemester(accessToken);
        return result.fold((f) => throw f, (semester) => semester);
      },
      freshTtl: schoolYearsFresh,
      staleTtl: schoolYearsStale,
      forceRefresh: forceRefresh,
    );
  }

  Stream<List<Course>> watchCourses(int semesterId) {
    return _cache.watchData('$_coursesKeyPrefix$semesterId');
  }

  /// Invalidate all schedule cache
  void invalidateAll() {
    _cache.invalidatePattern('schedule:*');
  }

  /// Invalidate courses for a specific semester
  void invalidateCourses(int semesterId) {
    _cache.invalidate('$_coursesKeyPrefix$semesterId');
  }

  /// Preload school years + course hours from SQLite into memory cache.
  /// Data is marked as stale (fetchedAt = 2 days ago) so it will trigger
  /// background refresh on first getData call.
  Future<void> preloadFromLocal() async {
    try {
      final yearsResult = await _repository.getCachedSchoolYears();
      yearsResult.fold(
        (_) {},
        (years) {
          if (years.isNotEmpty) {
            // Mark as just-past-fresh so getData returns stale + triggers refresh
            _cache.preload<List<SchoolYear>>(
              key: _schoolYearsKey,
              data: years,
              fetchedAt: _cache.clock.now()
                  .subtract(schoolYearsFresh)
                  .subtract(const Duration(seconds: 1)),
              freshTtl: schoolYearsFresh,
              staleTtl: schoolYearsStale,
            );
          }
        },
      );
    } catch (e) {
      debugPrint('[ScheduleCacheManager] Preload schoolYears failed: $e');
    }

    try {
      final hoursResult = await _repository.getCachedCourseHours();
      hoursResult.fold(
        (_) {},
        (hours) {
          if (hours.isNotEmpty) {
            _cache.preload<List<CourseHour>>(
              key: _courseHoursKey,
              data: hours,
              fetchedAt: _cache.clock.now()
                  .subtract(courseHoursFresh)
                  .subtract(const Duration(seconds: 1)),
              freshTtl: courseHoursFresh,
              staleTtl: courseHoursStale,
            );
          }
        },
      );
    } catch (e) {
      debugPrint('[ScheduleCacheManager] Preload courseHours failed: $e');
    }
  }

  /// Preload courses for a specific semester from SQLite.
  Future<void> preloadCourses(int semesterId) async {
    try {
      final coursesResult = await _repository.getCachedCourses(semesterId);
      coursesResult.fold(
        (_) {},
        (courses) {
          if (courses.isNotEmpty) {
            _cache.preload<List<Course>>(
              key: '$_coursesKeyPrefix$semesterId',
              data: courses,
              fetchedAt: _cache.clock.now()
                  .subtract(coursesFresh)
                  .subtract(const Duration(seconds: 1)),
              freshTtl: coursesFresh,
              staleTtl: coursesStale,
            );
          }
        },
      );
    } catch (e) {
      debugPrint('[ScheduleCacheManager] Preload courses failed: $e');
    }
  }
}
