import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/core/usecases/usecase.dart';
import 'package:tlucalendar/features/tuition/domain/entities/tuition_fee.dart';
import 'package:tlucalendar/features/tuition/domain/repositories/tuition_repository.dart';

class GetTuitionFeeParams extends Equatable {
  final String accessToken;
  const GetTuitionFeeParams({required this.accessToken});
  @override
  List<Object?> get props => [accessToken];
}

class GetTuitionFee implements UseCase<TuitionFee, GetTuitionFeeParams> {
  final TuitionRepository repository;

  GetTuitionFee(this.repository);

  @override
  Future<Either<Failure, TuitionFee>> call(GetTuitionFeeParams params) async {
    return await repository.getTuitionFee(params.accessToken);
  }
}
