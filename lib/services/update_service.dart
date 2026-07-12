import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateCheckResult {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String releaseName;
  final bool hasUpdate;
  final DateTime? publishedAt;

  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseName,
    required this.hasUpdate,
    this.publishedAt,
  });
}

class UpdateService {
  static const _latestReleaseApi =
      'https://api.github.com/repos/Miho1254/my-tlucalendar/releases/latest';
  static const _prefLastCheckDate = 'update_last_check_date';
  static const _prefDismissedVersion = 'update_dismissed_version';

  /// Check once per day. Returns null if skipped (checked <24h ago).
  static Future<UpdateCheckResult?> checkDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckRaw = prefs.getString(_prefLastCheckDate);

    if (lastCheckRaw != null) {
      final lastCheck = DateTime.tryParse(lastCheckRaw);
      if (lastCheck != null) {
        final hoursSince = DateTime.now().difference(lastCheck).inHours;
        if (hoursSince < 24) return null;
      }
    }

    final result = await checkLatestRelease();
    await prefs.setString(_prefLastCheckDate, DateTime.now().toIso8601String());
    return result;
  }

  /// Has the user dismissed this specific version?
  static Future<bool> isDismissed(String version) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefDismissedVersion) == version;
  }

  /// Mark a version as dismissed.
  static Future<void> dismiss(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDismissedVersion, version);
  }

  static Future<UpdateCheckResult> checkLatestRelease() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final response = await http.get(
      Uri.parse(_latestReleaseApi),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('GitHub trả về HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = data['tag_name'] as String? ?? '';
    final releaseUrl =
        data['html_url'] as String? ??
        'https://github.com/Miho1254/my-tlucalendar/releases/latest';
    final releaseName = data['name'] as String? ?? tagName;
    final publishedAtRaw = data['published_at'] as String?;
    final latestVersion = _normalizeVersion(tagName);

    if (latestVersion.isEmpty) {
      throw Exception('Release mới nhất không có tag hợp lệ');
    }

    return UpdateCheckResult(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      releaseUrl: releaseUrl,
      releaseName: releaseName,
      hasUpdate: _isNewerVersion(latestVersion, currentVersion),
      publishedAt: publishedAtRaw == null
          ? null
          : DateTime.tryParse(publishedAtRaw)?.toLocal(),
    );
  }

  static String _normalizeVersion(String tagName) {
    final trimmed = tagName.trim();
    var version = trimmed;
    if (version.startsWith('v') || version.startsWith('V')) {
      version = version.substring(1);
    }
    // Strip commit SHA suffix (e.g. "2026.07.02-abc1234" → "2026.07.02")
    final dashIndex = version.lastIndexOf('-');
    if (dashIndex != -1) {
      final suffix = version.substring(dashIndex + 1);
      // Only strip if suffix looks like a commit SHA (hex, 7 chars)
      if (RegExp(r'^[0-9a-f]{7}$').hasMatch(suffix)) {
        version = version.substring(0, dashIndex);
      }
    }
    return version;
  }

  static bool _isNewerVersion(String latest, String current) {
    final latestParts = _versionParts(latest);
    final currentParts = _versionParts(current);

    if (latestParts.isEmpty || currentParts.isEmpty) {
      return latest != current;
    }

    final maxLength = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    for (var i = 0; i < maxLength; i++) {
      final latestPart = i < latestParts.length ? latestParts[i] : 0;
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    return false;
  }

  static List<int> _versionParts(String version) {
    final mainVersion = version.split('+').first;
    final parts = mainVersion.split('.');
    final numbers = <int>[];

    for (final part in parts) {
      final match = RegExp(r'^\d+').firstMatch(part);
      if (match == null) return const [];
      numbers.add(int.parse(match.group(0)!));
    }

    return numbers;
  }
}
