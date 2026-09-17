import 'package:flutter/material.dart';
import 'package:tlucalendar/core/cache/education_program_cache_manager.dart';
import 'package:tlucalendar/features/education_program/domain/entities/education_program.dart';
import 'package:tlucalendar/providers/auth_provider.dart';

class EducationProgramProvider extends ChangeNotifier {
  final EducationProgramCacheManager _cacheManager;

  EducationProgramProvider({
    required EducationProgramCacheManager cacheManager,
  }) : _cacheManager = cacheManager;

  AuthProvider? _authProvider;

  void setAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  EducationProgram? _program;
  bool _isLoading = false;
  String? _errorMessage;

  EducationProgram? get program => _program;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearData() {
    _program = null;
    _errorMessage = null;
    _isLoading = false;
    _cacheManager.invalidateAll();
    notifyListeners();
  }

  Future<void> fetchProgram(
    String accessToken, {
    bool forceRefresh = false,
  }) async {
    _errorMessage = null;

    // Preload from SharedPreferences (stale)
    if (!forceRefresh && _program == null) {
      await _cacheManager.preloadFromLocal();
    }

    if (forceRefresh || _program == null) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final result = await _cacheManager.getProgram(
        accessToken,
        forceRefresh: forceRefresh,
      );

      _program = result.data;
    } catch (e) {
      // Try relogin
      if (_authProvider != null) {
        try {
          final newToken = _authProvider!.accessToken;
          if (newToken != null) {
            final result = await _cacheManager.getProgram(newToken);
            _program = result.data;
          }
        } catch (_) {
          if (_program == null || forceRefresh) {
            _errorMessage = 'Không thể kết nối đến máy chủ TLU';
          }
        }
      } else {
        if (_program == null || forceRefresh) {
          _errorMessage = 'Không thể kết nối đến máy chủ TLU';
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
