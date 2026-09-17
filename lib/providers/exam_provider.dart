import 'package:tlucalendar/core/cache/exam_cache_manager.dart';
import 'package:tlucalendar/core/cache/schedule_cache_manager.dart';
import 'package:tlucalendar/features/exam/data/models/exam_dtos.dart' as Legacy;
import 'package:tlucalendar/services/notification_service.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course_hour.dart';
import 'package:tlucalendar/features/schedule/domain/entities/school_year.dart';
import 'package:tlucalendar/features/exam/domain/entities/exam_schedule.dart';
import 'package:tlucalendar/features/exam/domain/entities/exam_room.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:tlucalendar/providers/auth_provider.dart';

class ExamProvider with ChangeNotifier {
  final ExamCacheManager _examCache;
  final ScheduleCacheManager _scheduleCache;

  AuthProvider? _authProvider;

  ExamProvider({
    required ExamCacheManager examCacheManager,
    required ScheduleCacheManager scheduleCacheManager,
  })  : _examCache = examCacheManager,
        _scheduleCache = scheduleCacheManager;

  void setAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  void clearData() {
    _registerPeriods = [];
    _availableSemesters = [];
    _examRooms = [];
    _examRoomEntities = [];
    _courseHours = [];
    _selectedRegisterPeriodId = null;
    _selectedSemesterId = null;
    _selectedExamRound = 1;
    _isLoading = false;
    _isLoadingSemesters = false;
    _isLoadingRooms = false;
    _errorMessage = null;
    _roomErrorMessage = null;
    _examCache.invalidateAll();
    notifyListeners();
  }

  List<Legacy.RegisterPeriod> _registerPeriods = [];
  List<Legacy.SemesterDto> _availableSemesters = [];
  List<Legacy.StudentExamRoom> _examRooms = [];
  List<CourseHour> _courseHours = [];
  bool _isLoading = false;
  bool _isLoadingSemesters = false;
  bool _isLoadingRooms = false;
  String? _errorMessage;
  String? _roomErrorMessage;

  int? _selectedRegisterPeriodId;
  int? _selectedSemesterId;
  int _selectedExamRound = 1;

  List<Legacy.RegisterPeriod> get registerPeriods => _registerPeriods;
  List<Legacy.SemesterDto> get availableSemesters => _availableSemesters;
  List<Legacy.StudentExamRoom> get examRooms => _examRooms;
  List<ExamRoom> _examRoomEntities = [];
  List<ExamRoom> get examRoomEntities => _examRoomEntities;
  bool get isLoading => _isLoading;
  bool get isLoadingSemesters => _isLoadingSemesters;
  bool get isLoadingRooms => _isLoadingRooms;
  String? get errorMessage => _errorMessage;
  String? get roomErrorMessage => _roomErrorMessage;
  int? get selectedRegisterPeriodId => _selectedRegisterPeriodId;
  int? get selectedSemesterId => _selectedSemesterId;
  int get selectedExamRound => _selectedExamRound;

  Legacy.RegisterPeriod? get selectedRegisterPeriod {
    if (_selectedRegisterPeriodId == null) return null;
    try {
      return _registerPeriods.firstWhere(
        (period) => period.id == _selectedRegisterPeriodId,
      );
    } catch (_) {
      return null;
    }
  }

  Legacy.SemesterDto? get selectedSemester {
    if (_selectedSemesterId == null) return null;
    try {
      return _availableSemesters.firstWhere(
        (semester) => semester.id == _selectedSemesterId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchAvailableSemesters(String accessToken) async {
    await init(accessToken);
  }

  Future<void> init(String accessToken) async {
    _isLoadingSemesters = true;
    notifyListeners();

    try {
      await _scheduleCache.preloadFromLocal();

      final yearsResult = await _scheduleCache.getSchoolYears(accessToken);
      _populateSemesters(yearsResult.data);

      final hoursResult = await _scheduleCache.getCourseHours(accessToken);
      _courseHours = hoursResult.data;

      if (_errorMessage != null && _availableSemesters.isNotEmpty) {
        _errorMessage = null;
      }
    } catch (e) {
      debugPrint('ExamProvider init failed: $e');
      _errorMessage = e.toString();

      if (_authProvider != null) {
        try {
          final newToken = _authProvider!.accessToken;
          if (newToken != null) {
            final yearsResult = await _scheduleCache.getSchoolYears(newToken);
            _populateSemesters(yearsResult.data);
            _errorMessage = null;
          }
        } catch (_) {}
      }
    }

    _isLoadingSemesters = false;
    notifyListeners();
  }

  void _populateSemesters(List<SchoolYear> years) {
    _availableSemesters = [];
    for (var year in years) {
      for (var sem in year.semesters) {
        _availableSemesters.add(
          Legacy.SemesterDto(
            id: sem.id,
            semesterCode: sem.semesterCode,
            semesterName: sem.semesterName,
            startDate: sem.startDate,
            endDate: sem.endDate,
            isCurrent: sem.isCurrent,
            semesterRegisterPeriods: [],
          ),
        );
      }
    }
    if (_availableSemesters.isNotEmpty) {
      final selectedStillExists =
          _selectedSemesterId != null &&
          _availableSemesters.any((s) => s.id == _selectedSemesterId);
      if (!selectedStillExists) {
        final currents =
            _availableSemesters.where((s) => s.isCurrent).toList();
        final mainCurrent = currents
            .where((s) => s.semesterName.toLowerCase().contains('học kỳ'))
            .firstOrNull;
        _selectedSemesterId =
            mainCurrent?.id ??
            currents.firstOrNull?.id ??
            _availableSemesters.last.id;
      }
    }
  }

  Future<bool> hasRegisterPeriodsCache(int semesterId) async {
    if (_selectedSemesterId == semesterId && _registerPeriods.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> selectSemesterFromCache(int semesterId) async {
    _selectedSemesterId = semesterId;
    notifyListeners();
  }

  Future<void> selectSemester(
    String accessToken,
    int semesterId,
    String? rawToken, {
    bool forceRefresh = false,
  }) async {
    if (_selectedSemesterId == semesterId &&
        _registerPeriods.isNotEmpty &&
        !forceRefresh) {
      return;
    }

    final previousPeriodId = _selectedRegisterPeriodId;
    final previousPeriodName = selectedRegisterPeriod?.name;
    _selectedSemesterId = semesterId;
    _errorMessage = null;

    if (!forceRefresh) {
      await _examCache.preloadSchedules(semesterId);
    }

    final shouldShowSpinner = _registerPeriods.isEmpty || forceRefresh;
    if (shouldShowSpinner) {
      _isLoading = true;
      _registerPeriods = [];
      notifyListeners();
    }

    try {
      final result = await _examCache.getExamSchedules(
        semesterId,
        accessToken,
        rawToken,
        forceRefresh: forceRefresh,
      );

      _populateRegisterPeriods(
        result.data,
        semesterId,
        accessToken,
        rawToken,
        preferredPeriodId: previousPeriodId,
        preferredPeriodName: previousPeriodName,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      if (_authProvider != null) {
        try {
          final newToken = _authProvider!.accessToken;
          final newRaw = _authProvider!.rawTokenStr ?? rawToken;
          if (newToken != null) {
            final result = await _examCache.getExamSchedules(
              semesterId, newToken, newRaw,
            );
            _populateRegisterPeriods(
              result.data,
              semesterId,
              newToken,
              newRaw,
              preferredPeriodId: previousPeriodId,
              preferredPeriodName: previousPeriodName,
              forceRefresh: forceRefresh,
            );
          }
        } catch (_) {
          if (shouldShowSpinner) {
            _errorMessage = e.toString();
          }
        }
      } else {
        if (shouldShowSpinner) {
          _errorMessage = e.toString();
          _selectedRegisterPeriodId = null;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _populateRegisterPeriods(
    List<ExamSchedule> schedules,
    int semesterId,
    String accessToken,
    String? rawToken, {
    int? preferredPeriodId,
    String? preferredPeriodName,
    bool forceRefresh = false,
  }) {
    final currentSem =
        selectedSemester ??
        Legacy.SemesterDto(
          id: semesterId,
          semesterCode: '',
          semesterName: '',
          startDate: 0,
          endDate: 0,
          isCurrent: false,
          semesterRegisterPeriods: [],
        );

    _registerPeriods = schedules
        .map(
          (e) => Legacy.RegisterPeriod(
            id: e.id,
            name: e.name,
            displayOrder: e.displayOrder,
            voided: e.voided,
            semester: currentSem,
            examPeriods: [],
          ),
        )
        .toList();

    if (_registerPeriods.isNotEmpty) {
      final preferred = _registerPeriods
          .where((period) => period.id == preferredPeriodId)
          .firstOrNull;
      final sameName = preferredPeriodName == null
          ? null
          : _registerPeriods
                .where((period) => period.name == preferredPeriodName)
                .firstOrNull;
      _selectedRegisterPeriodId =
          preferred?.id ?? sameName?.id ?? _registerPeriods.first.id;
      fetchExamRoomDetails(
        accessToken,
        semesterId,
        _selectedRegisterPeriodId!,
        _selectedExamRound,
        rawToken,
        forceRefresh: forceRefresh,
      );
    } else {
      _selectedRegisterPeriodId = null;
    }
  }

  void selectRegisterPeriod(
    String accessToken,
    int semesterId,
    int periodId,
    int round,
    String? rawToken, {
    bool forceRefresh = false,
  }) {
    if (_selectedRegisterPeriodId != periodId || forceRefresh) {
      _selectedRegisterPeriodId = periodId;
      notifyListeners();
      fetchExamRoomDetails(
        accessToken, semesterId, periodId, round, rawToken,
        forceRefresh: forceRefresh,
      );
    }
  }

  void selectExamRound(int round) {
    if (_selectedExamRound != round) {
      _selectedExamRound = round;
      notifyListeners();
    }
  }

  void setExamRound(int round) => selectExamRound(round);

  Future<void> fetchExamRoomDetails(
    String accessToken,
    int semesterId,
    int scheduleId,
    int round,
    String? rawToken, {
    bool forceRefresh = false,
  }) async {
    _roomErrorMessage = null;

    if (!forceRefresh) {
      await _examCache.preloadRooms(
        semesterId: semesterId,
        scheduleId: scheduleId,
        round: round,
      );
    }

    final shouldShowSpinner = _examRooms.isEmpty || forceRefresh;
    if (shouldShowSpinner) {
      _isLoadingRooms = true;
      notifyListeners();
    }

    try {
      final result = await _examCache.getExamRooms(
        semesterId: semesterId,
        scheduleId: scheduleId,
        round: round,
        accessToken: accessToken,
        rawToken: rawToken,
        forceRefresh: forceRefresh,
      );

      _populateExamRooms(result.data);
    } catch (e) {
      if (_authProvider != null) {
        try {
          final newToken = _authProvider!.accessToken;
          final newRaw = _authProvider!.rawTokenStr ?? rawToken;
          if (newToken != null) {
            final result = await _examCache.getExamRooms(
              semesterId: semesterId,
              scheduleId: scheduleId,
              round: round,
              accessToken: newToken,
              rawToken: newRaw,
            );
            _populateExamRooms(result.data);
          }
        } catch (_) {
          if (shouldShowSpinner) {
            _roomErrorMessage = 'Không thể kết nối đến máy chủ TLU';
          }
        }
      } else {
        if (shouldShowSpinner) {
          _roomErrorMessage = e.toString();
          _examRooms = [];
        }
      }
    } finally {
      _isLoadingRooms = false;
      if (_examRooms.isNotEmpty) {
        _scheduleNotifications();
      }
      notifyListeners();
    }
  }

  void _populateExamRooms(List<ExamRoom> rooms) {
    _examRoomEntities = rooms;
    _examRooms = rooms.map((e) {
      final detail = Legacy.ExamRoomDetail(
        id: 0,
        roomCode: e.roomName ?? '',
        examDate: e.examDate?.millisecondsSinceEpoch,
        examDateString: e.examDate != null
            ? DateFormat('dd/MM/yyyy').format(e.examDate!)
            : '',
        examHour: _parseExamHour(e.examTime),
        room: Legacy.Room(id: 0, name: e.roomName ?? '', code: ''),
        numberExpectedStudent: e.numberExpectedStudent ?? 0,
      );

      return Legacy.StudentExamRoom(
        id: e.id,
        status: 0,
        examPeriodCode: e.examPeriodCode,
        subjectName: e.subjectName,
        studentCode: e.studentCode,
        examRound: 0,
        examRoom: detail,
        examCode: e.examCode,
      );
    }).toList();
  }

  void _scheduleNotifications() {
    final notificationService = NotificationService();
    for (var room in _examRooms) {
      if (room.examRoom?.examDate != null && room.examRoom?.examHour != null) {
        final timeStr = room.examRoom!.examHour!.startString;
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);

          if (h != null && m != null) {
            final date = DateTime.fromMillisecondsSinceEpoch(
              room.examRoom!.examDate!,
            );
            final examDateTime = DateTime(
              date.year, date.month, date.day, h, m,
            );
            notificationService.scheduleExamNotifications(room, examDateTime);
          }
        }
      }
    }
  }

  Legacy.ExamHour _parseExamHour(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) {
      return Legacy.ExamHour(
        id: 0, name: 'Chưa có', startString: '', endString: '',
        start: 0, end: 0, indexNumber: 0, type: 0,
      );
    }

    String startStr = '';
    String endStr = '';
    String shiftName = timeStr;
    int start = 0;

    if (timeStr.contains('-')) {
      final parts = timeStr.split('-');
      if (parts.length >= 2) {
        startStr = parts[0].trim();
        endStr = parts[1].trim();

        if (RegExp(r'^\d{1,2}$').hasMatch(startStr)) {
          start = int.tryParse(startStr) ?? 0;
          int end = int.tryParse(endStr) ?? 0;

          String? realStartTime;
          String? realEndTime;

          if (_courseHours.isNotEmpty) {
            final startHour = _courseHours
                .where((h) => h.indexNumber == start)
                .firstOrNull;
            final endHour = _courseHours
                .where((h) => h.indexNumber == end)
                .firstOrNull;

            if (startHour != null) realStartTime = startHour.startString;
            if (endHour != null) realEndTime = endHour.endString;
          }

          if (realStartTime != null && realEndTime != null) {
            startStr = realStartTime;
            endStr = realEndTime;
          } else {
            startStr = 'Tiết $startStr';
            endStr = 'Tiết $endStr';
          }

          if (start >= 1 && start <= 3) {
            shiftName = 'Ca 1 (Sáng)';
          } else if (start >= 4 && start <= 6)
            shiftName = 'Ca 2 (Sáng)';
          else if (start >= 7 && start <= 9)
            shiftName = 'Ca 3 (Chiều)';
          else if (start >= 10 && start <= 12)
            shiftName = 'Ca 4 (Chiều)';
          else if (start >= 13)
            shiftName = 'Ca 5 (Tối)';
        }
      }
    }

    return Legacy.ExamHour(
      id: 0, name: shiftName, startString: startStr, endString: endStr,
      start: start, end: 0, indexNumber: 0, type: 0, code: '',
    );
  }
}
