import 'package:dartz/dartz.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/features/education_program/data/datasources/education_program_remote_data_source.dart';
import 'package:tlucalendar/features/education_program/domain/entities/education_program.dart';
import 'package:tlucalendar/features/education_program/domain/repositories/education_program_repository.dart';

class EducationProgramRepositoryImpl implements EducationProgramRepository {
  final EducationProgramRemoteDataSource remoteDataSource;

  EducationProgramRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, EducationProgram>> getEducationProgram(String accessToken) async {
    try {
      final program = await remoteDataSource.getEducationProgram(accessToken);
      return Right(program);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(ServerFailure(e.toString()));
    }
  }
}
