import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlucalendar/core/cache/cache_manager.dart';
import 'package:tlucalendar/core/cache/schedule_cache_manager.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course_hour.dart';
import 'package:tlucalendar/features/schedule/domain/entities/school_year.dart';
import 'package:tlucalendar/features/schedule/domain/entities/semester.dart';
import 'package:tlucalendar/features/schedule/domain/repositories/schedule_repository.dart';

// --- FakeClock (shared) ---

class FakeClock implements Clock {
  DateTime _now;
  FakeClock(this._now);
  @override
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

// --- Fakes ---

const _fakeCourse = Course(
  id: 1, courseCode: 'CS101', courseName: 'Intro to CS',
  dayOfWeek: 2, startCourseHour: 1, endCourseHour: 3,
  room: 'A101', credits: 3, startDate: 0, endDate: 9999999999999,
  fromWeek: 1, toWeek: 15, status: 'ACTIVE',
);

const _fakeCourseHour = CourseHour(
  id: 1, name: 'Tiết 1', startString: '07:00', endString: '07:50', indexNumber: 1,
);

const _fakeSemester = Semester(
  id: 1, semesterCode: 'HK1', semesterName: 'Học kỳ 1',
  startDate: 0, endDate: 9999999999999, isCurrent: true,
);

final _fakeSchoolYear = SchoolYear(
  id: 1, name: '2024-2025', code: '2024', year: 2024, current: true,
  startDate: 0, endDate: 9999999999999, displayName: '2024-2025',
  semesters: [_fakeSemester],
);

class FakeScheduleRepository implements ScheduleRepository {
  List<Course> courses;
  List<CourseHour> courseHours;
  List<SchoolYear> schoolYears;
  Object? getCoursesFailure;

  int getCoursesCallCount = 0;
  int getSchoolYearsCallCount = 0;
  int getCourseHoursCallCount = 0;

  FakeScheduleRepository({
    this.courses = const [_fakeCourse],
    this.courseHours = const [_fakeCourseHour],
    this.schoolYears = const [],
    this.getCoursesFailure,
  });

  @override
  Future<Either<Failure, List<Course>>> getCourses(int sem, String token) async {
    getCoursesCallCount++;
    if (getCoursesFailure != null) {
      if (getCoursesFailure is Failure) return Left(getCoursesFailure as Failure);
      throw getCoursesFailure!;
    }
    return Right(courses);
  }

  @override
  Future<Either<Failure, List<CourseHour>>> getCourseHours(String token) async {
    getCourseHoursCallCount++;
    return Right(courseHours);
  }

  @override
  Future<Either<Failure, List<SchoolYear>>> getSchoolYears(String token) async {
    getSchoolYearsCallCount++;
    return Right(schoolYears);
  }

  @override
  Future<Either<Failure, Semester>> getCurrentSemester(String token) async =>
      Right(_fakeSemester);

  @override
  Future<Either<Failure, List<Course>>> getCachedCourses(int sem) async =>
      Right(courses);

  @override
  Future<Either<Failure, List<SchoolYear>>> getCachedSchoolYears() async =>
      Right(schoolYears);

  @override
  Future<Either<Failure, List<CourseHour>>> getCachedCourseHours() async =>
      Right(courseHours);
}

void main() {
  late FakeClock clock;
  late CacheManager cache;
  late FakeScheduleRepository repository;
  late ScheduleCacheManager manager;

  setUp(() {
    clock = FakeClock(DateTime(2025, 1, 1, 12, 0, 0));
    cache = CacheManager(clock: clock);
    repository = FakeScheduleRepository(schoolYears: [_fakeSchoolYear]);
    manager = ScheduleCacheManager(repository, cache: cache);
  });

  tearDown(() => cache.dispose());

  test('getCourses cùng semester dùng cache lần hai', () async {
    final first = await manager.getCourses(1, 'token');
    final second = await manager.getCourses(1, 'token');

    expect(first.data, [_fakeCourse]);
    expect(first.isFromCache, isFalse);
    expect(second.isFromCache, isTrue);
    expect(repository.getCoursesCallCount, 1);
  });

  test('courses của hai semester không dùng nhầm cache', () async {
    await manager.getCourses(1, 'token');
    await manager.getCourses(2, 'token');
    expect(repository.getCoursesCallCount, 2);
  });

  test('repository failure ở cache miss được throw', () async {
    repository.getCoursesFailure = Exception('API down');
    expect(() => manager.getCourses(1, 'token'), throwsA(isA<Exception>()));
  });

  test('preload local đưa dữ liệu stale vào memory cache', () async {
    await manager.preloadFromLocal();

    expect(cache.hasCache('schedule:school_years'), isTrue);
    expect(cache.isStale('schedule:school_years'), isTrue);
    expect(cache.hasCache('schedule:course_hours'), isTrue);
    expect(cache.isStale('schedule:course_hours'), isTrue);
  });

  test('preloadCourses đưa courses stale vào memory cache', () async {
    await manager.preloadCourses(1);
    expect(cache.hasCache('schedule:courses:1'), isTrue);
    expect(cache.isStale('schedule:courses:1'), isTrue);
  });

  test('invalidateCourses chỉ xóa semester tương ứng', () async {
    await manager.getCourses(1, 'token');
    await manager.getCourses(2, 'token');

    manager.invalidateCourses(1);

    expect(cache.hasCache('schedule:courses:1'), isFalse);
    expect(cache.hasCache('schedule:courses:2'), isTrue);
  });

  test('invalidateAll không xóa cache ngoài schedule', () async {
    await manager.getCourses(1, 'token');

    await cache.getData<String>(
      key: 'grades:1',
      fetcher: () async => 'grade_data',
      freshTtl: Duration(hours: 1),
      staleTtl: Duration(hours: 6),
    );

    manager.invalidateAll();

    expect(cache.hasCache('schedule:courses:1'), isFalse);
    expect(cache.hasCache('grades:1'), isTrue);
  });

  test('setAccount cô lập cache giữa hai user', () async {
    cache.setAccount('A');
    await manager.getCourses(1, 'token');
    final rA = await manager.getCourses(1, 'token');
    expect(rA.isFromCache, isTrue);

    cache.setAccount('B');
    final rB = await manager.getCourses(1, 'token');
    expect(rB.isFromCache, isFalse);
    expect(repository.getCoursesCallCount, 2);
  });

  test('forceRefresh truyền xuống đúng', () async {
    await manager.getCourses(1, 'token');
    expect(repository.getCoursesCallCount, 1);

    final result = await manager.getCourses(1, 'token', forceRefresh: true);
    expect(result.isFromCache, isFalse);
    expect(repository.getCoursesCallCount, 2);
  });
}
