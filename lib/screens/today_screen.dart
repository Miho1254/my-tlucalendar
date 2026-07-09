import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/schedule_provider.dart';
import 'package:tlucalendar/providers/exam_provider.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';
import 'package:tlucalendar/widgets/empty_state_widget.dart';
import 'package:tlucalendar/widgets/schedule_skeleton.dart';
import 'package:tlucalendar/widgets/timeline_item_optimized.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:forui/forui.dart';
import 'package:forui_assets/forui_assets.dart';
import 'package:tlucalendar/features/grades/presentation/pages/grade_screen.dart';
import 'package:tlucalendar/features/grades/presentation/pages/analytics_screen.dart';
import 'package:tlucalendar/screens/tuition_fee_screen.dart';
import 'package:tlucalendar/screens/education_program_screen.dart';
import 'package:tlucalendar/utils/vn_time.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late DateTime _currentDate;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentDate = VnTime.now();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = VnTime.now();
      if (now.day != _currentDate.day ||
          now.month != _currentDate.month ||
          now.year != _currentDate.year ||
          now.minute != _currentDate.minute) {
        setState(() {
          _currentDate = now;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = VnTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  static String? _getVietnameseFirstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;
    if (parts.length == 1) return parts.last;

    final lastWord = parts.last;

    const compoundEndings = {
      'Anh', 'Nhi', 'Vy', 'Vi', 'Tiên', 'Bảo',
      'Nguyên', 'Ân', 'Tú', 'Linh', 'Hà', 'Khuê', 'San',
    };

    if (compoundEndings.contains(lastWord) && parts.length >= 2) {
      final prevWord = parts[parts.length - 2];
      const genderMarkers = {'Thị', 'Văn', 'Hữu', 'Đình', 'Ngọc'};
      if (genderMarkers.contains(prevWord)) {
        return lastWord;
      }
      return '$prevWord $lastWord';
    }

    return lastWord;
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showCalendarSheet(BuildContext context) {
    final theme = Theme.of(context);
    DateTime sheetSelected = _currentDate;
    final sheetController = FGridCalendarController(
      initial: DateTime.utc(_currentDate.year, _currentDate.month),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Consumer<ScheduleProvider>(
              builder: (context, scheduleProvider, _) {
                final dayName = _getDayOfWeek(sheetSelected.weekday);
                final courses = scheduleProvider.getActiveCourses(sheetSelected);
                courses.sort(
                  (a, b) => a.startCourseHour.compareTo(b.startCourseHour),
                );

                return Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Month header with nav
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                FLucideIcons.chevronLeft,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                final targetMonth = DateTime(
                                  sheetSelected.year,
                                  sheetSelected.month - 1,
                                );
                                final maxDay = DateTime(
                                  targetMonth.year,
                                  targetMonth.month + 1,
                                  0,
                                ).day;
                                final preservedDay = sheetSelected.day
                                    .clamp(1, maxDay);
                                final newDate = DateTime(
                                  targetMonth.year,
                                  targetMonth.month,
                                  preservedDay,
                                );
                                sheetController.jumpToDayPicker(
                                  DateTime.utc(
                                    targetMonth.year,
                                    targetMonth.month,
                                  ),
                                );
                                setSheetState(() {
                                  sheetSelected = newDate;
                                });
                                setState(() {
                                  _currentDate = newDate;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'Tháng ${sheetSelected.month}, ${sheetSelected.year}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                FLucideIcons.chevronRight,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                final targetMonth = DateTime(
                                  sheetSelected.year,
                                  sheetSelected.month + 1,
                                );
                                final maxDay = DateTime(
                                  targetMonth.year,
                                  targetMonth.month + 1,
                                  0,
                                ).day;
                                final preservedDay = sheetSelected.day
                                    .clamp(1, maxDay);
                                final newDate = DateTime(
                                  targetMonth.year,
                                  targetMonth.month,
                                  preservedDay,
                                );
                                sheetController.jumpToDayPicker(
                                  DateTime.utc(
                                    targetMonth.year,
                                    targetMonth.month,
                                  ),
                                );
                                setSheetState(() {
                                  sheetSelected = newDate;
                                });
                                setState(() {
                                  _currentDate = newDate;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // Calendar grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final daySize = constraints.maxWidth / 7;
                            return FCalendar.grid(
                              control: FGridCalendarControl(
                                controller: sheetController,
                              ),
                              style: FCalendarStyleDelta.delta(
                                decoration: const DecorationDelta.value(
                                  BoxDecoration(color: Colors.transparent),
                                ),
                                padding: const EdgeInsetsGeometryDelta.value(
                                  EdgeInsets.zero,
                                ),
                                dayPickerStyle:
                                    FCalendarDayPickerStyleDelta.delta(
                                  daySize: Size(daySize, daySize),
                                ),
                              ),
                              selectionControl: FDateSelectionControl.lifted(
                                selected: (date) =>
                                    _isSameDay(date, sheetSelected),
                                select: (date) {
                                  setSheetState(() {
                                    sheetSelected = date;
                                  });
                                  setState(() {
                                    _currentDate = date;
                                  });
                                },
                              ),
                              dayBuilder: (
                                context,
                                styles,
                                localizations,
                                date,
                                variants,
                              ) {
                                final events = scheduleProvider
                                    .getActiveCourses(date);
                                final isToday = variants.contains(
                                  FCalendarDayVariant.today,
                                );
                                final modifiedVariants = Set.of(variants);
                                if (isToday) {
                                  modifiedVariants.remove(
                                    FCalendarDayVariant.today,
                                  );
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
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    margin: const EdgeInsets.all(4),
                                    alignment: Alignment.center,
                                    child: dayWidget,
                                  );
                                }

                                if (events.isEmpty) return dayWidget;

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    dayWidget,
                                    Positioned(
                                      bottom: 4,
                                      child: Container(
                                        width: 16,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),

                      // Selected day header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            Text(
                              '$dayName, ${sheetSelected.day}/${sheetSelected.month}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${courses.length} môn',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Mini schedule list
                      Expanded(
                        child: courses.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        FLucideIcons.coffee,
                                        size: 32,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Trống lịch!',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                itemCount: courses.length,
                                itemBuilder: (context, index) {
                                  final course = courses[index];
                                  final sHourObj = scheduleProvider.courseHours
                                      .where(
                                        (h) =>
                                            h.indexNumber ==
                                            course.startCourseHour,
                                      )
                                      .firstOrNull;
                                  final eHourObj = scheduleProvider.courseHours
                                      .where(
                                        (h) =>
                                            h.indexNumber ==
                                            course.endCourseHour,
                                      )
                                      .firstOrNull;

                                  final startStr =
                                      sHourObj?.startString ?? '??:??';
                                  final endStr =
                                      eHourObj?.endString ?? '??:??';

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 6,
                                    ),
                                    child: FCard.raw(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            // Time block
                                            SizedBox(
                                              width: 52,
                                              child: Text(
                                                startStr,
                                                style: theme
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Course info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    course.courseName,
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '$startStr - $endStr · ${course.room}',
                                                    style: theme
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
          },
        );
      },
    ).then((_) {
      sheetController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = VnTime.now();
    final isViewingToday =
        _currentDate.day == today.day &&
        _currentDate.month == today.month &&
        _currentDate.year == today.year;
    final dayName = _getDayOfWeek(_currentDate.weekday);
    final dateFormat = '$dayName, ${_currentDate.day}/${_currentDate.month}';

    return Consumer2<AuthProvider, ScheduleProvider>(
      builder: (context, authProvider, scheduleProvider, _) {
        if (!authProvider.isLoggedIn) {
          return const Center(
            child: EmptyStateWidget(
              icon: FLucideIcons.lock,
              title: 'Vui lòng đăng nhập',
              description: 'Đăng nhập để xem lịch học của bạn',
            ),
          );
        }

        if (scheduleProvider.isLoading) {
          return const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: ScheduleSkeleton(),
              ),
            ),
          );
        }

        // P0: Error state — distinguish "no classes" from "API failed"
        if (scheduleProvider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FLucideIcons.alertTriangle,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không thể tải lịch học',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scheduleProvider.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FButton(
                    onPress: () {
                      if (authProvider.accessToken != null &&
                          scheduleProvider.currentSemester != null) {
                        scheduleProvider.loadSchedule(
                          authProvider.accessToken!,
                          scheduleProvider.currentSemester!.id,
                          forceRefresh: true,
                        );
                      }
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final activeCourses = scheduleProvider.getActiveCourses(_currentDate);
        final todaySchedules = activeCourses;
        todaySchedules.sort(
          (a, b) => a.startCourseHour.compareTo(b.startCourseHour),
        );

        final userName =
            _getVietnameseFirstName(authProvider.currentUser?.fullName ?? '') ??
            'bạn';

        return RefreshIndicator(
          onRefresh: () async {
            if (authProvider.accessToken != null &&
                scheduleProvider.currentSemester != null) {
              await scheduleProvider.loadSchedule(
                authProvider.accessToken!,
                scheduleProvider.currentSemester!.id,
                forceRefresh: true,
              );

              final examProvider = context.read<ExamProvider>();
              if (examProvider.selectedSemesterId != null) {
                examProvider.selectSemester(
                  authProvider.accessToken!,
                  examProvider.selectedSemesterId!,
                  authProvider.rawTokenStr,
                  forceRefresh: true,
                );
              }
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 240.0,
                toolbarHeight: 0.0,
                pinned: false,
                stretch: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                  ],
                  background: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/today_dark.webp'
                        : 'assets/today.webp',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(25),
                  child: Transform.translate(
                    offset: const Offset(0, 1),
                    child: Container(
                      height: 25,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.theme.scaffoldStyle.backgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Greeting + Date Navigation
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  color: context.theme.scaffoldStyle.backgroundColor,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()},\n$userName! 👋',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isViewingToday
                            ? (todaySchedules.isEmpty
                                ? 'Hôm nay bạn được nghỉ ngơi thoải mái!'
                                : 'Hôm nay chiến ${todaySchedules.length} môn nhé.')
                            : 'Xem lịch ngày ${_currentDate.day}/${_currentDate.month}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showCalendarSheet(context),
                            child: FCard.raw(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      FLucideIcons.calendar,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateFormat,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      FLucideIcons.chevronDown,
                                      size: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!isViewingToday) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentDate = today;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      FLucideIcons.rotateCcw,
                                      size: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Hôm nay',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 3. Timeline List or Empty State
              if (todaySchedules.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: EmptyStateWidget(
                      icon: FLucideIcons.coffee,
                      title: 'Hôm nay trống lịch!',
                      description:
                          'Tuyệt vời! Tắt báo thức và ngủ tiếp thôi, hoặc xách cơ ra làm vài đường!',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  sliver: SliverList.builder(
                    itemCount: todaySchedules.length,
                    itemBuilder: (context, index) {
                      final course = todaySchedules[index];
                      final isLast = index == todaySchedules.length - 1;
                      final status = _getCourseStatus(
                        scheduleProvider,
                        course,
                      );

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: TimelineItemOptimized(
                              course: course,
                              isLast: isLast,
                              status: status,
                              startTime: _getTimeRange(
                                scheduleProvider,
                                course,
                              ).split('\n')[0],
                              timeRange: _getTimeRange(
                                scheduleProvider,
                                course,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 4. Utilities Section (moved below schedule)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'Tiện ích',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                      FTileGroup(
                        children: [
                          FTile(
                            prefix: Icon(
                              FLucideIcons.graduationCap,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Tra cứu điểm'),
                            suffix: const Icon(
                              FLucideIcons.chevronRight,
                              size: 20,
                            ),
                            onPress: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GradeScreen(),
                                ),
                              );
                            },
                          ),
                          FTile(
                            prefix: Icon(
                              FLucideIcons.pieChart,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Phân tích học tập'),
                            suffix: const Icon(
                              FLucideIcons.chevronRight,
                              size: 20,
                            ),
                            onPress: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AnalyticsScreen(),
                                ),
                              );
                            },
                          ),
                          FTile(
                            prefix: Icon(
                              FLucideIcons.wallet,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Kiểm tra học phí'),
                            suffix: const Icon(
                              FLucideIcons.chevronRight,
                              size: 20,
                            ),
                            onPress: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TuitionFeeScreen(),
                                ),
                              );
                            },
                          ),
                          FTile(
                            prefix: Icon(
                              FLucideIcons.school,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Chương trình đào tạo'),
                            suffix: const Icon(
                              FLucideIcons.chevronRight,
                              size: 20,
                            ),
                            onPress: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const EducationProgramScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverSafeArea(
                top: false,
                bottom: true,
                sliver: SliverToBoxAdapter(child: SizedBox(height: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  CourseStatus _getCourseStatus(
    ScheduleProvider scheduleProvider,
    Course course,
  ) {
    if (scheduleProvider.courseHours.isEmpty) return CourseStatus.future;

    final startHour = scheduleProvider.courseHours
        .where((h) => h.indexNumber == course.startCourseHour)
        .firstOrNull;
    final endHour = scheduleProvider.courseHours
        .where((h) => h.indexNumber == course.endCourseHour)
        .firstOrNull;

    if (startHour == null || endHour == null) return CourseStatus.future;

    final now = VnTime.now();
    final startParts = startHour.startString.split(':');
    final endParts = endHour.endString.split(':');

    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    if (now.isAfter(endTime)) {
      return CourseStatus.past;
    } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
      return CourseStatus.current;
    } else {
      return CourseStatus.future;
    }
  }

  String _getDayOfWeek(int weekday) {
    const days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    if (weekday >= 1 && weekday <= 7) return days[weekday - 1];
    return '';
  }

  String _getTimeRange(ScheduleProvider scheduleProvider, Course course) {
    if (scheduleProvider.courseHours.isEmpty) {
      return 'Tiết ${course.startCourseHour}\nTiết ${course.endCourseHour}';
    }

    final startHour = scheduleProvider.courseHours
        .where((h) => h.indexNumber == course.startCourseHour)
        .firstOrNull;
    final endHour = scheduleProvider.courseHours
        .where((h) => h.indexNumber == course.endCourseHour)
        .firstOrNull;

    if (startHour != null && endHour != null) {
      return '${startHour.startString}\n${endHour.endString}';
    }
    return 'Tiết ${course.startCourseHour}\nTiết ${course.endCourseHour}';
  }
}
