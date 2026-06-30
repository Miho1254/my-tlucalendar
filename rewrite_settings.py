import re

with open('lib/screens/settings_screen.dart', 'r') as f:
    content = f.read()

# We'll extract everything before Widget build
pre_build = content[:content.find('  @override\n  Widget build(BuildContext context) {')]

# We'll extract everything after the end of build
post_build_idx = content.find('  static Future<void> _sendBugReport(BuildContext context) async {')
post_build = content[post_build_idx:]

new_build = """  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          elevation: 0,
          title: Text(
            'Cài đặt',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SliverToBoxAdapter(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
                return const SizedBox.shrink();
              }
              final user = authProvider.currentUser!;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
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
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.studentId} • ${user.email}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return _buildSectionContainer(
                context,
                'Tài khoản',
                [
                  if (authProvider.isLoggedIn && authProvider.currentUser != null) ...[
                    _buildSettingsItem(
                      context,
                      icon: Icons.check_circle_outline,
                      title: 'Đã đăng nhập',
                      subtitle: authProvider.currentUser!.studentId,
                      trailing: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          key: const ValueKey('logoutButton'),
                          onPressed: () {
                            authProvider.logout();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã đăng xuất'), duration: Duration(seconds: 2)),
                            );
                          },
                          child: const Text('Đăng xuất'),
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildSettingsItem(
                      context,
                      icon: Icons.lock_outlined,
                      title: 'Chưa đăng nhập',
                      subtitle: 'Nhấp để đăng nhập tài khoản',
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('settingsLoginButton'),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
                          },
                          child: const Text('Đăng nhập'),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return _buildSectionContainer(
                context,
                'Thông báo',
                [
                  _buildSettingsItem(
                    context,
                    icon: Icons.sync,
                    title: 'Tự động làm mới',
                    subtitle: 'Đồng bộ dữ liệu nền (mỗi 6h)',
                    trailing: Switch(
                      key: const ValueKey('autoRefreshSwitch'),
                      value: settings.autoRefreshEnabled,
                      onChanged: (value) => settings.setAutoRefresh(value),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context,
                    icon: Icons.notifications_active_outlined,
                    title: 'Thông báo hàng ngày',
                    subtitle: 'Nhắc lịch học/thi sáng sớm',
                    trailing: Switch(
                      key: const ValueKey('dailyNotificationSwitch'),
                      value: settings.dailyNotificationEnabled,
                      onChanged: (value) => settings.setDailyNotification(value),
                    ),
                  ),
                  if (settings.dailyNotificationEnabled) ...[
                    const Divider(height: 1),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: settings.dailyNotificationTime,
                        );
                        if (picked != null) settings.setDailyNotificationTime(picked);
                      },
                      child: _buildSettingsItem(
                        context,
                        icon: Icons.access_time,
                        title: 'Thời gian thông báo',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            settings.dailyNotificationTime.format(context),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return _buildSectionContainer(
                context,
                'Hiển thị',
                [
                  _buildSettingsItem(
                    context,
                    icon: themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    title: themeProvider.isDarkMode ? 'Chế độ tối' : 'Chế độ sáng',
                    trailing: Switch(
                      key: const ValueKey('darkModeSwitch'),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) => themeProvider.toggleTheme(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: _buildSectionContainer(
            context,
            'Sao lưu và khôi phục',
            [
              InkWell(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final result = await BackupService.exportDatabase();
                  if (result != null) {
                    final isError = result.startsWith('Lỗi') || result.startsWith('Không tìm');
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(result),
                        backgroundColor: isError ? Colors.red : null,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                child: _buildSettingsItem(
                  context,
                  icon: Icons.cloud_upload_outlined,
                  title: 'Sao lưu dữ liệu',
                  subtitle: 'Xuất file database để lưu trữ',
                ),
              ),
              const Divider(height: 1),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Khôi phục dữ liệu?'),
                      content: const Text('Hành động này sẽ XÓA TOÀN BỘ dữ liệu hiện tại và thay thế bằng file sao lưu. Bạn có chắc chắn không?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                        FilledButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final error = await BackupService.importDatabase();
                            if (error == null) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Khôi phục thành công! Đang khởi động lại...'), duration: Duration(seconds: 2)),
                              );
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => const AppInitializer()),
                                  (route) => false,
                                );
                              }
                            } else {
                              messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                            }
                          },
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Khôi phục'),
                        ),
                      ],
                    ),
                  );
                },
                child: _buildSettingsItem(
                  context,
                  icon: Icons.cloud_download_outlined,
                  title: 'Khôi phục dữ liệu',
                  subtitle: 'Nhập file database đã lưu',
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: _buildSectionContainer(
            context,
            'Tính năng khác',
            [
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegistrationPeriodSelectionScreen())),
                child: _buildSettingsItem(
                  context,
                  icon: Icons.app_registration_rounded,
                  title: 'Đăng ký học',
                  subtitle: 'Đăng ký môn học, hủy học phần',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                    child: const Text('HOT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const Divider(height: 1),
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GradeScreen())),
                child: _buildSettingsItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Tra cứu điểm',
                  subtitle: 'Xem điểm tổng hợp, điểm thành phần',
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: _buildSectionContainer(
            context,
            'Hệ thống',
            [
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LogsScreen())),
                child: _buildSettingsItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'System Logs',
                  subtitle: 'Xem nhật ký hệ thống',
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
              ),
              const Divider(height: 1),
              InkWell(
                onTap: () async => await _sendBugReport(context),
                child: _buildSettingsItem(
                  context,
                  icon: Icons.bug_report_outlined,
                  title: 'Báo lỗi',
                  subtitle: 'Gửi báo cáo lỗi kèm thông tin thiết bị',
                ),
              ),
              if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) ...[
                const Divider(height: 1),
                InkWell(
                  onTap: () async => await _viewThirdPartyNotices(context),
                  child: _buildSettingsItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'Thông báo bên thứ ba',
                    subtitle: 'Thông báo giấy phép của bên thứ ba',
                  ),
                ),
              ],
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
            child: Column(
              children: [
                Text('TLU Calendar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 4),
                Text('Phiên bản 2026.03.23', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text('Bởi Nguyen Duy Thanh', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionContainer(BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required IconData icon, required String title, String? subtitle, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing,
          ],
        ],
      ),
    );
  }
"""

with open('lib/screens/settings_screen.dart', 'w') as f:
    f.write(pre_build + new_build + post_build)
