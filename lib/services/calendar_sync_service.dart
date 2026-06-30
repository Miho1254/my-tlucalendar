import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:http/http.dart' as http;
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course_hour.dart';
import 'package:tlucalendar/features/exam/domain/entities/exam_room.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class SyncCalendar {
  final String id;
  final String name;
  final String accountName;
  final String accountType;
  final int? color;

  SyncCalendar({
    required this.id,
    required this.name,
    required this.accountName,
    required this.accountType,
    this.color,
  });
}

class CalendarSyncService {
  static bool _initialized = false;
  static String? _cachedUserEmail;
  static String? _cachedAccessToken; // Tracks the current token for eviction if it fails
  static const List<String> _scopes = [
    google_calendar.CalendarApi.calendarEventsScope,
    google_calendar.CalendarApi.calendarReadonlyScope,
  ];

  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize();
      _initialized = true;
    }
  }

  static Future<google_calendar.CalendarApi?> _getCalendarApi() async {
    await _ensureInitialized();

    // Try silent auth first
    GoogleSignInAccount? account = await GoogleSignIn.instance.attemptLightweightAuthentication();
    
    // Fall back to explicit interactive auth if silent fails
    if (account == null) {
      try {
        account = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
      } catch (e) {
        debugPrint("Google Auth Error: $e");
        return null;
      }
    }



    _cachedUserEmail = account.email;

    final authz = await account.authorizationClient.authorizeScopes(_scopes);
    _cachedAccessToken = authz.accessToken;
    
    final authHeaders = <String, String>{
      'Authorization': 'Bearer ${authz.accessToken}',
      'X-Goog-AuthUser': '0',
    };

    final authenticateClient = GoogleAuthClient(authHeaders);
    return google_calendar.CalendarApi(authenticateClient);
  }

  static Future<List<SyncCalendar>> getWritableCalendars() async {
    final api = await _getCalendarApi();
    if (api == null) {
      throw "Đăng nhập Google thất bại, bị hủy hoặc chưa cấp quyền truy cập Lịch.";
    }

    try {
      final calendarList = await api.calendarList.list();
      final List<SyncCalendar> result = [];

      if (calendarList.items != null) {
        for (var cal in calendarList.items!) {
          if (cal.accessRole == 'owner' || cal.accessRole == 'writer') {
            int? colorInt;
            if (cal.backgroundColor != null) {
              String hex = cal.backgroundColor!.replaceAll('#', '');
              if (hex.length == 6) {
                hex = 'FF$hex';
              }
              colorInt = int.tryParse(hex, radix: 16);
            }
            
            result.add(SyncCalendar(
              id: cal.id!,
              name: cal.summary ?? 'Lịch không tên',
              accountName: _cachedUserEmail ?? 'Google Account',
              accountType: 'com.google',
              color: colorInt,
            ));
          }
        }
      }
      return result;
    } on google_calendar.DetailedApiRequestError catch (e) {
      if (e.status == 401 || e.status == 403) {
        if (_cachedAccessToken != null) {
          try {
            // FORCE Android Google Play Services to destroy THIS specific token from its persistent cache
            await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(accessToken: _cachedAccessToken!);
          } catch (_) {}
        }
        try {
          await GoogleSignIn.instance.disconnect();
        } catch (_) {}
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
        throw "Đã phát hiện và gỡ bỏ bộ đệm Token cũ (Mã ${e.status}). Vui lòng bấm Đồng Bộ một lần nữa để cấp lại quyền truy cập mới.";
      }
      rethrow;
    }
  }

  /// Syncs a list of courses to the Google calendar.
  static Future<String> exportScheduleToCalendar(
    String calendarId,
    List<Course> courses,
    List<CourseHour> courseHours,
  ) async {
    if (courses.isEmpty) return "Không có lịch học để đồng bộ.";

    final api = await _getCalendarApi();
    if (api == null) throw "Chưa xác thực Google hoặc từ chối quyền Lịch.";

    try {
      // **NEW**: Wipe old schedule events to prevent duplicates
      try {
        await _clearOldEvents(api, calendarId, 'course');
      } catch (e) {
        if (e is google_calendar.DetailedApiRequestError && (e.status == 401 || e.status == 403)) rethrow;
        debugPrint("Error clearing old course events: $e");
      }

      int successCount = 0;
      int failCount = 0;

      for (final course in courses) {
        try {
          await _createCourseEvent(api, calendarId, course, courseHours);
          successCount++;
        } catch (e) {
          if (e is google_calendar.DetailedApiRequestError && (e.status == 401 || e.status == 403)) rethrow;
          debugPrint("Error syncing course ${course.courseCode}: $e");
          failCount++;
        }
      }

      return "Đã đồng bộ $successCount môn học${failCount > 0 ? ' ($failCount lỗi)' : ''}.";
    } on google_calendar.DetailedApiRequestError catch (e) {
      if (e.status == 401 || e.status == 403) {
        if (_cachedAccessToken != null) {
          try {
            await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(accessToken: _cachedAccessToken!);
          } catch (_) {}
        }
        try {
          await GoogleSignIn.instance.disconnect();
        } catch (_) {}
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
        throw "Đã phát hiện và gỡ bỏ bộ đệm Token cũ (Mã ${e.status}). Vui lòng bấm Đồng Bộ một lần nữa để cấp lại quyền truy cập mới.";
      }
      rethrow;
    }
  }

  /// Syncs a list of exam rooms to the Google calendar.
  static Future<String> exportExamToCalendar(
    String calendarId,
    List<ExamRoom> exams,
  ) async {
    if (exams.isEmpty) return "Không có lịch thi để đồng bộ.";

    final api = await _getCalendarApi();
    if (api == null) throw "Chưa xác thực Google hoặc từ chối quyền Lịch.";

    try {
      // **NEW**: Wipe old exam events to prevent duplicates
      try {
        await _clearOldEvents(api, calendarId, 'exam');
      } catch (e) {
        if (e is google_calendar.DetailedApiRequestError && (e.status == 401 || e.status == 403)) rethrow;
        debugPrint("Error clearing old exam events: $e");
      }

      int successCount = 0;

      for (final exam in exams) {
        if (exam.examDate == null || exam.examTime == null) continue;

        try {
          final parsed = _parseExamDateTimeDetails(
            exam.examDate!,
            exam.examTime!,
          );
          final startTime = parsed['start']!;
          final endTime = parsed['end']!;

          final event = google_calendar.Event()
            ..summary = "Thi: ${exam.subjectName}"
            ..description =
                "Phòng: ${exam.roomName ?? 'Unknown'}\nSBD: ${exam.studentCode ?? 'N/A'}\nGhi chú: ${exam.notes ?? ''} ${exam.examMethod ?? ''}"
            ..location = exam.roomName
            ..extendedProperties = (google_calendar.EventExtendedProperties()
              ..private = {'tlucalendar_sync': 'exam'})
            ..start = (google_calendar.EventDateTime()
              ..dateTime = startTime
              ..timeZone = "Asia/Ho_Chi_Minh")
            ..end = (google_calendar.EventDateTime()
              ..dateTime = endTime
              ..timeZone = "Asia/Ho_Chi_Minh");

          await api.events.insert(event, calendarId);
          successCount++;
        } catch (e) {
          if (e is google_calendar.DetailedApiRequestError && (e.status == 401 || e.status == 403)) rethrow;
          debugPrint("Error syncing exam ${exam.subjectName}: $e");
        }
      }

      return "Đã đồng bộ $successCount lịch thi.";
    } on google_calendar.DetailedApiRequestError catch (e) {
      if (e.status == 401 || e.status == 403) {
        if (_cachedAccessToken != null) {
          try {
            await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(accessToken: _cachedAccessToken!);
          } catch (_) {}
        }
        try {
          await GoogleSignIn.instance.disconnect();
        } catch (_) {}
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
        throw "Đã phát hiện và gỡ bỏ bộ đệm Token cũ (Mã ${e.status}). Vui lòng bấm Đồng Bộ một lần nữa để cấp lại quyền truy cập mới.";
      }
      rethrow;
    }
  }

  // --- Helpers ---

  static Future<void> _clearOldEvents(
    google_calendar.CalendarApi api,
    String calendarId,
    String type,
  ) async {
    String? pageToken;
    do {
      final eventsResource = await api.events.list(
        calendarId,
        privateExtendedProperty: ["tlucalendar_sync=$type"],
        pageToken: pageToken,
      );

      final items = eventsResource.items;
      if (items != null) {
        for (var event in items) {
          if (event.id != null) {
            try {
              await api.events.delete(calendarId, event.id!);
            } catch (e) {
              debugPrint("Failed to delete old event \${event.id}: \$e");
            }
          }
        }
      }
      pageToken = eventsResource.nextPageToken;
    } while (pageToken != null);
  }

  static Future<void> _createCourseEvent(
    google_calendar.CalendarApi api,
    String calendarId,
    Course course,
    List<CourseHour> courseHours,
  ) async {
    // 1. Calculate Start/End Date from Course
    // Retrieve absolute UTC times (midnight UTC equivalent), align to Vietnam (UTC+7) absolute dates to avoid local phone timezone drifts.
    final utcValidFrom = DateTime.fromMillisecondsSinceEpoch(course.startDate, isUtc: true);
    final vnValidFrom = utcValidFrom.add(const Duration(hours: 7));
    final anchorValidFrom = DateTime.utc(vnValidFrom.year, vnValidFrom.month, vnValidFrom.day);

    final utcValidTo = DateTime.fromMillisecondsSinceEpoch(course.endDate, isUtc: true);
    final vnValidTo = utcValidTo.add(const Duration(hours: 7));
    final anchorValidTo = DateTime.utc(vnValidTo.year, vnValidTo.month, vnValidTo.day);

    // 2. Adjust validFrom to the first actual day of class
    int targetWeekday = course.dayOfWeek - 1;
    if (targetWeekday == 0) targetWeekday = 7; 

    int daysDiff = targetWeekday - anchorValidFrom.weekday;
    if (daysDiff < 0) daysDiff += 7;

    final firstClassDate = anchorValidFrom.add(Duration(days: daysDiff));
    if (firstClassDate.isAfter(anchorValidTo)) {
      return;
    }

    // 3. Calculate Time
    final startHourModel = _findCourseHour(courseHours, course.startCourseHour);
    final endHourModel = _findCourseHour(courseHours, course.endCourseHour);

    final startTimeParts = startHourModel.startString.split(':');
    final endTimeParts = endHourModel.endString.split(':');

    // **NEW**: Compute absolute UTC time for Vietnam Time (UTC+7)
    // To get 07:00 Vietnam Time, we use UTC time 00:00 (7 - 7)
    final startDateTime = DateTime.utc(
      firstClassDate.year,
      firstClassDate.month,
      firstClassDate.day,
      int.parse(startTimeParts[0]) - 7,
      int.parse(startTimeParts[1]),
    );
    final endDateTime = DateTime.utc(
      firstClassDate.year,
      firstClassDate.month,
      firstClassDate.day,
      int.parse(endTimeParts[0]) - 7,
      int.parse(endTimeParts[1]),
    );

    // 4. Create Event
    final event = google_calendar.Event()
      ..summary = "${course.courseName} (${course.courseCode})"
      ..description = "Phòng: ${course.room}\nGV: ${course.lecturerName ?? 'N/A'}"
      ..location = course.room
      ..extendedProperties = (google_calendar.EventExtendedProperties()
            ..private = {'tlucalendar_sync': 'course'})
      ..start = (google_calendar.EventDateTime()
        ..dateTime = startDateTime
        ..timeZone = "Asia/Ho_Chi_Minh")
      ..end = (google_calendar.EventDateTime()
        ..dateTime = endDateTime
        ..timeZone = "Asia/Ho_Chi_Minh")
      ..recurrence = [
        "RRULE:FREQ=WEEKLY;UNTIL=${_formatRecurrenceUntil(anchorValidTo)}"
      ];

    await api.events.insert(event, calendarId);
  }

  static String _formatRecurrenceUntil(DateTime date) {
    // End of the day in UTC, ensuring we don't miss any events on the final day's limits.
    final utcEnd = DateTime.utc(date.year, date.month, date.day, 23, 59, 59);
    return "${utcEnd.year}${utcEnd.month.toString().padLeft(2, '0')}${utcEnd.day.toString().padLeft(2, '0')}T235959Z";
  }

  static CourseHour _findCourseHour(List<CourseHour> hours, int index) {
    try {
      return hours.firstWhere((h) => h.indexNumber == index);
    } catch (_) {
      return _getDefaultCourseHour(index);
    }
  }

  static CourseHour _getDefaultCourseHour(int index) {
    final map = {
      1: ["07:00", "07:50"],
      2: ["07:55", "08:45"],
      3: ["08:50", "09:40"],
      4: ["09:45", "10:35"],
      5: ["10:40", "11:30"],
      6: ["11:35", "12:25"],
      7: ["12:30", "13:20"],
      8: ["13:25", "14:15"],
      9: ["14:20", "15:10"],
      10: ["15:15", "16:05"],
      11: ["16:10", "17:00"],
      12: ["17:05", "17:55"],
      13: ["18:00", "18:50"],
      14: ["18:55", "19:45"],
      15: ["19:50", "20:40"],
      16: ["20:45", "21:35"],
    };

    final times = map[index] ?? ["00:00", "01:00"];
    return CourseHour(
      id: index,
      name: "Tiết $index",
      startString: times[0],
      endString: times[1],
      indexNumber: index,
    );
  }

  static Map<String, DateTime> _parseExamDateTimeDetails(
    DateTime date,
    String timeStr,
  ) {
    const defaultDuration = Duration(minutes: 60);
    final cleanStr = timeStr.trim();

    int startHour = 7;
    int startMinute = 0;
    int endHour = 8;
    int endMinute = 0;
    bool hasEnd = false;

    if (cleanStr.contains(':')) {
      final parts = cleanStr.split(RegExp(r'\s*-\s*'));
      if (parts.isNotEmpty) {
        final startParts = parts[0].split(':');
        if (startParts.length >= 2) {
          startHour = int.tryParse(startParts[0]) ?? 7;
          startMinute = int.tryParse(startParts[1]) ?? 0;
        }

        if (parts.length >= 2) {
          final endParts = parts[1].split(':');
          if (endParts.length >= 2) {
            endHour = int.tryParse(endParts[0]) ?? (startHour + 1);
            endMinute = int.tryParse(endParts[1]) ?? startMinute;
            hasEnd = true;
          }
        }
      }
    } else if (cleanStr.toLowerCase().contains("ca")) {
      if (cleanStr.contains("1")) {
        startHour = 7;
        startMinute = 0;
      } else if (cleanStr.contains("2")) {
        startHour = 9;
        startMinute = 30;
      } else if (cleanStr.contains("3")) {
        startHour = 13;
        startMinute = 0;
      } else if (cleanStr.contains("4")) {
        startHour = 15;
        startMinute = 30;
      }
    }

    // **NEW**: Compute absolute UTC time for Vietnam Time (UTC+7)
    final startTime = DateTime.utc(
      date.year,
      date.month,
      date.day,
      startHour - 7,
      startMinute,
    );
    final endTime = hasEnd
        ? DateTime.utc(date.year, date.month, date.day, endHour - 7, endMinute)
        : startTime.add(defaultDuration);

    return {'start': startTime, 'end': endTime};
  }
}
