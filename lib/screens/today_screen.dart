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

    // Update every minute (sufficient for class status updates)
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

  @override
  Widget build(BuildContext context) {
    final today = VnTime.now();
    final dayName = _getDayOfWeek(today.weekday);
    final dateFormat = '$dayName, ${today.day}/${today.month}';

    return Consumer2<AuthProvider, ScheduleProvider>(
      builder: (context, authProvider, scheduleProvider, _) {
        if (!authProvider.isLoggedIn) {
          return const Center(
            child: EmptyStateWidget(
              icon: Icons.lock_outlined,
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

        final activeCourses = scheduleProvider.getActiveCourses(today);
        // todayWeekIndex logic handled inside getActiveCourses
        final todaySchedules = activeCourses;
        todaySchedules.sort(
          (a, b) => a.startCourseHour.compareTo(b.startCourseHour),
        );

        final userName =
            authProvider.currentUser?.fullName.split(' ').last ?? 'bạn';

        return FScaffold(
          child: SafeArea(
            bottom: false, // Liquid Glass tab bar handles its own safe area
            child: RefreshIndicator(
              onRefresh: () async {
                if (authProvider.accessToken != null &&
                    scheduleProvider.currentSemester != null) {
                  // Refresh schedule (await — blocks UI until done)
                  await scheduleProvider.loadSchedule(
                    authProvider.accessToken!,
                    scheduleProvider.currentSemester!.id,
                    forceRefresh: true,
                  );

                  // Fire-and-forget exam refresh (don't block UI)
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
                  // Reconnecting Banner
                  if (scheduleProvider.isRefreshing)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: FAlert(
                          icon: const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          title: const Text('Đang lấy dữ liệu mới...'),
                        ),
                      ),
                    ),

                  if (scheduleProvider.isReconnecting)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: FAlert(
                          icon: const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          title: const Text('Đang thử kết nối lại...'),
                        ),
                      ),
                    ),

                  // Offline Banner
                  if (scheduleProvider.isOfflineMode &&
                      !scheduleProvider.isRefreshing)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: FAlert(
                          variant: FAlertVariant.destructive,
                          icon: const Icon(Icons.cloud_off, size: 16),
                          title: const Text(
                            'Mất kết nối. Đang hiển thị lịch đã lưu.',
                          ),
                        ),
                      ),
                    ),

                  // Greeting Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()},\n$userName! 👋',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            todaySchedules.isEmpty
                                ? 'Hôm nay bạn được nghỉ ngơi thoải mái!'
                                : 'Hôm nay chiến ${todaySchedules.length} môn nhé.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Date Chip
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FCard.raw(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Text(
                              dateFormat,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Utilities Section
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
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                                  FLucideIcons.bookOpen,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                title: const Text('Đăng ký học'),
                                suffix: const Icon(
                                  FLucideIcons.chevronRight,
                                  size: 20,
                                ),
                                onPress: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tính năng đang phát triển',
                                      ),
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

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Timeline List or Empty State
                  if (todaySchedules.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
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

                  // Add bottom safe area padding (automatically accounts for the Liquid Glass tab bar)
                  // plus a small clearance to prevent the last item from touching the tab bar.
                  const SliverSafeArea(
                    top: false,
                    bottom: true,
                    sliver: SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ),
                ],
              ),
            ),
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
    // Parse "HH:mm"
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
