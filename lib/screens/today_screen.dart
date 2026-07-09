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

  void _navigateDay(int delta) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: delta));
    });
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
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _navigateDay(-1),
                              child: Icon(
                                FLucideIcons.chevronLeft,
                                size: 20,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FCard.raw(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                child: Text(
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
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _navigateDay(1),
                              child: Icon(
                                FLucideIcons.chevronRight,
                                size: 20,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            if (!isViewingToday) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _currentDate = today;
                                  });
                                },
                                child: Text(
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
                              ),
                            ],
                          ],
                        ),
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
