import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/features/education_program/domain/entities/education_program.dart';
import 'package:tlucalendar/features/education_program/data/models/education_program_model.dart';
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

  Future<void> loadCachedProgram() async {
    if (_program != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('cached_education_program');
      if (cachedString != null) {
        _program = EducationProgramModel.fromCacheJson(jsonDecode(cachedString));
        notifyListeners();
      }
    } catch (e) {
      // Ignore cache load errors
    }
  }

  Future<void> fetchProgram(String accessToken, {bool forceRefresh = false}) async {
    _errorMessage = null;

    await loadCachedProgram();

    if (forceRefresh || _program == null) {
      _isLoading = true;
      notifyListeners();
    }

    final result = await getEducationProgramUseCase(
      GetEducationProgramParams(accessToken: accessToken),
    );

    await result.fold(
      (failure) async {
        if (_authProvider != null && await _authProvider!.reLogin()) {
          final newToken = _authProvider!.accessToken;
          if (newToken == null) {
            _errorMessage = _mapFailureToMessage(failure);
          } else {
            final newResult = await getEducationProgramUseCase(
              GetEducationProgramParams(accessToken: newToken),
            );
            newResult.fold(
              (f) {
                _errorMessage = _mapFailureToMessage(f);
              },
              (program) {
                _program = program;
                _saveToCache(program);
              },
            );
          }
        } else {
          if (_program == null || forceRefresh) {
            _errorMessage = _mapFailureToMessage(failure);
          }
        }
      },
      (program) async {
        _program = program;
        _saveToCache(program);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveToCache(EducationProgram program) async {
    try {
      if (program is EducationProgramModel) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_education_program', jsonEncode(program.toJson()));
      } else {
        final model = EducationProgramModel(
          id: program.id,
          name: program.name,
          code: program.code,
          subjects: program.subjects,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_education_program', jsonEncode(model.toJson()));
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
