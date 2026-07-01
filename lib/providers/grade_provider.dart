import 'package:flutter/material.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/features/grades/domain/entities/student_mark.dart';
import 'package:tlucalendar/features/grades/domain/repositories/grade_repository.dart';
import 'package:tlucalendar/features/grades/domain/usecases/get_grades.dart';
import 'package:tlucalendar/features/grades/domain/services/grade_analytics_service.dart';
import 'package:tlucalendar/providers/auth_provider.dart';

class GradeProvider with ChangeNotifier {
  final GetGrades getGradesUseCase;
  final GradeRepository gradeRepository;

  GradeProvider({
    required this.getGradesUseCase,
    required this.gradeRepository,
  });

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

  // Clear data on logout
  void clearData() {
    _grades = [];
    _analyticsResult = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Grouped by Semester: Map<SemesterName, List<StudentMark>>
  Map<String, List<StudentMark>> get groupedGrades {
    final Map<String, List<StudentMark>> grouped = {};
    for (var grade in _grades) {
      if (!grouped.containsKey(grade.semesterName)) {
        grouped[grade.semesterName] = [];
      }
      grouped[grade.semesterName]!.add(grade);
    }
    return grouped;
  }

  Future<void> fetchGrades(String accessToken, {bool forceRefresh = false}) async {
    _errorMessage = null;

    if (!forceRefresh) {
      // Step 1: Load cache immediately without spinning
      final cacheResult = await gradeRepository.getCachedGrades();
      cacheResult.fold(
        (_) => null,
        (cachedGrades) {
          if (cachedGrades.isNotEmpty) {
            _grades = cachedGrades;
            _grades.sort((a, b) => b.semesterId.compareTo(a.semesterId));
            _analyticsResult = GradeAnalyticsService.analyze(_grades);
            notifyListeners();
          }
        },
      );
    }

    // Step 2: Show spinner if memory is empty OR forceRefresh is true
    final shouldShowSpinner = _grades.isEmpty || forceRefresh;
    if (shouldShowSpinner) {
      _isLoading = true;
      notifyListeners();
    }

    // Step 3: Fetch remote
    final result = await getGradesUseCase(
      GetGradesParams(accessToken: accessToken),
    );

    await result.fold(
      (failure) async {
        if (_authProvider != null && await _authProvider!.reLogin()) {
          final newResult = await getGradesUseCase(
            GetGradesParams(accessToken: _authProvider!.accessToken!),
          );
          newResult.fold(
            (f) {
              if (shouldShowSpinner) {
                _errorMessage = _mapFailureToMessage(f);
              }
            },
            (grades) {
              _grades = grades;
              _grades.sort((a, b) => b.semesterId.compareTo(a.semesterId));
              _analyticsResult = GradeAnalyticsService.analyze(_grades);
            },
          );
        } else {
          if (shouldShowSpinner) {
            _errorMessage = _mapFailureToMessage(failure);
          }
        }
      },
      (grades) async {
        _grades = grades;
        _grades.sort((a, b) => b.semesterId.compareTo(a.semesterId));
        _analyticsResult = GradeAnalyticsService.analyze(_grades);
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
