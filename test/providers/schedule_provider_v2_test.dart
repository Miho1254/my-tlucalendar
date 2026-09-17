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
import 'package:tlucalendar/providers/schedule_provider.dart';
import 'package:tlucalendar/widgets/update_banner.dart';

// --- FakeClock ---

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

const _fakeSemester2 = Semester(
  id: 2, semesterCode: 'HK2', semesterName: 'Học kỳ 2',
  startDate: 1000000000000, endDate: 2000000000000, isCurrent: false,
);

final _fakeSchoolYear = SchoolYear(
  id: 1, name: '2024-2025', code: '2024', year: 2024, current: true,
  startDate: 0, endDate: 9999999999999, displayName: '2024-2025',
  semesters: [_fakeSemester, _fakeSemester2],
);

class FakeScheduleRepository implements ScheduleRepository {
  List<Course> courses;
  List<CourseHour> courseHours;
  List<SchoolYear> schoolYears;
  Object? failure;

  int getCoursesCallCount = 0;
  int getSchoolYearsCallCount = 0;

  /// Whether cached methods return data
  bool hasCachedData;

  FakeScheduleRepository({
    this.courses = const [_fakeCourse],
    this.courseHours = const [_fakeCourseHour],
    List<SchoolYear>? schoolYears,
    this.failure,
    this.hasCachedData = false,
  }) : schoolYears = schoolYears ?? [_fakeSchoolYear];

  @override
  Future<Either<Failure, List<Course>>> getCourses(int sem, String token) async {
    getCoursesCallCount++;
    if (failure != null) {
      if (failure is Failure) return Left(failure as Failure);
      throw failure!;
    }
    return Right(courses);
  }

  @override
  Future<Either<Failure, List<CourseHour>>> getCourseHours(String token) async {
    if (failure != null) {
      if (failure is Failure) return Left(failure as Failure);
      throw failure!;
    }
    return Right(courseHours);
  }

  @override
  Future<Either<Failure, List<SchoolYear>>> getSchoolYears(String token) async {
    getSchoolYearsCallCount++;
    if (failure != null) {
      if (failure is Failure) return Left(failure as Failure);
      throw failure!;
    }
    return Right(schoolYears);
  }

  @override
  Future<Either<Failure, Semester>> getCurrentSemester(String token) async =>
      Right(_fakeSemester);

  @override
  Future<Either<Failure, List<Course>>> getCachedCourses(int sem) async =>
      hasCachedData ? Right(courses) : Right([]);

  @override
  Future<Either<Failure, List<SchoolYear>>> getCachedSchoolYears() async =>
      hasCachedData ? Right(schoolYears) : Right([]);

  @override
  Future<Either<Failure, List<CourseHour>>> getCachedCourseHours() async =>
      hasCachedData ? Right(courseHours) : Right([]);
}

void main() {
  late FakeClock clock;
  late CacheManager cache;
  late FakeScheduleRepository repository;
  late ScheduleCacheManager cacheManager;
  late ScheduleProvider provider;

  setUp(() {
    clock = FakeClock(DateTime(2025, 1, 1, 12, 0, 0));
    cache = CacheManager(clock: clock);
    repository = FakeScheduleRepository();
    cacheManager = ScheduleCacheManager(repository, cache: cache);
    provider = ScheduleProvider(cacheManager: cacheManager);
  });

  tearDown(() => cache.dispose());

  test('init load school years, course hours và courses', () async {
    await provider.init('token');

    expect(provider.schoolYears, [_fakeSchoolYear]);
    expect(provider.courseHours, [_fakeCourseHour]);
    expect(provider.courses, [_fakeCourse]);
    expect(provider.currentSemester, _fakeSemester);
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('dữ liệu stale bật offline mode và tạo offline toast', () async {
    await provider.init('token');
    while (provider.consumeToastEvent() != null) {} // drain

    // Advance past schoolYears stale threshold (staleTtl = 2 days)
    // but courses stale threshold (staleTtl = 12h) is already expired
    // Use markStale instead of clock advance to avoid expiry
    cache.markStale('schedule:school_years');
    cache.markStale('schedule:course_hours');

    await provider.init('token');

    expect(provider.isOfflineMode, isTrue);
    expect(provider.consumeToastEvent(), DataToastState.offline);
  });

  test('fetch mới thành công tạo success toast', () async {
    await provider.init('token');
    expect(provider.consumeToastEvent(), DataToastState.success);
  });

  test('fetch lỗi tạo error toast', () async {
    repository.failure = Exception('API down');
    await provider.init('token');

    expect(provider.consumeToastEvent(), DataToastState.error);
    expect(provider.errorMessage, isNotNull);
  });

  test('clearData xóa state và invalidate cache', () async {
    await provider.init('token');
    expect(provider.courses, isNotEmpty);

    provider.clearData();

    expect(provider.schoolYears, isEmpty);
    expect(provider.courses, isEmpty);
    expect(provider.courseHours, isEmpty);
    expect(provider.currentSemester, isNull);
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('selectSemester đổi semester và load courses mới', () async {
    await provider.init('token');
    final before = repository.getCoursesCallCount;

    await provider.selectSemester('token', 2);

    expect(provider.currentSemester, _fakeSemester2);
    expect(repository.getCoursesCallCount, greaterThan(before));
  });

  test('force refresh truyền xuống cache manager', () async {
    await provider.init('token');
    final before = repository.getCoursesCallCount;

    await provider.loadSchedule('token', 1, forceRefresh: true);

    expect(repository.getCoursesCallCount, greaterThan(before));
    expect(provider.isRefreshing, isFalse);
  });

  test('force refresh tạo success toast', () async {
    await provider.init('token');
    while (provider.consumeToastEvent() != null) {} // drain

    await provider.loadSchedule('token', 1, forceRefresh: true);

    expect(provider.consumeToastEvent(), DataToastState.success);
  });
}
