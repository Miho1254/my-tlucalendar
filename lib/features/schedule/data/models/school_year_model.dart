import 'package:tlucalendar/features/schedule/data/models/semester_model.dart';
import 'package:tlucalendar/features/schedule/domain/entities/school_year.dart';

class SchoolYearModel extends SchoolYear {
  const SchoolYearModel({
    required super.id,
    required super.name,
    required super.code,
    required super.year,
    required super.current,
    required super.startDate,
    required super.endDate,
    required super.displayName,
    required List<SemesterModel> super.semesters,
  });

  factory SchoolYearModel.fromJson(Map<String, dynamic> json) {
    var semestersList = json['semesters'] as List?;
    return SchoolYearModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      year: json['year'] ?? 0,
      current: json['current'] ?? false,
      startDate: json['startDate'] ?? 0,
      endDate: json['endDate'] ?? 0,
      displayName: json['displayName'] ?? '',
      semesters: semestersList != null
          ? semestersList.map((item) => SemesterModel.fromJson(item)).toList()
          : [],
    );
  }
}
