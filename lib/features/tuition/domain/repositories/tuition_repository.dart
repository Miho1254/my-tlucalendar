import 'package:dartz/dartz.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/features/tuition/domain/entities/tuition_fee.dart';

abstract class TuitionRepository {
  Future<Either<Failure, TuitionFee>> getTuitionFee(String accessToken);
}
