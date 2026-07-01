import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:url_launcher/url_launcher.dart';
import 'package:forui/forui.dart';

import 'package:tlucalendar/providers/theme_provider.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/schedule_provider.dart';
import 'package:tlucalendar/providers/settings_provider.dart';
import 'package:tlucalendar/screens/logs_screen.dart';
import 'package:tlucalendar/utils/error_logger.dart';
import 'package:tlucalendar/services/backup_service.dart';
import 'package:tlucalendar/services/update_service.dart';
import 'package:tlucalendar/screens/app_initializer.dart';
import 'package:tlucalendar/utils/semester_parser.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _versionTapCount = 0;
  bool _developerModeEnabled = false;
  bool _isCheckingUpdate = false;
  UpdateCheckResult? _updateCheckResult;
  String? _updateCheckError;
  String? _appVersionLabel;
  bool _isCheckingNetwork = false;
  String? _networkStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppVersion();
      _checkForUpdates(silent: true);
    });
  }

  void _handleVersionTap() {
    setState(() {
      _versionTapCount++;
      if (_versionTapCount >= 5 && !_developerModeEnabled) {
        _developerModeEnabled = true;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Developer Mode Enabled')));
      }
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersionLabel = packageInfo.version;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appVersionLabel = 'không xác định';
      });
    }
  }

  Future<void> _checkForUpdates({bool silent = false}) async {
    if (_isCheckingUpdate) return;

    setState(() {
      _isCheckingUpdate = true;
      _updateCheckError = null;
    });

    try {
      final result = await UpdateService.checkLatestRelease();
      if (!mounted) return;
      setState(() {
        _updateCheckResult = result;
      });

      if (!silent && !result.hasUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đang dùng phiên bản mới nhất')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _updateCheckError = e.toString().replaceAll('Exception: ', '');
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kiểm tra cập nhật: $_updateCheckError'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  Future<void> _openLatestRelease() async {
    final url =
        _updateCheckResult?.releaseUrl ??
        'https://github.com/Miho1254/my-tlucalendar/releases/latest';
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở trang release')),
      );
    }
  }

  Future<void> _checkNetworkStatus() async {
    if (_isCheckingNetwork) return;

    setState(() {
      _isCheckingNetwork = true;
      _networkStatus = null;
    });

    try {
      // Step 1: Check internet connectivity
      final internetCheck = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      if (internetCheck.statusCode != 200) {
        throw Exception('no_internet');
      }

      // Step 2: Check school API
      final apiCheck = await http
          .get(Uri.parse('https://tlu-proxy-node.vercel.app'))
          .timeout(const Duration(seconds: 10));

      if (apiCheck.statusCode == 200) {
        setState(() => _networkStatus = 'ok');
      } else {
        throw Exception('api_down');
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('no_internet') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        setState(() => _networkStatus = 'no_internet');
      } else {
        setState(() => _networkStatus = 'api_down');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingNetwork = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            FHeader(title: const Text('Cài đặt')),
            // Profile Header
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (!authProvider.isLoggedIn ||
                    authProvider.currentUser == null) {
                  return const SizedBox.shrink();
                }
                final user = authProvider.currentUser!;
                final initials = user.fullName
                    .trim()
                    .split(' ')
                    .where((p) => p.isNotEmpty)
                    .map((p) => p[0].toUpperCase())
                    .take(2)
                    .join();

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
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                            if (time != null)
                              settings.setDailyNotificationTime(time);
                          },
                          suffix: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              settings.dailyNotificationTime.format(context),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
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
                          content: const Text(
                            'Hành động này sẽ XÓA TOÀN BỘ dữ liệu hiện tại và thay thế bằng file sao lưu. Bạn có chắc chắn không?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy'),
                            ),
                            FButton(
                              variant: FButtonVariant.primary,
                              onPress: () async {
                                Navigator.pop(context);
                                final error =
                                    await BackupService.importDatabase();
                                if (error == null) {
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AppInitializer(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error)),
                                    );
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
                    prefix: _isCheckingUpdate
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _updateCheckResult?.hasUpdate == true
                                ? FLucideIcons.download
                                : FLucideIcons.refreshCw,
                          ),
                    title: Text(
                      _updateCheckResult?.hasUpdate == true
                          ? 'Có bản cập nhật mới'
                          : 'Kiểm tra cập nhật',
                    ),
                    subtitle: Text(_updateSubtitle),
                    suffix: _updateCheckResult?.hasUpdate == true
                        ? FBadge(
                            child: Text(
                              'v${_updateCheckResult!.latestVersion}',
                            ),
                          )
                        : const Icon(FLucideIcons.chevronRight, size: 20),
                    onPress: () {
                      if (_updateCheckResult?.hasUpdate == true) {
                        _openLatestRelease();
                      } else {
                        _checkForUpdates();
                      }
                    },
                  ),
                  FTile(
                    prefix: _isCheckingNetwork
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _networkStatus == 'ok'
                                ? FLucideIcons.checkCircle
                                : _networkStatus == 'no_internet'
                                    ? FLucideIcons.wifiOff
                                    : FLucideIcons.serverOff,
                          ),
                    title: const Text('Kiểm tra kết nối'),
                    subtitle: Text(_networkStatusText),
                    onPress: _checkNetworkStatus,
                  ),
                  FTile(
                    prefix: const Icon(FLucideIcons.bug),
                    title: const Text('Báo lỗi'),
                    subtitle: const Text('Gửi email kèm thông tin thiết bị'),
                    onPress: () => _sendBugReport(context),
                  ),
                  if (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS)
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
                      onPress: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LogsScreen(),
                        ),
                      ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phiên bản ${_appVersionLabel ?? 'đang tải...'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bởi Nguyen Duy Thanh & Dang Quang Hien (Miho)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FButton(
                        variant: FButtonVariant.destructive,
                        onPress: () {
                          HapticFeedback.mediumImpact();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Đăng xuất?'),
                              content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    authProvider.logout();
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => const AppInitializer(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  child: const Text('Đăng xuất'),
                                ),
                              ],
                            ),
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
    final scheduleProvider = Provider.of<ScheduleProvider>(
      context,
      listen: false,
    );

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
        deviceDetails =
            'Android ${info.version.release} - ${info.brand} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceDetails =
            'iOS ${info.systemVersion} - ${info.name} ${info.model}';
      } else {
        deviceDetails =
            '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      }
    } catch (e) {
      deviceDetails = 'Unknown device info: $e';
    }

    final userId = authProvider.isLoggedIn
        ? (authProvider.currentUser?.studentId ?? 'unknown_user')
        : 'not_logged_in';
    final userName = authProvider.isLoggedIn
        ? (authProvider.currentUser?.fullName ?? 'unknown')
        : 'not_logged_in';
    final selectedSemester =
        scheduleProvider.selectedSemester?.semesterName.toReadableSemester ??
        'unknown';

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
    final mailto =
        'mailto:thanhdz167@gmail.com?subject=$encodedSubject&body=$encodedBody';
    final uri = Uri.parse(mailto);

    try {
      final success = await launchUrl(uri);
      if (!context.mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng email')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi mở email: $e')));
    }
  }

  String get _updateSubtitle {
    if (_isCheckingUpdate) return 'Đang kiểm tra GitHub Releases...';
    if (_updateCheckError != null) return _updateCheckError!;

    final result = _updateCheckResult;
    if (result == null) return 'Tự kiểm tra bản mới từ GitHub Releases';
    if (result.hasUpdate) {
      return 'Đang dùng v${result.currentVersion}, mới nhất v${result.latestVersion}';
    }
    return 'Phiên bản hiện tại: v${result.currentVersion}';
  }

  String get _networkStatusText {
    if (_isCheckingNetwork) return 'Đang kiểm tra...';
    switch (_networkStatus) {
      case 'ok':
        return 'Mọi thứ hoạt động bình thường';
      case 'no_internet':
        return 'Không có kết nối mạng';
      case 'api_down':
        return 'Server trường đang gặp sự cố';
      default:
        return 'Nhấn để kiểm tra kết nối';
    }
  }

  static const MethodChannel _navigationChannel = MethodChannel(
    'com.nekkochan.tlucalendar/navigation',
  );

  Future<void> _viewThirdPartyNotices(BuildContext context) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final result = await _navigationChannel.invokeMethod(
          'openLicenseActivity',
        );
        if (result != true) {
          throw Exception('Failed to open license activity');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể mở thông báo bên thứ ba: $e')),
          );
        }
      }
    }
  }
}
