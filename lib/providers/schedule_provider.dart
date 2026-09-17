import 'package:flutter/material.dart';
import 'package:tlucalendar/core/cache/schedule_cache_manager.dart';
import 'package:tlucalendar/core/native/native_parser.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course_hour.dart';
import 'package:tlucalendar/features/schedule/domain/entities/school_year.dart';
import 'package:tlucalendar/features/schedule/domain/entities/semester.dart';
import 'package:tlucalendar/services/notification_service.dart';
import 'package:tlucalendar/widgets/update_banner.dart';
import 'package:tlucalendar/providers/auth_provider.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleCacheManager _cacheManager;

  AuthProvider? _authProvider;

  ScheduleProvider({
    required ScheduleCacheManager cacheManager,
  }) : _cacheManager = cacheManager;

  void setAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  List<SchoolYear> _schoolYears = [];
  List<Course> _courses = [];
  List<CourseHour> _courseHours = [];
  Semester? _currentSemester;

  bool _isOfflineMode = false;
  bool _isReconnecting = false;
  bool _isRefreshing = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<DataToastState> _pendingToasts = [];

  List<SchoolYear> get schoolYears => _schoolYears;
  List<Course> get courses => _courses;
  List<CourseHour> get courseHours => _courseHours;
  Semester? get currentSemester => _currentSemester;
  Semester? get selectedSemester => _currentSemester;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOfflineMode => _isOfflineMode;
  bool get isReconnecting => _isReconnecting;
  bool get isRefreshing => _isRefreshing;

  DataToastState? consumeToastEvent() {
    if (_pendingToasts.isEmpty) return null;
    return _pendingToasts.removeAt(0);
  }

  void _enqueueToast(DataToastState state) {
    _pendingToasts.add(state);
  }

  void clearData() {
    _schoolYears = [];
    _courses = [];
    _courseHours = [];
    _currentSemester = null;
    _isOfflineMode = false;
    _isReconnecting = false;
    _isRefreshing = false;
    _isLoading = false;
    _errorMessage = null;
    _cacheManager.invalidateAll();
    notifyListeners();
  }

  Future<void> init(String accessToken) async {
    _isLoading = true;
    _errorMessage = null;
    _isOfflineMode = false;
    _isReconnecting = false;
    _isRefreshing = false;
    notifyListeners();

    try {
      await _cacheManager.preloadFromLocal();

      final yearsResult = await _cacheManager.getSchoolYears(accessToken);
      _processSchoolYears(yearsResult.data);
      _isOfflineMode = yearsResult.isFromCache && yearsResult.isStale;
      if (_isOfflineMode) {
        _enqueueToast(DataToastState.offline);
      } else if (!yearsResult.isFromCache) {
        _enqueueToast(DataToastState.success);
      }

      final hoursResult = await _cacheManager.getCourseHours(accessToken);
      _courseHours = hoursResult.data;

      if (_currentSemester != null) {
        await loadSchedule(accessToken, _currentSemester!.id);
      }
    } catch (e) {
      debugPrint('ScheduleProvider init failed: $e');
      _errorMessage = e.toString();
      _enqueueToast(DataToastState.error);

      if (_authProvider != null) {
        try {
          _isReconnecting = true;
          notifyListeners();

          final newToken = _authProvider!.accessToken;
          if (newToken != null) {
            final yearsResult = await _cacheManager.getSchoolYears(newToken);
            _processSchoolYears(yearsResult.data);

            final hoursResult = await _cacheManager.getCourseHours(newToken);
            _courseHours = hoursResult.data;

            if (_currentSemester != null) {
              await loadSchedule(newToken, _currentSemester!.id);
            }

            _errorMessage = null;
          }
        } catch (retryError) {
          debugPrint('Retry failed: $retryError');
        } finally {
          _isReconnecting = false;
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _processSchoolYears(List<SchoolYear> years) async {
    _schoolYears = years;
    _schoolYears.sort((a, b) => a.startDate.compareTo(b.startDate));

    List<Semester> currents = [];
    for (var y in years) {
      for (var s in y.semesters) {
        if (s.isCurrent) currents.add(s);
      }
    }

    Semester? foundCurrent = currents
        .where((s) => s.semesterName.toLowerCase().contains('học kỳ'))
        .firstOrNull;
    foundCurrent ??= currents.firstOrNull;

    if (foundCurrent == null &&
        years.isNotEmpty &&
        years.last.semesters.isNotEmpty) {
      foundCurrent = years.last.semesters.last;
    }

    _currentSemester = foundCurrent;
  }

  Future<void> selectSemester(String accessToken, int semesterId) async {
    Semester? found;
    for (var y in _schoolYears) {
      final s = y.semesters.where((s) => s.id == semesterId).firstOrNull;
      if (s != null) {
        found = s;
        break;
      }
    }

    if (found != null) {
      _currentSemester = found;
      _courses = [];
      _isLoading = true;
      notifyListeners();
      await loadSchedule(accessToken, semesterId);
    }
  }

  Future<void> loadSchedule(
    String accessToken,
    int semesterId, {
    bool forceRefresh = false,
  }) async {
    _errorMessage = null;
    _isRefreshing = forceRefresh;

    try {
      if (!forceRefresh) {
        await _cacheManager.preloadCourses(semesterId);
      }

      final result = await _cacheManager.getCourses(
        semesterId,
        accessToken,
        forceRefresh: forceRefresh,
      );

      _courses = result.data;
      if (result.isFromCache && result.isStale) {
        _isOfflineMode = true;
        _enqueueToast(DataToastState.offline);
      } else if (!result.isFromCache) {
        _enqueueToast(DataToastState.success);
      }

      _scheduleNotifications();
    } catch (e) {
      debugPrint('loadSchedule failed: $e');
      _errorMessage = e.toString();
      _enqueueToast(DataToastState.error);
    }

    _isLoading = false;
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> _scheduleNotifications() async {
    try {
      await Future.delayed(Duration.zero);
      if (_currentSemester == null || _courses.isEmpty) return;

      final notificationService = NotificationService();
      await notificationService.cancelAllNotifications();
      if (_currentSemester == null) return;

      final notifications = NativeParser.generateNotifications(
        _currentSemester!.startDate,
      );

      if (notifications.isEmpty && _courses.isNotEmpty) {
        await _scheduleDartNotifications(notificationService);
        return;
      }

      int count = 0;
      for (var n in notifications) {
        await notificationService.scheduleNativeClassNotification(n);
        count++;
        if (count % 20 == 0) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
    } catch (e) {
      debugPrint('[ScheduleProvider] Notification scheduling failed: $e');
    }
  }

  Future<void> _scheduleDartNotifications(
    NotificationService notificationService,
  ) async {
    if (_courseHours.isEmpty) return;

    int count = 0;
    for (var course in _courses) {
      final startHourObj = _courseHours.firstWhere(
        (h) => h.id == course.startCourseHour,
        orElse: () => _courseHours.first,
      );

      final timeParts = startHourObj.startString.split(':');
      if (timeParts.length < 2) continue;
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final semesterStart = DateTime.fromMillisecondsSinceEpoch(
        _currentSemester!.startDate,
      );

      for (int w = course.fromWeek; w <= course.toWeek; w++) {
        final weekStart = semesterStart.add(Duration(days: (w - 1) * 7));
        final offsetDays = course.dayOfWeek - 2;
        final classDate = weekStart.add(Duration(days: offsetDays));

        final classDateTime = DateTime(
          classDate.year, classDate.month, classDate.day, hour, minute,
        );

        await notificationService.scheduleClassNotifications(
          course, classDateTime, course.dayOfWeek,
          "${startHourObj.startString}-${startHourObj.endString}",
        );

        count++;
        if (count % 20 == 0) {
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }
    }
  }

  List<Course> getActiveCourses(DateTime date) {
    final tluDayOfWeek = date.weekday + 1;
    return _courses.where((course) {
      return course.dayOfWeek == tluDayOfWeek && course.isActiveOn(date);
    }).toList();
  }
}
