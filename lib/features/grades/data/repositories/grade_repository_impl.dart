import 'package:dartz/dartz.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/features/grades/data/datasources/grade_remote_data_source.dart';
import 'package:tlucalendar/features/grades/data/datasources/grade_local_data_source.dart';
import 'package:tlucalendar/features/grades/domain/entities/student_mark.dart';
import 'package:tlucalendar/features/grades/domain/repositories/grade_repository.dart';

class GradeRepositoryImpl implements GradeRepository {
  final GradeRemoteDataSource remoteDataSource;
  final GradeLocalDataSource localDataSource;

  GradeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<StudentMark>>> getGrades(
    String accessToken,
  ) async {
    try {
      final grades = await remoteDataSource.getGrades(accessToken);
      try {
        await localDataSource.cacheGrades(grades);
      } catch (_) {}
      return Right(grades);
    } catch (e) {
      try {
        final cached = await localDataSource.getCachedGrades();
        if (cached.isNotEmpty) {
          return Left(CachedDataFailure(cached));
        }
      } catch (_) {}

      if (e is Failure) return Left(e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StudentMark>>> getCachedGrades() async {
    try {
      final cached = await localDataSource.getCachedGrades();
      return Right(cached);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
