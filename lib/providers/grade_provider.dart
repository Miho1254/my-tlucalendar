import 'package:flutter/material.dart';
import 'package:tlucalendar/core/cache/grade_cache_manager.dart';
import 'package:tlucalendar/features/grades/domain/entities/student_mark.dart';
import 'package:tlucalendar/features/grades/domain/services/grade_analytics_service.dart';
import 'package:tlucalendar/providers/auth_provider.dart';

class GradeProvider with ChangeNotifier {
  final GradeCacheManager _cacheManager;

  GradeProvider({
    required GradeCacheManager cacheManager,
  }) : _cacheManager = cacheManager;

  AuthProvider? _authProvider;

  void setAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  List<StudentMark> _grades = [];
  bool _isLoading = false;
  String? _errorMessage;
  GradeAnalyticsResult? _analyticsResult;

  List<StudentMark> get grades => _grades;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GradeAnalyticsResult? get analyticsResult => _analyticsResult;

  void clearData() {
    _grades = [];
    _analyticsResult = null;
    _errorMessage = null;
    _isLoading = false;
    _cacheManager.invalidateAll();
    notifyListeners();
  }

  Map<String, List<StudentMark>> get groupedGrades {
    final Map<String, List<StudentMark>> grouped = {};
    for (var grade in _grades) {
      grouped.putIfAbsent(grade.semesterName, () => []).add(grade);
    }
    return grouped;
  }

  Future<void> fetchGrades(
    String accessToken, {
    bool forceRefresh = false,
  }) async {
    _errorMessage = null;

    // Preload from SQLite (stale)
    if (!forceRefresh) {
      await _cacheManager.preloadFromLocal();
    }

    // Show spinner only if no data yet or force refresh
    final shouldShowSpinner = _grades.isEmpty || forceRefresh;
    if (shouldShowSpinner) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final result = await _cacheManager.getGrades(
        accessToken,
        forceRefresh: forceRefresh,
      );

      _grades = result.data;
      _grades.sort((a, b) => b.semesterId.compareTo(a.semesterId));
      _analyticsResult = GradeAnalyticsService.analyze(_grades);
    } catch (e) {
      // Try relogin
      if (_authProvider != null) {
        try {
          final newToken = _authProvider!.accessToken;
          if (newToken != null) {
            final result = await _cacheManager.getGrades(newToken);
            _grades = result.data;
            _grades.sort((a, b) => b.semesterId.compareTo(a.semesterId));
            _analyticsResult = GradeAnalyticsService.analyze(_grades);
          }
        } catch (_) {
          if (shouldShowSpinner) {
            _errorMessage = 'Không thể kết nối đến máy chủ TLU';
          }
        }
      } else {
        if (shouldShowSpinner) {
          _errorMessage = 'Không thể kết nối đến máy chủ TLU';
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
