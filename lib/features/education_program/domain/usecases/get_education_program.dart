import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/core/usecases/usecase.dart';
import 'package:tlucalendar/features/education_program/domain/entities/education_program.dart';
import 'package:tlucalendar/features/education_program/domain/repositories/education_program_repository.dart';

class GetEducationProgramParams extends Equatable {
  final String accessToken;
  const GetEducationProgramParams({required this.accessToken});
  @override
  List<Object?> get props => [accessToken];
}

class GetEducationProgram implements UseCase<EducationProgram, GetEducationProgramParams> {
  final EducationProgramRepository repository;

  GetEducationProgram(this.repository);

  @override
  Future<Either<Failure, EducationProgram>> call(GetEducationProgramParams params) async {
    return await repository.getEducationProgram(params.accessToken);
  }
}
