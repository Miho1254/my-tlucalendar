import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:liquid_glass_nav/liquid_glass_nav.dart';
import 'package:provider/provider.dart';

import 'package:tlucalendar/providers/schedule_provider.dart';
import 'package:tlucalendar/utils/vn_time.dart';

import 'package:tlucalendar/screens/today_screen.dart';
import 'package:tlucalendar/screens/calendar_screen.dart';
import 'package:tlucalendar/screens/exam_schedule_screen.dart';
import 'package:tlucalendar/screens/settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeShell — Main navigation scaffold
// Implements Liquid Glass Bottom Nav package
// ─────────────────────────────────────────────────────────────────────────────
class HomeShell extends StatefulWidget {
  final int initialIndex;

  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _selectedIndex;

  final _screens = const [
    TodayScreen(),
    CalendarScreen(),
    ExamScheduleScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Make status bar transparent — edge-to-edge Apple style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ));
  }

  void _onTabTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    
    // Get schedule provider to determine today's courses
    final scheduleProvider = context.watch<ScheduleProvider>();
    final today = VnTime.now();
    final activeCoursesCount = scheduleProvider.getActiveCourses(today).length;

    final navItems = [
      LiquidGlassNavItem(
        icon: FLucideIcons.sun,
        label: 'Hôm nay',
        tooltip: 'Hôm nay',
        showBadge: activeCoursesCount > 0,
        badgeText: activeCoursesCount > 0 ? activeCoursesCount.toString() : null,
      ),
      LiquidGlassNavItem(
        icon: FLucideIcons.calendarDays,
        label: 'Lịch học',
        tooltip: 'Lịch học',
      ),
      LiquidGlassNavItem(
        icon: FLucideIcons.clipboardList,
        label: 'Lịch thi',
        tooltip: 'Lịch thi',
      ),
      LiquidGlassNavItem(
        icon: FLucideIcons.settings,
        label: 'Cài đặt',
        tooltip: 'Cài đặt',
        showBadge: scheduleProvider.isOfflineMode,
        badgeColor: Theme.of(context).colorScheme.error,
      ),
    ];

    return Scaffold(
      extendBody: true,          // content flows beneath the Liquid Glass bar
      backgroundColor: context.theme.scaffoldStyle.backgroundColor,
      body: Stack(
        children: [
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(
                bottom: (bottomPadding > 0 ? bottomPadding : 16) + 80.0,
              ),
            ),
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
          LiquidGlassBottomNav(
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: bottomPadding > 0 ? bottomPadding : 16,
            ),
            items: navItems,
            currentIndex: _selectedIndex,
            onTap: _onTabTap,
            animationType: NavAnimationType.scale,
            enableBounceAnimation: false,
            enableHapticFeedback: true,
            hapticFeedbackType: HapticFeedbackType.selection,
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.onSurfaceVariant,
            blurStrength: 20.0,
            borderRadius: 30.0,
          ),
        ],
      ),
    );
  }
}
