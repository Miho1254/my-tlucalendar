import 'package:flutter/foundation.dart';
import 'cache_manager.dart';
import '../../features/exam/domain/entities/exam_room.dart';
import '../../features/exam/domain/entities/exam_schedule.dart';
import '../../features/exam/domain/repositories/exam_repository.dart';

class ExamCacheManager {
  final ExamRepository _repository;
  final CacheManager _cache;

  static const Duration schedulesFresh = Duration(hours: 1);
  static const Duration schedulesStale = Duration(days: 2);
  static const Duration roomsFresh = Duration(hours: 1);
  static const Duration roomsStale = Duration(days: 2);

  ExamCacheManager(this._repository, {CacheManager? cache})
      : _cache = cache ?? CacheManager.instance;

  String _schedulesKey(int semesterId) => 'exam:schedules:$semesterId';
  String _roomsKey(int semesterId, int scheduleId, int round) =>
      'exam:rooms:$semesterId:$scheduleId:$round';

  Future<CacheResult<List<ExamSchedule>>> getExamSchedules(
    int semesterId,
    String accessToken,
    String? rawToken, {
    bool forceRefresh = false,
  }) {
    return _cache.getData(
      key: _schedulesKey(semesterId),
      fetcher: () async {
        final result = await _repository.getExamSchedules(
          semesterId, accessToken, rawToken,
        );
        return result.fold((f) => throw f, (s) => s);
      },
      freshTtl: schedulesFresh,
      staleTtl: schedulesStale,
      forceRefresh: forceRefresh,
    );
  }

  Future<CacheResult<List<ExamRoom>>> getExamRooms({
    required int semesterId,
    required int scheduleId,
    required int round,
    required String accessToken,
    String? rawToken,
    bool forceRefresh = false,
  }) {
    return _cache.getData(
      key: _roomsKey(semesterId, scheduleId, round),
      fetcher: () async {
        final result = await _repository.getExamRooms(
          semesterId: semesterId,
          scheduleId: scheduleId,
          round: round,
          accessToken: accessToken,
          rawToken: rawToken,
        );
        return result.fold((f) => throw f, (r) => r);
      },
      freshTtl: roomsFresh,
      staleTtl: roomsStale,
      forceRefresh: forceRefresh,
    );
  }

  void invalidateSemester(int semesterId) {
    _cache.invalidatePattern('exam:schedules:$semesterId');
    _cache.invalidatePattern('exam:rooms:$semesterId:*');
  }

  void invalidateAll() {
    _cache.invalidatePattern('exam:*');
  }

  Future<void> preloadSchedules(int semesterId) async {
    try {
      final result = await _repository.getCachedExamSchedules(semesterId);
      result.fold((_) {}, (schedules) {
        if (schedules.isNotEmpty) {
          _cache.preload<List<ExamSchedule>>(
            key: _schedulesKey(semesterId),
            data: schedules,
            fetchedAt: _cache.clock.now()
                .subtract(schedulesFresh)
                .subtract(const Duration(seconds: 1)),
            freshTtl: schedulesFresh,
            staleTtl: schedulesStale,
          );
        }
      });
    } catch (e) {
      debugPrint('[ExamCacheManager] Preload schedules failed: $e');
    }
  }

  Future<void> preloadRooms({
    required int semesterId,
    required int scheduleId,
    required int round,
  }) async {
    try {
      final result = await _repository.getCachedExamRooms(
        semesterId: semesterId,
        scheduleId: scheduleId,
        round: round,
      );
      result.fold((_) {}, (rooms) {
        if (rooms.isNotEmpty) {
          _cache.preload<List<ExamRoom>>(
            key: _roomsKey(semesterId, scheduleId, round),
            data: rooms,
            fetchedAt: _cache.clock.now()
                .subtract(roomsFresh)
                .subtract(const Duration(seconds: 1)),
            freshTtl: roomsFresh,
            staleTtl: roomsStale,
          );
        }
      });
    } catch (e) {
      debugPrint('[ExamCacheManager] Preload rooms failed: $e');
    }
  }
}
