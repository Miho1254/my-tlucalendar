import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';
import 'package:tlucalendar/providers/schedule_provider.dart';
import 'package:tlucalendar/widgets/course_detail_sheet.dart';
import 'package:intl/intl.dart';
import 'package:forui/forui.dart';
import 'package:tlucalendar/utils/vn_time.dart';

class WeeklyTimetableWidget extends StatelessWidget {
  final DateTime selectedDate;

  const WeeklyTimetableWidget({
    super.key,
    required this.selectedDate,
  });

  // Shifts definitions
  static const double _rowHeight = 60.0;
  static const double _timeColumnWidth = 60.0;
  static const double _dayColumnWidth = 110.0;

  static const List<double> _curatedHues = [
    225, // Indigo
    175, // Teal
    150, // Emerald
    37,  // Amber
    345, // Rose
    265, // Violet
    200, // Sky
  ];

  Color _getPastelColor(String name, bool isDark) {
    final int hash = name.hashCode.abs();
    final double hue = _curatedHues[hash % _curatedHues.length];
    return HSLColor.fromAHSL(
      1.0,
      hue,
      isDark ? 0.55 : 0.65,
      isDark ? 0.14 : 0.93,
    ).toColor();
  }

  Color _getTextColor(String name, bool isDark) {
    final int hash = name.hashCode.abs();
    final double hue = _curatedHues[hash % _curatedHues.length];
    return HSLColor.fromAHSL(
      1.0,
      hue,
      0.80,
      isDark ? 0.85 : 0.30,
    ).toColor();
  }

  Color _getBorderColor(String name, bool isDark) {
    final int hash = name.hashCode.abs();
    final double hue = _curatedHues[hash % _curatedHues.length];
    return HSLColor.fromAHSL(
      1.0,
      hue,
      isDark ? 0.55 : 0.65,
      isDark ? 0.22 : 0.86,
    ).toColor();
  }

  String _getCourseTimeRange(Course course, List<dynamic> hours) {
    final startHour = hours.where((h) => h.indexNumber == course.startCourseHour).firstOrNull;
    final endHour = hours.where((h) => h.indexNumber == course.endCourseHour).firstOrNull;
    if (startHour != null && endHour != null) {
      return '${startHour.startString} - ${endHour.endString}';
    }
    return 'Tiết ${course.startCourseHour}-${course.endCourseHour}';
  }

  String _getPeriodTime(int periodIndex, List<dynamic> hours) {
    final hourObj = hours.where((h) => h.indexNumber == periodIndex).firstOrNull;
    if (hourObj != null) {
      return '${hourObj.startString} - ${hourObj.endString}';
    }
    const defaultTimes = {
      1: '07:00 - 07:50',
      2: '07:55 - 08:45',
      3: '08:50 - 09:40',
      4: '09:45 - 10:35',
      5: '10:40 - 11:30',
      6: '13:00 - 13:50',
      7: '13:55 - 14:45',
      8: '14:50 - 15:40',
      9: '15:45 - 16:35',
      10: '16:40 - 17:30',
      11: '18:00 - 18:50',
      12: '18:55 - 19:45',
      13: '19:50 - 20:40',
    };
    return defaultTimes[periodIndex] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hours = scheduleProvider.courseHours;

    // Calculate start of week (Monday)
    final int currentWeekday = selectedDate.weekday;
    final DateTime monday = selectedDate.subtract(Duration(days: currentWeekday - 1));

    // Generate 6 days: Thứ 2 -> Thứ 7
    final days = List.generate(6, (i) => monday.add(Duration(days: i)));

    // Check if today is in this week
    final now = VnTime.now();
    final todayInWeek = days.any((d) =>
        d.year == now.year && d.month == now.month && d.day == now.day);

    // Check if we need evening periods (11-13)
    bool hasEvening = false;
    for (int dayIdx = 0; dayIdx < 6; dayIdx++) {
      final date = days[dayIdx];
      final courses = scheduleProvider.getActiveCourses(date);
      if (courses.any((c) => c.startCourseHour >= 11 || c.endCourseHour >= 11)) {
        hasEvening = true;
        break;
      }
    }

    final totalPeriods = hasEvening ? 13 : 10;
    final double gridHeight = totalPeriods * _rowHeight;

    // Generate Positioned cards
    final List<Widget> positionedCards = [];

    for (int dayIdx = 0; dayIdx < 6; dayIdx++) {
      final date = days[dayIdx];
      final courses = scheduleProvider.getActiveCourses(date);

      // Sort courses by start hour
      courses.sort((a, b) => a.startCourseHour.compareTo(b.startCourseHour));

      // Resolve overlaps
      final Map<Course, int> lanes = {};
      final Map<Course, int> totalLanes = {};
      
      List<List<Course>> overlapGroups = [];
      for (final course in courses) {
        bool added = false;
        for (final group in overlapGroups) {
          if (group.any((c) => course.startCourseHour <= c.endCourseHour && course.endCourseHour >= c.startCourseHour)) {
            group.add(course);
            added = true;
            break;
          }
        }
        if (!added) {
          overlapGroups.add([course]);
        }
      }

      for (final group in overlapGroups) {
        for (int i = 0; i < group.length; i++) {
          lanes[group[i]] = i;
          totalLanes[group[i]] = group.length;
        }
      }

      for (final course in courses) {
        final lane = lanes[course] ?? 0;
        final total = totalLanes[course] ?? 1;

        final double cardWidth = _dayColumnWidth / total;
        final double cardLeft = dayIdx * _dayColumnWidth + (lane * cardWidth);
        final double cardTop = (course.startCourseHour - 1) * _rowHeight;
        final double cardHeight = (course.endCourseHour - course.startCourseHour + 1) * _rowHeight;

        positionedCards.add(
          Positioned(
            left: cardLeft + 2.0,
            top: cardTop + 2.0,
            width: cardWidth - 4.0,
            height: cardHeight - 4.0,
            child: _buildCourseCard(
              context,
              course,
              isDark,
              date,
              _getCourseTimeRange(course, hours),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Shift/Time Column (Sticky)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spacer to align with Header Row height
              const SizedBox(
                width: _timeColumnWidth,
                height: 45,
              ),
              const SizedBox(height: 8),
              ...List.generate(totalPeriods, (rowIdx) {
                final periodIndex = rowIdx + 1;
                final timeStr = _getPeriodTime(periodIndex, hours);
                final startTime = timeStr.isNotEmpty ? timeStr.split(' - ')[0] : '';
                return Container(
                  width: _timeColumnWidth,
                  height: _rowHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colors.border.withValues(alpha: 0.3),
                      ),
                      right: BorderSide(
                        color: colors.border,
                        width: 1.5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'T$periodIndex',
                        style: theme.typography.body.xs.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.foreground,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        startTime,
                        style: theme.typography.body.xs.copyWith(
                          fontSize: 8.5,
                          color: colors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(width: 4),
          // Horizontally Scrollable Grid (Header + Cells)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Header Row
                  Row(
                    children: List.generate(6, (index) {
                      final date = days[index];
                      final isCurrentSelected = date.year == selectedDate.year &&
                          date.month == selectedDate.month &&
                          date.day == selectedDate.day;
                      final isToday = todayInWeek &&
                          date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day;
                      final dayName = _getDayName(index + 2);

                      return Container(
                        key: ValueKey('day_header_${date.month}_${date.day}'),
                        width: _dayColumnWidth,
                        height: 45,
                        margin: const EdgeInsets.only(left: 0.0),
                        decoration: isToday
                            ? BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : const BoxDecoration(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayName,
                              style: theme.typography.body.xs.copyWith(
                                fontWeight: isToday || isCurrentSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrentSelected
                                    ? colors.primary
                                    : colors.foreground,
                              ),
                            ),
                            Text(
                              DateFormat('d/M').format(date),
                              style: theme.typography.body.xs.copyWith(
                                fontSize: 10,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  // Stack-based Absolute Grid Area
                  SizedBox(
                    width: 6 * _dayColumnWidth,
                    height: gridHeight,
                    child: Stack(
                      children: [
                        // Background Grid cells (Only horizontal lines)
                        Column(
                          children: List.generate(totalPeriods, (rowIdx) {
                            return Row(
                              children: List.generate(6, (dayIdx) {
                                return Container(
                                  width: _dayColumnWidth,
                                  height: _rowHeight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: colors.border
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          }),
                        ),
                        // Layer of positioned course cards
                        ...positionedCards,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
      BuildContext context, Course course, bool isDark, DateTime date, String timeRange) {
    final theme = FTheme.of(context);
    
    final cardBgColor = _getPastelColor(course.courseName, isDark);
    final cardTextColor = _getTextColor(course.courseName, isDark);
    final cardBorderColor = _getBorderColor(course.courseName, isDark);

    final int periodsCount = course.endCourseHour - course.startCourseHour + 1;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        border: Border.all(
          color: cardBorderColor,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CourseDetailSheet(
              course: course,
              classDate: date,
              timeRange: timeRange,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Course Name (Bold, clean layout)
                Expanded(
                  child: Text(
                    course.courseName,
                    style: theme.typography.body.xs.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cardTextColor,
                      fontSize: 10,
                      height: 1.2,
                    ),
                    maxLines: periodsCount > 1 ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),
                // Room and Time details
                if (periodsCount > 1) ...[
                  // Room
                  Row(
                    children: [
                      Icon(
                        Icons.room_outlined,
                        size: 9.5,
                        color: cardTextColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          course.room,
                          style: theme.typography.body.xs.copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: cardTextColor.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Time range
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 9.5,
                        color: cardTextColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          timeRange,
                          style: theme.typography.body.xs.copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: cardTextColor.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Row layout for tight 1-period height (e.g. 60px)
                  Row(
                    children: [
                      Icon(
                        Icons.room_outlined,
                        size: 9,
                        color: cardTextColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        course.room,
                        style: theme.typography.body.xs.copyWith(
                          fontSize: 8,
                          color: cardTextColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '  •  ${timeRange.split(' - ')[0]}',
                        style: theme.typography.body.xs.copyWith(
                          fontSize: 8,
                          color: cardTextColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDayName(int day) {
    if (day == 8) return 'CN';
    return 'Thứ $day';
  }
}
