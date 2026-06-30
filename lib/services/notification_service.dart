import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:tlucalendar/services/log_service.dart';
import 'package:tlucalendar/services/navigation_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tlucalendar/features/schedule/domain/entities/course.dart';
import 'package:tlucalendar/screens/home_shell.dart';
import 'package:tlucalendar/features/exam/data/models/exam_dtos.dart' as Legacy;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _log = LogService();

  bool _initialized = false;

  // Background FCM handler definition must be a top-level function
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    LogService().log(
      'Handling a background message: ${message.messageId}',
      level: LogLevel.info,
    );

    // Check if it's a silent sync request
    if (message.data['action'] == 'check_daily_schedule') {
      LogService().log(
        'Received Silent Sync Request from Server.',
        level: LogLevel.info,
      );
      // Do background DB/API fetching process to sync here
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();

    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      // Set up FCM Background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _setupFcmListeners();
    }

    _initialized = true;
  }

  Future<void> _setupFcmListeners() async {
    // 1. Xin quyền đẩy FCM từ hệ sinh thái Apple (iOS) hoặc Android 13+
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // 2. Lắng nghe lúc app đang MỞ (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _log.log(
        'Nhận thông báo khi App mở: ${message.messageId}',
        level: LogLevel.info,
      );
      if (message.notification != null) {
        showImmediateNotification(
          id: message.hashCode,
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
          payload: message.data['action'],
        );
      }

      // Xử lý nốt Data Message (Silent Push) nếu gửi kèm nhưng app vẫn đang mở
      if (message.data['action'] == 'check_daily_schedule') {
        _log.log(
          'Foreground: Bắt đầu quá trình đồng bộ lại lịch học.',
          level: LogLevel.info,
        );
      }
    });

    // 3. Lắng nghe lúc nhấn vào Push Notification để mở lại app từ khay hệ thống
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _log.log(
        'Nhấn vào thông báo FCM để mở app: ${message.messageId}',
        level: LogLevel.info,
      );
      if (message.data.containsKey('action')) {
        _handlePayloadAction(message.data['action']);
      }
    });

    // 3.5. Lắng nghe khi app hoàn toàn tắt bị ấn để gọi lên Initial
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        _log.log(
          'Khởi chạy qua PushNotification FCM Terminated State: ${message.messageId}',
          level: LogLevel.info,
        );
        // Delay a bit to let the app build its routes fully before pushing
        Future.delayed(const Duration(seconds: 1), () {
          if (message.data.containsKey('action')) {
            _handlePayloadAction(message.data['action']);
          }
        });
      }
    });

    // 4. Tự động subscribe vào Topic all_users để hứng Broadcast
    FirebaseMessaging.instance.subscribeToTopic('all_users');
    _log.log('Đã subscribe vào topic: all_users', level: LogLevel.info);

    // 5. Phân nhóm User theo môi trường cài đặt (APK ngoài hay Play Store)
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installerStore = packageInfo.installerStore;

      if (installerStore == 'com.android.vending') {
        FirebaseMessaging.instance.unsubscribeFromTopic('apk_users');
        FirebaseMessaging.instance.subscribeToTopic('playstore_users');
        _log.log(
          'Đã subscribe vào topic: playstore_users, huỷ apk_users',
          level: LogLevel.info,
        );
      } else {
        FirebaseMessaging.instance.unsubscribeFromTopic(
          'playstore_users',
        );
        FirebaseMessaging.instance.subscribeToTopic('apk_users');
        _log.log(
          'Đã subscribe vào topic: apk_users, huỷ playstore_users',
          level: LogLevel.info,
        );
      }
    } catch (e) {
      _log.log('Lỗi khi đăng ký topic theo store: $e', level: LogLevel.error);
    }
  }

  Future<bool> _requestPermissions() async {
    bool granted = false;

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final result = await androidPlugin.requestNotificationsPermission();
      granted = result ?? false;
    }

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    }

    return granted;
  }

  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final result = await androidPlugin.areNotificationsEnabled();
      return result ?? false;
    }
    return _initialized;
  }

  Future<bool> requestPermissions() async {
    return await _requestPermissions();
  }

  void _onNotificationTapped(NotificationResponse response) {
    _log.log(
      'Nhấn vào Local Notification: ${response.payload}',
      level: LogLevel.info,
    );
    _handlePayloadAction(response.payload);
  }

  void _handlePayloadAction(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      if (payload.contains('exam')) {
        NavigationService.navigateAndRemoveUntil(
          const HomeShell(initialIndex: 2),
        );
      } else if (payload.contains('class')) {
        NavigationService.navigateAndRemoveUntil(
          const HomeShell(initialIndex: 0),
        );
      } else if (payload.contains('open_exam')) {
        NavigationService.navigateAndRemoveUntil(
          const HomeShell(initialIndex: 2),
        );
      } else if (payload.contains('update')) {
        _handleUpdateRouting();
      }
    } catch (e) {
      _log.log('Error handling payload: $e', level: LogLevel.error);
    }
  }

  Future<void> _handleUpdateRouting() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installerStore = packageInfo.installerStore;
      final packageName = packageInfo.packageName;

      _log.log(
        'App Update requested. Installer Store: $installerStore',
        level: LogLevel.info,
      );

      if (installerStore == 'com.android.vending') {
        // Installed via Google Play Store
        final playStoreUrl = Uri.parse('market://details?id=$packageName');
        if (await canLaunchUrl(playStoreUrl)) {
          await launchUrl(playStoreUrl, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // Fallback to Web URL (GitLab Releases or Website)
      final webUrl = Uri.parse(
        'https://gitlab.com/nekkochan0x0007/tlucalendar/-/releases',
      );
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        _log.log('Cannot launch web URL for update.', level: LogLevel.warning);
      }
    } catch (e) {
      _log.log('Error in Update Routing: $e', level: LogLevel.error);
    }
  }

  Future<void> scheduleReminder(DateTime eventDate, String title, String body, String payload, {bool dayBefore = true}) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    DateTime scheduleTime;
    
    if (dayBefore) {
      // Schedule at 20:00 (8:00 PM) the day before
      scheduleTime = DateTime(eventDate.year, eventDate.month, eventDate.day).subtract(const Duration(days: 1)).add(const Duration(hours: 20));
    } else {
      // Schedule exactly 1 hour before
      scheduleTime = eventDate.subtract(const Duration(hours: 1));
    }

    if (scheduleTime.isBefore(now)) return;

    final id = scheduleTime.millisecondsSinceEpoch.remainder(100000);

    await _scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduleTime,
      payload: payload,
    );
    
    _log.log('Scheduled reminder "$title" at $scheduleTime', level: LogLevel.info);
  }

  Future<void> scheduleClassNotifications(
    Course course,
    DateTime classDateTime,
    int weekDay,
    String timeSlot,
  ) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    if (classDateTime.isBefore(now)) return;

    final subjectName = course.courseName;
    final baseId =
        '${course.id}_${weekDay}_${classDateTime.millisecondsSinceEpoch}'
            .hashCode;

    final oneHourBefore = classDateTime.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 1,
        title: 'Sắp đến giờ học!',
        body: 'Còn 1 giờ nữa là đến giờ học môn: $subjectName!',
        scheduledDate: oneHourBefore,
        payload: 'class_${course.id}_1h',
      );
    }

    final thirtyMinBefore = classDateTime.subtract(const Duration(minutes: 30));
    if (thirtyMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 2,
        title: 'Sắp đến giờ học!',
        body: 'Còn 30 phút nữa là đến giờ học môn: $subjectName!',
        scheduledDate: thirtyMinBefore,
        payload: 'class_${course.id}_30m',
      );
    }

    final fifteenMinBefore = classDateTime.subtract(
      const Duration(minutes: 15),
    );
    if (fifteenMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 3,
        title: 'Sắp đến giờ học!',
        body: 'Còn 15 phút nữa là đến giờ học môn: $subjectName!',
        scheduledDate: fifteenMinBefore,
        payload: 'class_${course.id}_15m',
      );
    }
  }

  // Optimized method for Native C++ Notifications
  Future<void> scheduleNativeClassNotification(
    // We use dynamic or import the model, but usually better to import.
    // For now, let's pass fields or use the model if imports allow.
    // Since NotificationService is low level, we might not want to import NativeParser types if it causes cycles?
    // NativeParser is in core, NotificationService in services. Core -> Services? No.
    // usually Services -> Core. So we can import NativeParser.
    dynamic
    model, // using dynamic to avoid import duplication issues if any, or just fields
  ) async {
    if (!_initialized) await initialize();

    final classDateTime = DateTime.fromMillisecondsSinceEpoch(
      model.triggerTime,
    );
    final now = DateTime.now();
    if (classDateTime.isBefore(now)) return;

    final subjectName =
        model.title; // Adjusted: Native model title has "Lịch học: " prefix?
    // C++: "Lịch học: %s"
    // Dart existing: "Sắp đến giờ học môn: $subjectName"
    // We should probably just pass the raw Subject Name from C++ if we want to match exact text?
    // Or just use the C++ title as is.
    // C++ Body: "Phòng: %s | Giờ: %s"

    // Let's use the C++ provided Title/Body directly for the notification content?
    // But the current logic adds "Còn 1 giờ nữa...".
    // If we want exact parity, C++ should return just the data.
    // But C++ returned formatted strings.
    // Let's just use the C++ title/body for the notification "Body" or "Title".

    // Current Native Impl:
    // Title: "Lịch học: Data Structures"
    // Body: "Phòng: B1 | Giờ: 07:00"

    // Desired Notification:
    // Title: "Sắp đến giờ học!"
    // Body: "Còn ... môn Data Structures"

    // Since C++ strings are already formatted, we might just use them.
    // "Lịch học: Data Structures" is a good Title.
    // Body: "Phòng: B1... (Còn 1h)"

    // Let's stick to the C++ strings for simplicity and speed.
    // We can append " - Còn 1h" to the body.

    final baseId = model.id;

    final oneHourBefore = classDateTime.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 1,
        title: model.title,
        body: '${model.body} (Còn 1 giờ)',
        scheduledDate: oneHourBefore,
        payload: 'native_class_${model.id}',
      );
    }

    final thirtyMinBefore = classDateTime.subtract(const Duration(minutes: 30));
    if (thirtyMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 2,
        title: model.title,
        body: '${model.body} (Còn 30 phút)',
        scheduledDate: thirtyMinBefore,
        payload: 'native_class_${model.id}',
      );
    }

    final fifteenMinBefore = classDateTime.subtract(
      const Duration(minutes: 15),
    );
    if (fifteenMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 3,
        title: model.title,
        body: '${model.body} (Còn 15 phút)',
        scheduledDate: fifteenMinBefore,
        payload: 'native_class_${model.id}',
      );
    }
  }

  Future<void> scheduleCourseNoteNotification(
    Course course,
    DateTime classDateTime,
    String noteContent,
  ) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    // Schedule exactly 24 hours before class
    final reminderTime = classDateTime.subtract(const Duration(hours: 24));
    
    if (reminderTime.isBefore(now)) return;

    final baseId = '${course.id}_note_${classDateTime.millisecondsSinceEpoch}'.hashCode;

    await _scheduleNotification(
      id: baseId,
      title: 'Nhắc nhở ngày mai: ${course.courseName}',
      body: noteContent,
      scheduledDate: reminderTime,
      payload: 'class_${course.id}_note',
    );
  }
  
  Future<void> cancelCourseNoteNotification(Course course, DateTime classDateTime) async {
    final baseId = '${course.id}_note_${classDateTime.millisecondsSinceEpoch}'.hashCode;
    await cancelNotification(baseId);
  }

  Future<void> scheduleExamNotifications(
    Legacy.StudentExamRoom examRoom,
    DateTime examDateTime,
  ) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    if (examDateTime.isBefore(now)) return;

    final subjectName = examRoom.subjectName;
    final examCode = examRoom.examCode ?? '';
    final baseId =
        '${examRoom.id}_${examDateTime.millisecondsSinceEpoch}'.hashCode;

    final oneHourBefore = examDateTime.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 1,
        title: 'Sắp đến giờ thi!',
        body:
            'Còn 1 giờ nữa là đến giờ thi môn: $subjectName${examCode.isNotEmpty ? ' ($examCode)' : ''}!',
        scheduledDate: oneHourBefore,
        payload: 'exam_${examRoom.id}_1h',
      );
    }

    final thirtyMinBefore = examDateTime.subtract(const Duration(minutes: 30));
    if (thirtyMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 2,
        title: 'Sắp đến giờ thi!',
        body:
            'Còn 30 phút nữa là đến giờ thi môn: $subjectName${examCode.isNotEmpty ? ' ($examCode)' : ''}!',
        scheduledDate: thirtyMinBefore,
        payload: 'exam_${examRoom.id}_30m',
      );
    }

    final fifteenMinBefore = examDateTime.subtract(const Duration(minutes: 15));
    if (fifteenMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 3,
        title: 'Sắp đến giờ thi!',
        body:
            'Còn 15 phút nữa là đến giờ thi môn: $subjectName${examCode.isNotEmpty ? ' ($examCode)' : ''}!',
        scheduledDate: fifteenMinBefore,
        payload: 'exam_${examRoom.id}_15m',
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final now = DateTime.now();
    final maxYear = now.year + 10;

    if (scheduledDate.year > maxYear || scheduledDate.year < 2020) {
      _log.log(
        'Invalid scheduled date: $scheduledDate',
        level: LogLevel.warning,
      );
      return;
    }

    if (scheduledDate.isBefore(now)) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'class_exam_reminders',
      'Nhắc nhở lịch học và lịch thi',
      channelDescription: 'Thông báo nhắc nhở trước giờ học và giờ thi',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzScheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'class_exam_reminders',
      'Nhắc nhở lịch học và lịch thi',
      channelDescription: 'Thông báo nhắc nhở trước giờ học và giờ thi',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
