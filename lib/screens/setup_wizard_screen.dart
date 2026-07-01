import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/exam_provider.dart';
import 'package:tlucalendar/providers/schedule_provider.dart';
import 'package:tlucalendar/providers/theme_provider.dart';
import 'package:tlucalendar/providers/settings_provider.dart';
import 'package:tlucalendar/screens/home_shell.dart';

class SetupWizardScreen extends StatefulWidget {
  final bool isReauth;
  final VoidCallback? onFinished;

  const SetupWizardScreen({super.key, this.isReauth = false, this.onFinished});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Login controllers
  late TextEditingController _studentCodeController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _studentCodeController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _studentCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishSetup();
    }
  }

  void _finishSetup() {
    if (widget.isReauth) {
      Navigator.of(context).pop();
    } else if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeShell()),
      );
    }
  }

  bool _isValidStudentCode(String code) {
    final codeRegex = RegExp(r'^\d{8,10}$');
    return codeRegex.hasMatch(code);
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);

    final studentCode = _studentCodeController.text.trim();
    final password = _passwordController.text;

    if (studentCode.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã sinh viên và mật khẩu');
      return;
    }

    if (!_isValidStudentCode(studentCode)) {
      setState(() => _errorMessage = 'Mã sinh viên không hợp lệ (8-10 chữ số)');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    setState(() => _isLoading = true);

    if (!mounted) return;

    try {
      final success = await context.read<AuthProvider>().login(
        studentCode,
        password,
      );

      if (!success) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage =
              context.read<AuthProvider>().errorMessage ?? 'Đăng nhập thất bại';
        });
        return;
      }

      if (!mounted) return;

      final accessToken = context.read<AuthProvider>().accessToken;
      if (accessToken != null) {
        final scheduleProvider = context.read<ScheduleProvider>();
        final examProvider = context.read<ExamProvider>();
        await scheduleProvider.init(accessToken);
        await examProvider.init(accessToken);
      }

      if (!mounted) return;

      // Next step
      _nextPage();
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = _currentPage >= index;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildLoginStep(),
                  _buildThemeStep(),
                  _buildNotificationsStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginStep() {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Icon(
            FLucideIcons.graduationCap,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Đăng nhập sinh viên',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sử dụng tài khoản Quản lý đào tạo (CMC) để đồng bộ lịch học & lịch thi',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    FLucideIcons.alertCircle,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          FTextField(
            control: FTextFieldControl.managed(
              controller: _studentCodeController,
            ),
            hint: 'Mã sinh viên',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          FTextField.password(
            control: FTextFieldControl.managed(controller: _passwordController),
            hint: 'Mật khẩu',
          ),
          const SizedBox(height: 32),

          FButton(
            onPress: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Text('Tiếp tục'),
          ),

          if (_isLoading) ...[
            const SizedBox(height: 24),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: authProvider.loginProgressPercent,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authProvider.loginProgress.isEmpty
                          ? 'Đang kết nối...'
                          : authProvider.loginProgress,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeStep() {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Icon(
            FLucideIcons.palette,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Chọn giao diện',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Giao diện tối giúp tiết kiệm pin và thân thiện với mắt hơn vào ban đêm.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          FTileGroup(
            children: [
              FTile(
                title: const Text('Giao diện sáng'),
                prefix: const Icon(FLucideIcons.sun),
                suffix: FRadio(
                  value: !isDark,
                  onChange: (_) => themeProvider.toggleTheme(),
                ),
                onPress: () {
                  if (isDark) themeProvider.toggleTheme();
                },
              ),
              FTile(
                title: const Text('Giao diện tối'),
                prefix: const Icon(FLucideIcons.moon),
                suffix: FRadio(
                  value: isDark,
                  onChange: (_) => themeProvider.toggleTheme(),
                ),
                onPress: () {
                  if (!isDark) themeProvider.toggleTheme();
                },
              ),
            ],
          ),

          const Spacer(),
          FButton(onPress: _nextPage, child: const Text('Tiếp tục')),
        ],
      ),
    );
  }

  Widget _buildNotificationsStep() {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Icon(FLucideIcons.bellRing, size: 64, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Cài đặt thông báo',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Nhận thông báo nhắc lịch học, lịch thi hằng ngày để không bỏ lỡ buổi học nào.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          FTileGroup(
            children: [
              FTile(
                title: const Text('Thông báo hằng ngày'),
                subtitle: const Text('Nhắc lịch học, thi vào buổi sáng'),
                prefix: const Icon(FLucideIcons.bell),
                suffix: FSwitch(
                  value: settingsProvider.dailyNotificationEnabled,
                  onChange: (val) => settingsProvider.setDailyNotification(val),
                ),
              ),
              if (settingsProvider.dailyNotificationEnabled)
                FTile(
                  title: const Text('Thời gian nhắc'),
                  prefix: const Icon(FLucideIcons.clock),
                  onPress: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: settingsProvider.dailyNotificationTime,
                    );
                    if (time != null) {
                      settingsProvider.setDailyNotificationTime(time);
                    }
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
                      settingsProvider.dailyNotificationTime.format(context),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FTileGroup(
            children: [
              FTile(
                title: const Text('Tự động đồng bộ'),
                subtitle: const Text('Cập nhật dữ liệu ngầm mỗi 6 tiếng'),
                prefix: const Icon(FLucideIcons.refreshCcw),
                suffix: FSwitch(
                  value: settingsProvider.autoRefreshEnabled,
                  onChange: (val) => settingsProvider.setAutoRefresh(val),
                ),
              ),
            ],
          ),

          const Spacer(),
          FButton(onPress: _finishSetup, child: const Text('Hoàn tất')),
        ],
      ),
    );
  }
}
