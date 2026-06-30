import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:forui/forui.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:tlucalendar/providers/theme_provider.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/schedule_provider.dart';
import 'package:tlucalendar/providers/exam_provider.dart';
import 'package:tlucalendar/providers/settings_provider.dart';
import 'package:tlucalendar/providers/registration_provider.dart';
import 'package:tlucalendar/providers/grade_provider.dart';

import 'package:tlucalendar/theme/app_theme.dart';
import 'package:tlucalendar/screens/app_initializer.dart';
import 'package:tlucalendar/injection_container.dart' as di;
import 'package:tlucalendar/services/navigation_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:tlucalendar/services/notification_service.dart';
import 'package:device_preview/device_preview.dart';

import 'package:tlucalendar/services/daily_notification_service.dart';
import 'package:tlucalendar/services/auto_refresh_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar: transparent, icons white for True Dark / OLED Black theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase First
  if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    try {
      await Firebase.initializeApp();
      
      // Capture Flutter Errors (Layout/Render) with Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // Capture Async/Platform Errors with Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true; // Prevent app crash
      };
    } catch (e) {
      debugPrint('Lỗi khởi tạo Firebase: $e');
    }
  } else {
    debugPrint('Bypass Firebase trên môi trường Linux/Windows Desktop.');
  }

  // Enable Edge-to-Edge for Transparent Status/Nav Bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Service Locator (Dependency Injection)
  await di.init();

  // Initialize date formatting
  await initializeDateFormatting('vi', null);

  // Initialize timezone database
  tz.initializeTimeZones();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    // Initialize Daily Notification Service
    await DailyNotificationService.initialize();
    await DailyNotificationService.requestPermissions();

    // Load saved settings for notification time
    final prefs = await SharedPreferences.getInstance();
    final notifEnabled = prefs.getBool('setting_daily_notif') ?? true;
    final notifHour = prefs.getInt('setting_daily_notif_hour') ?? 7;
    final notifMinute = prefs.getInt('setting_daily_notif_minute') ?? 0;

    if (notifEnabled) {
      await DailyNotificationService.scheduleDailyCheck(
        hour: notifHour,
        minute: notifMinute,
      );
    } else {
      // Ensure cancellation if disabled
      await DailyNotificationService.cancelDailyCheck();
    }

    // Initialize Notification Service
    final notificationService = di.sl<NotificationService>();
    await notificationService.initialize();

    // Initialize Auto Refresh Service
    await AutoRefreshService.initialize();
  } else {
    debugPrint('Bypass Notification & Background Services trên Linux/Windows.');
  }

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => di.sl<ThemeProvider>()..init()),
          ChangeNotifierProvider(create: (_) => di.sl<AuthProvider>()),
          ChangeNotifierProxyProvider<AuthProvider, ScheduleProvider>(
            create: (_) => di.sl<ScheduleProvider>(),
            update: (_, auth, schedule) => schedule!..setAuthProvider(auth),
          ),
          ChangeNotifierProxyProvider<AuthProvider, ExamProvider>(
            create: (_) => di.sl<ExamProvider>(),
            update: (_, auth, exam) => exam!..setAuthProvider(auth),
          ),
          ChangeNotifierProvider(
            create: (_) => di.sl<SettingsProvider>()..init(),
          ),
          ChangeNotifierProvider(create: (_) => di.sl<GradeProvider>()),
          ChangeNotifierProxyProvider<AuthProvider, RegistrationProvider>(
            create: (_) => di.sl<RegistrationProvider>(),
            update: (_, auth, registration) =>
                registration!..setAuthProvider(auth),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          title: 'TLU Calendar',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          locale: const Locale('vi', 'VN'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('vi', 'VN'),
            Locale('en', 'US'),
          ],
          builder: (context, child) {
            child = DevicePreview.appBuilder(context, child);
            final isDark = themeProvider.themeMode == ThemeMode.dark ||
                (themeProvider.themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark);
            
            return FTheme(
              data: isDark ? AppTheme.darkForui : AppTheme.lightForui,
              child: FToaster(child: child),
            );
          },
          home: const AppInitializer(),
        );
      },
    );
  }
}
