import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:url_launcher/url_launcher.dart';
import 'package:forui/forui.dart';

import 'package:tlucalendar/providers/theme_provider.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/schedule_provider.dart';
import 'package:tlucalendar/providers/settings_provider.dart';
import 'package:tlucalendar/screens/logs_screen.dart';
import 'package:tlucalendar/utils/error_logger.dart';
import 'package:tlucalendar/services/backup_service.dart';
import 'package:tlucalendar/screens/app_initializer.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _versionTapCount = 0;
  bool _developerModeEnabled = false;

  void _handleVersionTap() {
    setState(() {
      _versionTapCount++;
      if (_versionTapCount >= 5 && !_developerModeEnabled) {
        _developerModeEnabled = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Developer Mode Enabled')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            FHeader(
              title: const Text('Cài đặt'),
            ),
            // Profile Header
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
                  return const SizedBox.shrink();
                }
                final user = authProvider.currentUser!;
                final initials = user.fullName.trim().split(' ')
                  .where((p) => p.isNotEmpty).map((p) => p[0].toUpperCase())
                  .take(2).join();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Theme Settings
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: FTileGroup(
                    label: const Text('Giao diện'),
                    children: [
                      FTile(
                        prefix: const Icon(FLucideIcons.moon),
                        title: const Text('Chế độ tối (Dark Mode)'),
                        suffix: FSwitch(
                          value: themeProvider.isDarkMode,
                          onChange: (val) => themeProvider.toggleTheme(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Notifications
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: FTileGroup(
                    label: const Text('Thông báo'),
                    children: [
                      FTile(
                        prefix: const Icon(FLucideIcons.bell),
                        title: const Text('Nhắc lịch hằng ngày'),
                        subtitle: const Text('Nhắc lịch học/thi vào buổi sáng'),
                        suffix: FSwitch(
                          value: settings.dailyNotificationEnabled,
                          onChange: (val) => settings.setDailyNotification(val),
                        ),
                      ),
                      if (settings.dailyNotificationEnabled)
                        FTile(
                          prefix: const Icon(FLucideIcons.clock),
                          title: const Text('Thời gian thông báo'),
                          onPress: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: settings.dailyNotificationTime,
                            );
                            if (time != null) settings.setDailyNotificationTime(time);
                          },
                          suffix: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              settings.dailyNotificationTime.format(context),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      FTile(
                        prefix: const Icon(FLucideIcons.refreshCcw),
                        title: const Text('Tự động đồng bộ'),
                        subtitle: const Text('Đồng bộ dữ liệu nền (mỗi 6h)'),
                        suffix: FSwitch(
                          value: settings.autoRefreshEnabled,
                          onChange: (val) => settings.setAutoRefresh(val),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Data
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FTileGroup(
                label: const Text('Dữ liệu'),
                children: [
                  FTile(
                    prefix: const Icon(FLucideIcons.uploadCloud),
                    title: const Text('Sao lưu dữ liệu'),
                    subtitle: const Text('Xuất file database an toàn'),
                    onPress: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await BackupService.exportDatabase();
                      if (result != null) {
                        messenger.showSnackBar(SnackBar(content: Text(result)));
                      }
                    },
                  ),
                  FTile(
                    prefix: const Icon(FLucideIcons.downloadCloud),
                    title: const Text('Khôi phục dữ liệu'),
                    subtitle: const Text('Ghi đè dữ liệu từ file sao lưu'),
                    onPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Khôi phục dữ liệu?'),
                          content: const Text('Hành động này sẽ XÓA TOÀN BỘ dữ liệu hiện tại và thay thế bằng file sao lưu. Bạn có chắc chắn không?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                            FButton(
                              variant: FButtonVariant.primary,
                              onPress: () async {
                                Navigator.pop(context);
                                final error = await BackupService.importDatabase();
                                if (error == null) {
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (context) => const AppInitializer()),
                                      (route) => false,
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                                  }
                                }
                              },
                              child: const Text('Khôi phục'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // About
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FTileGroup(
                label: const Text('Về ứng dụng'),
                children: [
                  FTile(
                    prefix: const Icon(FLucideIcons.bug),
                    title: const Text('Báo lỗi'),
                    subtitle: const Text('Gửi email kèm thông tin thiết bị'),
                    onPress: () => _sendBugReport(context),
                  ),
                  if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
                    FTile(
                      prefix: const Icon(FLucideIcons.info),
                      title: const Text('Thông báo bên thứ ba'),
                      subtitle: const Text('Bản quyền mã nguồn mở'),
                      onPress: () => _viewThirdPartyNotices(context),
                    ),
                  if (_developerModeEnabled)
                    FTile(
                      prefix: const Icon(FLucideIcons.terminal),
                      title: const Text('System Logs (Dev)'),
                      subtitle: const Text('Xem nhật ký hệ thống nội bộ'),
                      onPress: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LogsScreen())),
                      suffix: const Icon(FLucideIcons.chevronRight, size: 20),
                    ),
                ],
              ),
            ),

            // App Version Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: GestureDetector(
                onTap: _handleVersionTap,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    Text(
                      'TLU Calendar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phiên bản 2026.07.01',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bởi Nguyen Duy Thanh & Dang Quang Hien (Miho)',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            // Logout
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (!authProvider.isLoggedIn) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FButton(
                      variant: FButtonVariant.destructive,
                      onPress: () {
                        authProvider.logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const AppInitializer()),
                          (route) => false,
                        );
                      },
                      child: const Text('Đăng xuất'),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendBugReport(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);

    String appName = 'TLU Calendar';
    String appVersion = '2026.03.23';
    try {
      final pkg = await PackageInfo.fromPlatform();
      appName = pkg.appName;
      appVersion = '${pkg.version}+${pkg.buildNumber}';
    } catch (e) {
      // ignore
    }

    final deviceInfo = DeviceInfoPlugin();
    String deviceDetails = '';
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceDetails = 'Android ${info.version.release} - ${info.brand} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceDetails = 'iOS ${info.systemVersion} - ${info.name} ${info.model}';
      } else {
        deviceDetails = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      }
    } catch (e) {
      deviceDetails = 'Unknown device info: $e';
    }

    final userId = authProvider.isLoggedIn ? (authProvider.currentUser?.studentId ?? 'unknown_user') : 'not_logged_in';
    final userName = authProvider.isLoggedIn ? (authProvider.currentUser?.fullName ?? 'unknown') : 'not_logged_in';
    final selectedSemester = scheduleProvider.selectedSemester?.semesterName ?? 'unknown';

    final errorLogger = ErrorLogger();
    final errorLogs = errorLogger.getFormattedErrors();
    final errorCount = errorLogger.getRecentErrors().length;

    final subject = 'TLU Calendar Bug Report';

    final body = StringBuffer();
    body.writeln('App: $appName');
    body.writeln('Version: $appVersion');
    body.writeln('Device: $deviceDetails');
    body.writeln('User: $userName ($userId)');
    body.writeln('Selected semester: $selectedSemester');
    body.writeln('Errors logged this session: $errorCount');
    body.writeln('\n--- INSTRUCTIONS ---');
    body.writeln('Please describe the issue below:');
    body.writeln('\n\n\n');
    body.writeln('\n--- DEBUG INFO ---');
    body.writeln('\n=== ERROR HISTORY ===');
    body.writeln(errorLogs);

    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body.toString());
    final mailto = 'mailto:thanhdz167@gmail.com?subject=$encodedSubject&body=$encodedBody';
    final uri = Uri.parse(mailto);

    try {
      final success = await launchUrl(uri);
      if (!context.mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở ứng dụng email')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi mở email: $e')));
    }
  }

  static const MethodChannel _navigationChannel = MethodChannel('com.nekkochan.tlucalendar/navigation');

  Future<void> _viewThirdPartyNotices(BuildContext context) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final result = await _navigationChannel.invokeMethod('openLicenseActivity');
        if (result != true) {
          throw Exception('Failed to open license activity');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể mở thông báo bên thứ ba: $e')));
        }
      }
    }
  }
}
