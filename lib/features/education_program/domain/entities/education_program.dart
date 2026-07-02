import 'package:equatable/equatable.dart';

class EducationProgram extends Equatable {
  final int id;
  final String name;
  final String code;
  final List<ProgramSubject> subjects;

  const EducationProgram({
    required this.id,
    required this.name,
    required this.code,
    required this.subjects,
  });

  Map<int, List<ProgramSubject>> get subjectsBySemester {
    final map = <int, List<ProgramSubject>>{};
    for (final subject in subjects) {
      map.putIfAbsent(subject.semesterIndex, () => []).add(subject);
    }
    return map;
  }

  int get totalCredits => subjects.fold(0, (sum, s) => sum + s.credits);

  int creditsBySemester(int semester) {
    return subjects
        .where((s) => s.semesterIndex == semester)
        .fold(0, (sum, s) => sum + s.credits);
  }

  @override
  List<Object?> get props => [id, name, code, subjects];
}

class ProgramSubject extends Equatable {
  final int id;
  final String code;
  final String name;
  final int credits;
  final int semesterIndex;
  final String knowledgeBlock;
  final int subjectType; // 1=Bắt buộc, 2=Tự chọn, 3=Chứng chỉ

  const ProgramSubject({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.semesterIndex,
    required this.knowledgeBlock,
    required this.subjectType,
  });

  String get subjectTypeLabel {
    switch (subjectType) {
      case 1:
        return 'Bắt buộc';
      case 2:
        return 'Tự chọn';
      case 3:
        return 'Chứng chỉ';
      default:
        return '';
    }
  }

  @override
  List<Object?> get props => [id, code, name, credits, semesterIndex, knowledgeBlock, subjectType];
}
