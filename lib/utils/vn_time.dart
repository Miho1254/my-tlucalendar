import 'package:timezone/timezone.dart' as tz;

/// Centralized Vietnam timezone (GMT+7) utility.
/// Use [VnTime.now()] instead of DateTime.now() wherever the app
/// needs "right now" for schedule, notifications, or course status.
class VnTime {
  static const String _timezoneId = 'Asia/Ho_Chi_Minh';

  /// Current moment in Vietnam timezone.
  static DateTime now() {
    final vn = tz.getLocation(_timezoneId);
    return tz.TZDateTime.now(vn);
  }

  /// Today at midnight in Vietnam time.
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Convert epoch millis (stored as Vietnam local time in DB) to a
  /// date-only DateTime in Vietnam local time.
  static DateTime fromDateMs(int millisecondsSinceEpoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Whether two DateTimes represent the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
