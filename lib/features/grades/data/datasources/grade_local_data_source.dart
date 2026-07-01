import 'package:tlucalendar/features/grades/domain/entities/student_mark.dart';
import 'package:tlucalendar/services/database_helper.dart';

abstract class GradeLocalDataSource {
  Future<void> cacheGrades(List<StudentMark> grades);
  Future<List<StudentMark>> getCachedGrades();
}

class GradeLocalDataSourceImpl implements GradeLocalDataSource {
  final DatabaseHelper databaseHelper;

  GradeLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<void> cacheGrades(List<StudentMark> grades) async {
    await databaseHelper.saveStudentMarks(grades);
  }

  @override
  Future<List<StudentMark>> getCachedGrades() async {
    return await databaseHelper.getStudentMarks();
  }
}
