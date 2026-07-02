import 'package:tlucalendar/features/education_program/domain/entities/education_program.dart';

class EducationProgramModel extends EducationProgram {
  const EducationProgramModel({
    required super.id,
    required super.name,
    required super.code,
    required super.subjects,
  });

  factory EducationProgramModel.fromJson(Map<String, dynamic> json, Map<String, dynamic> programInfo) {
    final content = json['content'] as List<dynamic>? ?? [];

    final subjects = content.map<ProgramSubject>((item) {
      final subject = item['subject'] as Map<String, dynamic>? ?? {};
      final knowledgeProgram = item['knowledgeProgram'] as Map<String, dynamic>?;
      final knowledgeBlock = knowledgeProgram?['knowledgeBlock'] as Map<String, dynamic>?;

      return ProgramSubject(
        id: item['id'] as int? ?? 0,
        code: subject['subjectCode']?.toString() ?? item['displaySubjectCode']?.toString() ?? '',
        name: subject['subjectName']?.toString() ?? item['displaySubjectName']?.toString() ?? '',
        credits: subject['numberOfCredit'] as int? ?? 0,
        semesterIndex: item['semesterIndex'] as int? ?? 0,
        knowledgeBlock: knowledgeBlock?['name']?.toString() ?? '',
        subjectType: item['subjectType'] as int? ?? 1,
      );
    }).toList();

    return EducationProgramModel(
      id: programInfo['id'] as int? ?? 0,
      name: programInfo['name']?.toString() ?? '',
      code: programInfo['code']?.toString() ?? '',
      subjects: subjects,
    );
  }

  factory EducationProgramModel.fromCacheJson(Map<String, dynamic> json) {
    final subjects = (json['subjects'] as List<dynamic>? ?? []).map((item) {
      return ProgramSubject(
        id: item['id'] as int? ?? 0,
        code: item['code']?.toString() ?? '',
        name: item['name']?.toString() ?? '',
        credits: item['credits'] as int? ?? 0,
        semesterIndex: item['semesterIndex'] as int? ?? 0,
        knowledgeBlock: item['knowledgeBlock']?.toString() ?? '',
        subjectType: item['subjectType'] as int? ?? 1,
      );
    }).toList();

    return EducationProgramModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      subjects: subjects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'subjects': subjects.map((s) => {
        'id': s.id,
        'code': s.code,
        'name': s.name,
        'credits': s.credits,
        'semesterIndex': s.semesterIndex,
        'knowledgeBlock': s.knowledgeBlock,
        'subjectType': s.subjectType,
      }).toList(),
    };
  }
}
