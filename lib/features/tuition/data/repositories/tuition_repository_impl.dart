import 'package:dartz/dartz.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/features/tuition/data/datasources/tuition_remote_data_source.dart';
import 'package:tlucalendar/features/tuition/domain/entities/tuition_fee.dart';
import 'package:tlucalendar/features/tuition/domain/repositories/tuition_repository.dart';

class TuitionRepositoryImpl implements TuitionRepository {
  final TuitionRemoteDataSource remoteDataSource;

  TuitionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, TuitionFee>> getTuitionFee(String accessToken) async {
    try {
      final fee = await remoteDataSource.getTuitionFee(accessToken);
      return Right(fee);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(ServerFailure(e.toString()));
    }
  }
}
