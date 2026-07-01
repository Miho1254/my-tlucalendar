import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/schedule_provider.dart';
import 'package:tlucalendar/providers/exam_provider.dart';
import 'package:tlucalendar/providers/grade_provider.dart';
import 'package:tlucalendar/screens/home_shell.dart';
import 'package:tlucalendar/screens/setup_wizard_screen.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  bool _showSetupWizard = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.init();

    if (!mounted) return;

    if (authProvider.isLoggedIn && authProvider.accessToken != null) {
      final token = authProvider.accessToken!;
      final scheduleProvider = Provider.of<ScheduleProvider>(
        context,
        listen: false,
      );
      final examProvider = Provider.of<ExamProvider>(context, listen: false);
      final gradeProvider = Provider.of<GradeProvider>(context, listen: false);

      // Fire-and-forget: prefetch all data in parallel, don't block UI
      // Only fetch if data not already in memory (e.g. hot restart)
      if (scheduleProvider.courses.isEmpty) {
        scheduleProvider.init(token);
      }
      if (examProvider.registerPeriods.isEmpty) {
        examProvider.init(token);
      }
      if (gradeProvider.analyticsResult == null && !gradeProvider.isLoading) {
        gradeProvider.fetchGrades(token);
      }
    } else {
      _showSetupWizard = true;
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Splash Screen
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authProvider = Provider.of<AuthProvider>(context);
    if (_showSetupWizard) {
      return SetupWizardScreen(
        onFinished: () {
          setState(() {
            _showSetupWizard = false;
          });
        },
      );
    }

    if (!authProvider.isLoggedIn) {
      return SetupWizardScreen(
        onFinished: () {
          setState(() {
            _showSetupWizard = false;
          });
        },
      );
    }

    return const HomeShell();
  }
}
