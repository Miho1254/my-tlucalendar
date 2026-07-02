import 'package:flutter/material.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/features/education_program/domain/entities/education_program.dart';
import 'package:tlucalendar/features/education_program/domain/usecases/get_education_program.dart';
import 'package:tlucalendar/providers/auth_provider.dart';

class EducationProgramProvider extends ChangeNotifier {
  final GetEducationProgram getEducationProgramUseCase;

  EducationProgramProvider({required this.getEducationProgramUseCase});

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
    notifyListeners();
  }

  Future<void> fetchProgram(String accessToken, {bool forceRefresh = false}) async {
    _errorMessage = null;

    if (forceRefresh) {
      _isLoading = true;
      notifyListeners();
    }

    final result = await getEducationProgramUseCase(
      GetEducationProgramParams(accessToken: accessToken),
    );

    await result.fold(
      (failure) async {
        if (_authProvider != null && await _authProvider!.reLogin()) {
          final newResult = await getEducationProgramUseCase(
            GetEducationProgramParams(accessToken: _authProvider!.accessToken!),
          );
          newResult.fold(
            (f) {
              _errorMessage = _mapFailureToMessage(f);
            },
            (program) {
              _program = program;
            },
          );
        } else {
          _errorMessage = _mapFailureToMessage(failure);
        }
      },
      (program) async {
        _program = program;
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
