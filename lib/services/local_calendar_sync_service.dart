import 'package:flutter/foundation.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course_hour.dart';
import 'package:tlucalendar/features/exam/domain/entities/exam_room.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCalendarSyncService {
  static final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  static Future<bool> _requestPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && (permissionsGranted.data == true)) {
      return true;
    }

    permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
    return permissionsGranted.isSuccess && (permissionsGranted.data == true);
  }

  static Future<String> getOrCreateTluCalendar() async {
    final granted = await _requestPermissions();
    if (!granted) {
      throw "Vui lòng cấp quyền truy cập Lịch thiết bị trong phần Cài đặt.";
    }

    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('tlu_calendar_local_id');

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (calendarsResult.isSuccess && calendarsResult.data != null) {
      // 1. Try resolving strictly by cached ID (bulletproof for Android 12)
      if (savedId != null) {
        final match = calendarsResult.data!.where((c) => c.id == savedId).toList();
        if (match.isNotEmpty && match.first.id != null) {
          return match.first.id!;
        }
      }

      // 2. Fallback to name-matching for devices that grant correct Cursor projections
      final existing = calendarsResult.data!
          .where((c) => (c.name == 'TLU Calendar' || c.name == 'Device Calendar' || c.accountName == 'TLU Calendar') && c.isReadOnly == false)
          .toList();
      if (existing.isNotEmpty && existing.first.id != null) {
        await prefs.setString('tlu_calendar_local_id', existing.first.id!);
        return existing.first.id!;
      }
    }
    
    // 3. Provision new calendar if it explicitly doesn't exist
    final createResult = await _deviceCalendarPlugin.createCalendar('TLU Calendar');
    if (createResult.isSuccess && createResult.data != null) {
      await prefs.setString('tlu_calendar_local_id', createResult.data!);
      return createResult.data!;
    }

    final dump = (calendarsResult.isSuccess && calendarsResult.data != null) 
      ? calendarsResult.data!.map((c) => "'${c.name}'").join(', ')
      : "null";

    throw "Không thể tạo Lịch nội bộ: ${createResult.errors.join(', ')}. Lịch hiện có: $dump";
  }

  static Future<String> deleteTluCalendar() async {
    final granted = await _requestPermissions();
    if (!granted) {
      throw "Vui lòng cấp quyền truy cập Lịch thiết bị trong phần Cài đặt.";
    }

    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('tlu_calendar_local_id');

    if (savedId != null) {
      final deleteResult = await _deviceCalendarPlugin.deleteCalendar(savedId);
      if (deleteResult.isSuccess) {
         await prefs.remove('tlu_calendar_local_id');
         return "Đã xóa Lịch nội bộ thành công theo ID ($savedId).";
      }
      // If delete strictly failed, we still clear the prefs to untether the dead ghost ID
      await prefs.remove('tlu_calendar_local_id');
    }

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (calendarsResult.isSuccess && calendarsResult.data != null) {
      // Fallback name hunt
      final target = calendarsResult.data!.where((c) => (c.name == 'TLU Calendar' || c.name == 'Device Calendar' || c.accountName == 'TLU Calendar') && c.isReadOnly == false).firstOrNull;

      if (target != null && target.id != null) {
        final deleteResult = await _deviceCalendarPlugin.deleteCalendar(target.id!);
        if (deleteResult.isSuccess) {
           return "Đã dò tìm và xóa Lịch nội bộ thành công.";
        }
        throw "Không thể xóa lịch: ${deleteResult.errors.join(', ')}";
      }

      final dump = calendarsResult.data!.map((c) => "[ID: ${c.id}]").join(', ');
      return "Không tìm thấy Lịch ứng dụng để xóa. (Đã xóa từ trước, hoặc hệ thống Android 12 đã tự động ẩn hoàn toàn Lịch này ở tầng dưới). Các IDs có trong máy: $dump";
    }
    
    return "Lỗi đọc lịch từ máy: ${calendarsResult.errors.join(', ')}";
  }

  static Future<String> exportScheduleToCalendar(
    String calendarId,
    List<Course> courses,
    List<CourseHour> courseHours,
  ) async {
    if (courses.isEmpty) return "Không có lịch học để đồng bộ.";

    final granted = await _requestPermissions();
    if (!granted) throw "Thiếu quyền Lịch thiết bị.";

    int minDate = courses.first.startDate;
    int maxDate = courses.first.endDate;
    for (var c in courses) {
      if (c.startDate < minDate) minDate = c.startDate;
      if (c.endDate > maxDate) maxDate = c.endDate;
    }

    Map<String, String> existingEventsMap = {};
    final purgeResult = await _deviceCalendarPlugin.retrieveEvents(
      calendarId,
      RetrieveEventsParams(
        startDate: DateTime.fromMillisecondsSinceEpoch(minDate).subtract(const Duration(days: 14)),
        endDate: DateTime.fromMillisecondsSinceEpoch(maxDate).add(const Duration(days: 14)),
      ),
    );
    if (purgeResult.isSuccess && purgeResult.data != null) {
      for (final ev in purgeResult.data!) {
        final desc = ev.description ?? '';
        final startTag = '[TLU_SYNC_COURSE:';
        if (desc.contains(startTag)) {
          final startIndex = desc.indexOf(startTag) + startTag.length;
          final endIndex = desc.indexOf(']', startIndex);
          if (endIndex != -1 && ev.eventId != null) {
            existingEventsMap[desc.substring(startIndex, endIndex)] = ev.eventId!;
          }
        }
      }
    }

    int successCount = 0;
    int failCount = 0;

    for (final course in courses) {
      try {
        await _createCourseEvent(calendarId, course, courseHours, existingEventsMap[course.courseCode]);
        successCount++;
      } catch (e) {
        debugPrint("Error syncing course ${course.courseCode}: $e");
        failCount++;
      }
    }

    return "Đã đồng bộ $successCount môn học${failCount > 0 ? ' ($failCount lỗi)' : ''}.";
  }

  static Future<String> exportExamToCalendar(
    String calendarId,
    List<ExamRoom> exams,
  ) async {
    if (exams.isEmpty) return "Không có lịch thi để đồng bộ.";

    final granted = await _requestPermissions();
    if (!granted) throw "Thiếu quyền Lịch thiết bị.";

    final validExams = exams.where((e) => e.examDate != null).toList();
    if (validExams.isEmpty) return "Không có lịch thi hợp lệ để đồng bộ.";

    DateTime minDate = validExams.first.examDate!;
    DateTime maxDate = validExams.first.examDate!;
    for (var e in validExams) {
      if (e.examDate!.isBefore(minDate)) minDate = e.examDate!;
      if (e.examDate!.isAfter(maxDate)) maxDate = e.examDate!;
    }

    Map<String, String> existingEventsMap = {};
    final purgeResult = await _deviceCalendarPlugin.retrieveEvents(
      calendarId,
      RetrieveEventsParams(
        startDate: minDate.subtract(const Duration(days: 7)),
        endDate: maxDate.add(const Duration(days: 7)),
      ),
    );
    if (purgeResult.isSuccess && purgeResult.data != null) {
      for (final ev in purgeResult.data!) {
        final desc = ev.description ?? '';
        final startTag = '[TLU_SYNC_EXAM:';
        if (desc.contains(startTag)) {
          final startIndex = desc.indexOf(startTag) + startTag.length;
          final endIndex = desc.indexOf(']', startIndex);
          if (endIndex != -1 && ev.eventId != null) {
            existingEventsMap[desc.substring(startIndex, endIndex)] = ev.eventId!;
          }
        }
      }
    }

    int successCount = 0;

    for (final exam in exams) {
      if (exam.examDate == null || exam.examTime == null) continue;

      try {
        final parsed = _parseExamDateTimeDetails(exam.examDate!, exam.examTime!);
        final startTime = parsed['start']!;
        final endTime = parsed['end']!;

        final examTag = "${exam.subjectName}-${exam.examDate!.millisecondsSinceEpoch}";
        final existingEventId = existingEventsMap[examTag];

        final event = Event(calendarId, eventId: existingEventId)
          ..title = "Thi: ${exam.subjectName}"
          ..description = "Phòng: ${exam.roomName ?? 'Unknown'}\nSBD: ${exam.studentCode ?? 'N/A'}\nGhi chú: ${exam.notes ?? ''} ${exam.examMethod ?? ''}\n\n[TLU_SYNC_EXAM:$examTag]"
          ..location = exam.roomName
          ..start = tz.TZDateTime.from(startTime, tz.local)
          ..end = tz.TZDateTime.from(endTime, tz.local);

        final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
        if (result!.isSuccess) {
          successCount++;
        } else {
          debugPrint("Failed to create exam event: ${result.errors}");
        }
      } catch (e) {
        debugPrint("Error syncing exam ${exam.subjectName}: $e");
      }
    }

    return "Đã đồng bộ $successCount lịch thi.";
  }

  // --- Helpers ---

  static Future<void> _createCourseEvent(
    String calendarId,
    Course course,
    List<CourseHour> courseHours,
    String? existingEventId,
  ) async {
    // 1. Calculate Start/End Date from Course
    final validFrom = DateTime.fromMillisecondsSinceEpoch(course.startDate);
    final validTo = DateTime.fromMillisecondsSinceEpoch(course.endDate);

    // 2. Adjust validFrom to the first actual day of class
    int targetWeekday = course.dayOfWeek - 1;
    if (targetWeekday == 0) targetWeekday = 7; 

    int daysDiff = targetWeekday - validFrom.weekday;
    if (daysDiff < 0) daysDiff += 7;

    final firstClassDate = validFrom.add(Duration(days: daysDiff));
    if (firstClassDate.isAfter(validTo)) {
      return;
    }

    // 3. Calculate Time
    final startHourModel = _findCourseHour(courseHours, course.startCourseHour);
    final endHourModel = _findCourseHour(courseHours, course.endCourseHour);

    final startTimeParts = startHourModel.startString.split(':');
    final endTimeParts = endHourModel.endString.split(':');

    final startDateTime = DateTime(
      firstClassDate.year,
      firstClassDate.month,
      firstClassDate.day,
      int.parse(startTimeParts[0]),
      int.parse(startTimeParts[1]),
    );

    final endDateTime = DateTime(
      firstClassDate.year,
      firstClassDate.month,
      firstClassDate.day,
      int.parse(endTimeParts[0]),
      int.parse(endTimeParts[1]),
    );

    // 4. Create Event
    final event = Event(calendarId, eventId: existingEventId)
      ..title = "${course.courseName} (${course.courseCode})"
      ..description = "Phòng: ${course.room}\nGV: ${course.lecturerName ?? 'N/A'}\n\n[TLU_SYNC_COURSE:${course.courseCode}]"
      ..location = course.room
      ..start = tz.TZDateTime.from(startDateTime, tz.local)
      ..end = tz.TZDateTime.from(endDateTime, tz.local)
      ..recurrenceRule = RecurrenceRule(
        RecurrenceFrequency.Weekly,
        endDate: tz.TZDateTime.from(validTo.add(const Duration(days: 1)), tz.local)
      );

    final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
    if (!result!.isSuccess) {
         throw "Failed to create event: ${result.errors.join(', ')}";
    }
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
    // timeStr should be like "13:30 (60 phút)" or just "13:30"
    String time = timeStr.split(' ')[0];
    List<String> parts = time.split(':');
    int startHour = 0;
    int startMinute = 0;
    if (parts.length >= 2) {
      startHour = int.tryParse(parts[0]) ?? 0;
      startMinute = int.tryParse(parts[1]) ?? 0;
    }

    Duration defaultDuration = const Duration(minutes: 60);

    final match = RegExp(r'\((\d+)\s*phút\)').firstMatch(timeStr);
    if (match != null) {
      int durationMinutes = int.tryParse(match.group(1) ?? '60') ?? 60;
      defaultDuration = Duration(minutes: durationMinutes);
    }
    
    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      startHour,
      startMinute,
    );
    final endTime = startTime.add(defaultDuration);

    return {'start': startTime, 'end': endTime};
  }
}
