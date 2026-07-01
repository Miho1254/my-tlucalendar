import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:forui_assets/forui_assets.dart';
import 'package:tlucalendar/screens/today_screen.dart';
import 'package:tlucalendar/screens/calendar_screen.dart';
import 'package:tlucalendar/screens/exam_schedule_screen.dart';
import 'package:tlucalendar/screens/settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeShell — Main navigation scaffold
// Implements Apple HIG: Liquid Glass Tab Bar, Edge-to-Edge, SafeArea
// ─────────────────────────────────────────────────────────────────────────────
class HomeShell extends StatefulWidget {
  final int initialIndex;

  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  late int _selectedIndex;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scales;

  static const _tabs = [
    _TabInfo(label: 'Hôm nay',  icon: FLucideIcons.sun,        activeIcon: FLucideIcons.sunMedium),
    _TabInfo(label: 'Lịch học', icon: FLucideIcons.calendarDays, activeIcon: FLucideIcons.calendarCheck),
    _TabInfo(label: 'Lịch thi', icon: FLucideIcons.clipboardList, activeIcon: FLucideIcons.clipboardCheck),
    _TabInfo(label: 'Cài đặt',  icon: FLucideIcons.settings,    activeIcon: FLucideIcons.settings2),
  ];

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

    _controllers = List.generate(
      _tabs.length,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 180),
        vsync: this,
      ),
    );

    _scales = _controllers.map((c) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutBack),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    _controllers[index]
        .forward()
        .then((_) => _controllers[index].reverse());
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Make status bar transparent — edge-to-edge Apple style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ));

    return Scaffold(
      extendBody: true,          // content flows beneath the Liquid Glass bar
      backgroundColor: context.theme.scaffoldStyle.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _LiquidGlassTabBar(
        selectedIndex: _selectedIndex,
        tabs: _tabs,
        scales: _scales,
        onTap: _onTabTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Liquid Glass Tab Bar — BackdropFilter blur + hairline border
// ─────────────────────────────────────────────────────────────────────────────
class _LiquidGlassTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<_TabInfo> tabs;
  final List<Animation<double>> scales;
  final ValueChanged<int> onTap;

  const _LiquidGlassTabBar({
    required this.selectedIndex,
    required this.tabs,
    required this.scales,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          // Hairline top border — Zinc 800 on dark, Zinc 200 on light
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          // Min height: Apple tab bar ≈ 49pt + safe area bottom
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 49 + (bottomPadding > 0 ? 0 : 8), // 49pt min per HIG
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (i) {
                  return _TabItem(
                    tab: tabs[i],
                    isSelected: i == selectedIndex,
                    scale: scales[i],
                    onTap: () => onTap(i),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Tab Item — 44×44pt hit target (Apple HIG)
// ─────────────────────────────────────────────────────────────────────────────
class _TabItem extends StatelessWidget {
  final _TabInfo tab;
  final bool isSelected;
  final Animation<double> scale;
  final VoidCallback onTap;

  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;

    final color = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        // 44×44pt minimum hit target per Apple HIG
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: SizedBox(
          width: 72,
          child: ScaleTransition(
            scale: scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    isSelected ? tab.activeIcon : tab.icon,
                    key: ValueKey(isSelected),
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                    letterSpacing: -0.1,
                  ),
                  child: Text(tab.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class for tab metadata
// ─────────────────────────────────────────────────────────────────────────────
class _TabInfo {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabInfo({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
