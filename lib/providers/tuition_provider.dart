import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/features/tuition/domain/entities/tuition_fee.dart';
import 'package:tlucalendar/features/tuition/data/models/tuition_fee_model.dart';
import 'package:tlucalendar/features/tuition/domain/usecases/get_tuition_fee.dart';
import 'package:tlucalendar/providers/auth_provider.dart';

class TuitionProvider extends ChangeNotifier {
  final GetTuitionFee getTuitionFeeUseCase;

  TuitionProvider({required this.getTuitionFeeUseCase});

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
    notifyListeners();
  }

  Future<void> loadCachedTuitionFee() async {
    if (_tuitionFee != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('cached_tuition_fee_v2');
      if (cachedString != null) {
        _tuitionFee = TuitionFeeModel.fromCacheJson(jsonDecode(cachedString));
        notifyListeners();
      }
    } catch (e) {
      // Ignore cache load errors
    }
  }

  Future<void> fetchTuitionFee(String accessToken, {bool forceRefresh = false}) async {
    _errorMessage = null;
    
    await loadCachedTuitionFee();

    if (forceRefresh || _tuitionFee == null) {
      _isLoading = true;
      notifyListeners();
    }

    final result = await getTuitionFeeUseCase(
      GetTuitionFeeParams(accessToken: accessToken),
    );

    await result.fold(
      (failure) async {
        if (_authProvider != null && await _authProvider!.reLogin()) {
          final newResult = await getTuitionFeeUseCase(
            GetTuitionFeeParams(accessToken: _authProvider!.accessToken!),
          );
          newResult.fold(
            (f) {
              _errorMessage = _mapFailureToMessage(f);
            },
            (fee) {
              _tuitionFee = fee;
              _saveToCache(fee);
            },
          );
        } else {
          // If we have cached data, don't show a blocking error on silent refresh
          if (_tuitionFee == null || forceRefresh) {
            _errorMessage = _mapFailureToMessage(failure);
          }
        }
      },
      (fee) async {
        _tuitionFee = fee;
        _saveToCache(fee);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveToCache(TuitionFee fee) async {
    try {
      if (fee is TuitionFeeModel) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_tuition_fee_v2', jsonEncode(fee.toJson()));
      } else {
        // Fallback if it's somehow just a TuitionFee entity
        final model = TuitionFeeModel(
          totalPayable: fee.totalPayable,
          totalPaid: fee.totalPaid,
          remainingAmount: fee.remainingAmount,
          items: fee.items,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_tuition_fee_v2', jsonEncode(model.toJson()));
      }
    } catch (e) {
      // Ignore cache save errors
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else {
      return 'Không thể kết nối đến máy chủ TLU';
    }
  }
}
