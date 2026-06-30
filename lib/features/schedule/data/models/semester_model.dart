import 'package:tlucalendar/features/schedule/domain/entities/semester.dart';
import 'package:tlucalendar/features/schedule/data/models/semester_register_period_model.dart';

class SemesterModel extends Semester {
  const SemesterModel({
    required super.id,
    required super.semesterCode,
    required super.semesterName,
    required super.startDate,
    required super.endDate,
    required super.isCurrent,
    super.ordinalNumbers,
    List<SemesterRegisterPeriodModel>? super.registerPeriods,
  });

  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      id: json['id'] ?? 0,
      semesterCode: json['semesterCode'] ?? '',
      semesterName: json['semesterName'] ?? '',
      startDate: json['startDate'] ?? 0,
      endDate: json['endDate'] ?? 0,
      isCurrent: json['isCurrent'] ?? false,
      ordinalNumbers: json['ordinalNumbers'],
      registerPeriods: json['semesterRegisterPeriods'] != null
          ? (json['semesterRegisterPeriods'] as List)
                .map((e) => SemesterRegisterPeriodModel.fromJson(e))
                .toList()
          : [],
    );
  }
}
