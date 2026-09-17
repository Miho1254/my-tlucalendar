import 'package:flutter/material.dart';
import 'package:tlucalendar/core/cache/tuition_cache_manager.dart';
import 'package:tlucalendar/features/tuition/domain/entities/tuition_fee.dart';
import 'package:tlucalendar/providers/auth_provider.dart';

class TuitionProvider extends ChangeNotifier {
  final TuitionCacheManager _cacheManager;

  TuitionProvider({
    required TuitionCacheManager cacheManager,
  }) : _cacheManager = cacheManager;

  AuthProvider? _authProvider;

  void setAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  TuitionFee? _tuitionFee;
  bool _isLoading = false;
  String? _errorMessage;

  TuitionFee? get tuitionFee => _tuitionFee;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearData() {
    _tuitionFee = null;
    _errorMessage = null;
    _isLoading = false;
    _cacheManager.invalidateAll();
    notifyListeners();
  }

  Future<void> fetchTuitionFee(
    String accessToken, {
    bool forceRefresh = false,
  }) async {
    _errorMessage = null;

    // Preload from SharedPreferences (stale)
    if (!forceRefresh && _tuitionFee == null) {
      await _cacheManager.preloadFromLocal();
    }

    if (forceRefresh || _tuitionFee == null) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final result = await _cacheManager.getTuitionFee(
        accessToken,
        forceRefresh: forceRefresh,
      );

      _tuitionFee = result.data;
    } catch (e) {
      // Try relogin
      if (_authProvider != null) {
        try {
          final newToken = _authProvider!.accessToken;
          if (newToken != null) {
            final result = await _cacheManager.getTuitionFee(newToken);
            _tuitionFee = result.data;
          }
        } catch (_) {
          if (_tuitionFee == null || forceRefresh) {
            _errorMessage = 'Không thể kết nối đến máy chủ TLU';
          }
        }
      } else {
        if (_tuitionFee == null || forceRefresh) {
          _errorMessage = 'Không thể kết nối đến máy chủ TLU';
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
