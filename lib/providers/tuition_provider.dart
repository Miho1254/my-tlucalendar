import 'package:flutter/material.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/features/tuition/domain/entities/tuition_fee.dart';
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

  Future<void> fetchTuitionFee(String accessToken, {bool forceRefresh = false}) async {
    _errorMessage = null;

    if (forceRefresh) {
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
            },
          );
        } else {
          _errorMessage = _mapFailureToMessage(failure);
        }
      },
      (fee) async {
        _tuitionFee = fee;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else {
      return 'Không thể kết nối đến máy chủ TLU';
    }
  }
}
