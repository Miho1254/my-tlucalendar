import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/schedule_provider.dart';
import 'package:tlucalendar/providers/note_provider.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';
import 'package:tlucalendar/widgets/empty_state_widget.dart';
import 'package:tlucalendar/widgets/schedule_skeleton.dart';
import 'package:intl/intl.dart';
import 'package:tlucalendar/widgets/course_card_optimized.dart';
import 'package:tlucalendar/widgets/course_detail_sheet.dart';
import 'package:tlucalendar/utils/semester_parser.dart';
import 'package:tlucalendar/widgets/weekly_timetable_widget.dart';
import 'package:tlucalendar/utils/vn_time.dart';

bool _isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  bool _isWeeklyView = false;
  late final FGridCalendarController _calendarController;
  static final DateFormat _headerDateFormat = DateFormat(
    'EEEE, d MMMM, yyyy',
    'vi',
  );

  @override
  void initState() {
    super.initState();
    _selectedDate = VnTime.now();
    _calendarController = FGridCalendarController(
      initial: DateTime.utc(_selectedDate.year, _selectedDate.month),
    );
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  void _jumpToToday() {
    setState(() {
      _selectedDate = VnTime.now();
    });
    _calendarController.jumpToDayPicker(
      DateTime.utc(_selectedDate.year, _selectedDate.month),
    );
  }

  String _getWeekRangeString(DateTime date) {
    final int currentWeekday = date.weekday;
    final DateTime monday = date.subtract(Duration(days: currentWeekday - 1));
    final DateTime saturday = monday.add(const Duration(days: 5));
    final DateFormat formatter = DateFormat('dd/MM');
    return 'Tuần: ${formatter.format(monday)} - ${formatter.format(saturday)}';
  }

  List<Course> _getEventsForDay(
    DateTime day,
    ScheduleProvider scheduleProvider,
  ) {
    return scheduleProvider.getActiveCourses(day);
  }

  double _calculateSurvivalProgress(ScheduleProvider provider) {
    final currentDay = _selectedDate.weekday;
    final startOfWeek = _selectedDate.subtract(Duration(days: currentDay - 1));

    int total = 0;
    int completed = 0;
    final now = VnTime.now();

    for (int i = 0; i < 7; i++) {
      final checkDate = startOfWeek.add(Duration(days: i));
      final coursesForDay = provider.getActiveCourses(checkDate);
      total += coursesForDay.length;

      if (checkDate.isBefore(DateTime(now.year, now.month, now.day))) {
        completed += coursesForDay.length;
      } else if (_isSameDay(checkDate, now)) {
        for (final c in coursesForDay) {
          final eHourObj = provider.courseHours
              .where((h) => h.indexNumber == c.endCourseHour)
              .firstOrNull;
          if (eHourObj != null) {
            final endParts = eHourObj.endString.split(':');
            final endTimeDt = DateTime(
              now.year,
              now.month,
              now.day,
              int.parse(endParts[0]),
              int.parse(endParts[1]),
            );
            if (now.isAfter(endTimeDt)) {
              completed += 1;
            }
          }
        }
      }
    }

    if (total == 0) return 1.0;
    return completed / total;
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final provider = context.read<ScheduleProvider>();
            final auth = context.read<AuthProvider>();
            if (auth.accessToken != null && provider.currentSemester != null) {
              await provider.loadSchedule(
                auth.accessToken!,
                provider.currentSemester!.id,
                forceRefresh: true,
              );
            }
          },
          child: RepaintBoundary(
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildSurvivalBar(context)),
              if (!_isWeeklyView) ...[
                SliverToBoxAdapter(child: _buildCalendar(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                _buildCourseSliverList(context),
              ] else ...[
                SliverToBoxAdapter(
                  child: WeeklyTimetableWidget(
                    key: ValueKey('week_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}'),
                    selectedDate: _selectedDate,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSurvivalBar(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        final progress = _calculateSurvivalProgress(provider);
        final theme = Theme.of(context);

        final totalThisWeek = [
          for (var i = 0; i < 7; i++)
            provider.getActiveCourses(
              _selectedDate
                  .subtract(Duration(days: _selectedDate.weekday - 1))
                  .add(Duration(days: i)),
            ),
        ].fold<int>(0, (p, e) => p + e.length);

        if (totalThisWeek == 0) return const SizedBox.shrink();

        final percent = (progress * 100).toInt();
        final isDone = progress >= 1.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isDone
                        ? "🎉 Đã sống sót qua tuần này!"
                        : "Tiến độ sống sót tuần này",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    "$percent%",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isToday = _isSameDay(_selectedDate, VnTime.now());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Lịch học',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        FButton.icon(
                          onPress: () {
                            setState(() {
                              _isWeeklyView = !_isWeeklyView;
                            });
                          },
                          variant: FButtonVariant.ghost,
                          child: Icon(
                            _isWeeklyView
                                ? Icons.calendar_view_month
                                : Icons.calendar_view_week,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Opacity(
                          opacity: isToday ? 0.0 : 1.0,
                          child: IgnorePointer(
                            ignoring: isToday,
                            child: FButton.icon(
                              onPress: _jumpToToday,
                              variant: FButtonVariant.ghost,
                              child: const Icon(Icons.today, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildSemesterSelector(context),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _isWeeklyView
                    ? Row(
                        children: [
                          FButton.icon(
                            onPress: () {
                              setState(() {
                                _selectedDate = _selectedDate.subtract(
                                  const Duration(days: 7),
                                );
                              });
                            },
                            variant: FButtonVariant.ghost,
                            child: const Icon(Icons.chevron_left, size: 20),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getWeekRangeString(_selectedDate),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: isToday || _isSameDay(
                                    _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1)),
                                    VnTime.now().subtract(Duration(days: VnTime.now().weekday - 1)),
                                  )
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(width: 4),
                          FButton.icon(
                            onPress: () {
                              setState(() {
                                _selectedDate = _selectedDate.add(
                                  const Duration(days: 7),
                                );
                              });
                            },
                            variant: FButtonVariant.ghost,
                            child: const Icon(Icons.chevron_right, size: 20),
                          ),
                        ],
                      )
                    : Text(
                        _headerDateFormat.format(_selectedDate),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSelector(BuildContext context) {
    return Consumer2<ScheduleProvider, AuthProvider>(
      builder: (context, scheduleProvider, authProvider, _) {
        if (scheduleProvider.schoolYears.isEmpty) {
          return const SizedBox.shrink();
        }

        final selectedSemester = scheduleProvider.selectedSemester;

        return FButton(
          onPress: () =>
              _showSemesterPicker(context, scheduleProvider, authProvider),
          variant: FButtonVariant.secondary,
          prefix: const Icon(Icons.calendar_today, size: 16),
          child: Text(
            selectedSemester?.semesterName.toShortReadableSemester ?? 'Học kỳ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }

  void _showSemesterPicker(
    BuildContext context,
    ScheduleProvider scheduleProvider,
    AuthProvider authProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // True dark via container inside
      builder: (context) {
        final theme = Theme.of(context);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Chọn học kỳ',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: scheduleProvider.schoolYears.length,
                  itemBuilder: (context, index) {
                    final year =
                        scheduleProvider.schoolYears[scheduleProvider
                                .schoolYears
                                .length -
                            1 -
                            index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              bottom: 8.0,
                            ),
                            child: Text(
                              year.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          FTileGroup(
                            children: year.semesters.reversed.map<FTile>((
                              semester,
                            ) {
                              final isSelected =
                                  semester.id ==
                                  scheduleProvider.selectedSemester?.id;
                              return FTile(
                                title: Text(
                                  semester.semesterName.toReadableSemester,
                                ),
                                onPress: () async {
                                  HapticFeedback.selectionClick();
                                  if (authProvider.accessToken != null) {
                                    await scheduleProvider.selectSemester(
                                      authProvider.accessToken!,
                                      semester.id,
                                    );
                                    if (mounted) {
                                      final newDate =
                                          DateTime.fromMillisecondsSinceEpoch(
                                            semester.startDate,
                                          );
                                      setState(() {
                                        _selectedDate = newDate;
                                      });
                                      _calendarController.jumpToDayPicker(
                                        DateTime.utc(
                                          newDate.year,
                                          newDate.month,
                                        ),
                                      );
                                    }
                                  }
                                  if (context.mounted) Navigator.pop(context);
                                },
                                suffix: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: theme.colorScheme.primary,
                                      )
                                    : null,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildCalendar(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate dynamic day size to fill available width perfectly without horizontal padding
            final double daySize = constraints.maxWidth / 7;

            return FCalendar.grid(
              control: FGridCalendarControl(controller: _calendarController),
              style: FCalendarStyleDelta.delta(
                decoration: const DecorationDelta.value(
                  BoxDecoration(color: Colors.transparent),
                ),
                padding: const EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
                dayPickerStyle: FCalendarDayPickerStyleDelta.delta(
                  daySize: Size(daySize, daySize),
                ),
              ),
              selectionControl: FDateSelectionControl.lifted(
                selected: (date) => !_isSameDay(date, VnTime.now()) && _isSameDay(date, _selectedDate),
                select: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
              dayBuilder: (context, styles, localizations, date, variants) {
                final events = _getEventsForDay(date, provider);
                final hasExam = events.any(
                  (e) =>
                      e.courseName.toLowerCase().contains("thi ") ||
                      e.status.toLowerCase().contains("exam"),
                );
                final noteProvider = context.watch<NoteProvider>();
                final hasNote = events.any((e) {
                  final sHourObj = provider.courseHours
                      .where((h) => h.indexNumber == e.startCourseHour)
                      .firstOrNull;
                  final classDate = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    sHourObj != null
                        ? int.parse(sHourObj.startString.split(':')[0])
                        : 0,
                    sHourObj != null
                        ? int.parse(sHourObj.startString.split(':')[1])
                        : 0,
                  );
                  return noteProvider.hasNoteFor(
                    'course_${e.id}_${classDate.millisecondsSinceEpoch}',
                  );
                });

                final isToday = variants.contains(FCalendarDayVariant.today);
                final Set<FCalendarDayVariant> modifiedVariants = Set.from(
                  variants,
                );
                if (isToday) {
                  modifiedVariants.remove(FCalendarDayVariant.today);
                }

                Widget dayWidget = FCalendar.defaultDayBuilder(
                  context,
                  styles,
                  localizations,
                  date,
                  modifiedVariants,
                );

                if (isToday) {
                  dayWidget = Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      shape: BoxShape.circle,
                    ),
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    child: dayWidget,
                  );
                }

                if (events.isEmpty && !hasNote) {
                  return dayWidget;
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    dayWidget,
                    if (events.isNotEmpty)
                      Positioned(
                        bottom: 6,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hasExam
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    if (hasNote)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  bool _isRetryOnCooldown = false;

  Widget _buildCourseSliverList(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, _) {
        if (scheduleProvider.isLoading) {
          return const SliverToBoxAdapter(child: ScheduleSkeleton());
        }

        if (scheduleProvider.errorMessage != null &&
            scheduleProvider.courses.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildErrorState(context, scheduleProvider),
          );
        }

        final courses = scheduleProvider.getActiveCourses(_selectedDate);

        if (courses.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              title: 'Trống lịch rồi!',
              icon: FLucideIcons.inbox,
              isGamified: true,
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.only(top: 8, bottom: MediaQuery.paddingOf(context).bottom + 16),
          sliver: SliverList.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              String startTime = '${course.startCourseHour}';
              String endTime = '${course.endCourseHour}';

              final sHourObj = scheduleProvider.courseHours
                  .where((h) => h.indexNumber == course.startCourseHour)
                  .firstOrNull;
              final eHourObj = scheduleProvider.courseHours
                  .where((h) => h.indexNumber == course.endCourseHour)
                  .firstOrNull;

              if (sHourObj != null) startTime = sHourObj.startString;
              if (eHourObj != null) endTime = eHourObj.endString;

              final timeRange = '$startTime - $endTime';

              bool isPast = false;
              bool isCurrent = false;
              final now = VnTime.now();
              final isToday = _isSameDay(_selectedDate, now);

              if (_selectedDate.isBefore(
                DateTime(now.year, now.month, now.day),
              )) {
                isPast = true;
              } else if (isToday) {
                if (sHourObj != null && eHourObj != null) {
                  final startParts = sHourObj.startString.split(':');
                  final endParts = eHourObj.endString.split(':');
                  final startTimeDt = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    int.parse(startParts[0]),
                    int.parse(startParts[1]),
                  );
                  final endTimeDt = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    int.parse(endParts[0]),
                    int.parse(endParts[1]),
                  );

                  if (now.isAfter(endTimeDt)) {
                    isPast = true;
                  } else if (now.isAfter(startTimeDt) &&
                      now.isBefore(endTimeDt)) {
                    isCurrent = true;
                  }
                }
              }

              // Extract classDate logic out of builder so we can pass it to both
              final classDate = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                sHourObj != null
                    ? int.parse(sHourObj.startString.split(':')[0])
                    : 0,
                sHourObj != null
                    ? int.parse(sHourObj.startString.split(':')[1])
                    : 0,
              );

              return CourseCardOptimized(
                course: course,
                timeRange: timeRange,
                classDate: classDate,
                isPast: isPast,
                isCurrent: isCurrent,
                onTap: () {
                  // Show course detail bottom sheet with notes
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return CourseDetailSheet(
                        course: course,
                        classDate: classDate,
                        timeRange: timeRange,
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, ScheduleProvider provider) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Úi! Có lỗi rồi!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage ?? 'Không thể tải lịch học',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FButton(
                onPress: _isRetryOnCooldown
                    ? null
                    : () async {
                        setState(() => _isRetryOnCooldown = true);
                        final auth = context.read<AuthProvider>();
                        if (auth.accessToken != null &&
                            provider.currentSemester != null) {
                          await provider.loadSchedule(
                            auth.accessToken!,
                            provider.currentSemester!.id,
                          );
                        }
                        await Future.delayed(const Duration(seconds: 5));
                        if (mounted) setState(() => _isRetryOnCooldown = false);
                      },
                prefix: _isRetryOnCooldown
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                child: Text(_isRetryOnCooldown ? 'Vui lòng chờ...' : 'Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
