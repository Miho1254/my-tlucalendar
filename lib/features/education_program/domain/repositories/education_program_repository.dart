import 'package:dartz/dartz.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/features/education_program/domain/entities/education_program.dart';

abstract class EducationProgramRepository {
  Future<Either<Failure, EducationProgram>> getEducationProgram(String accessToken);
}
