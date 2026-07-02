import 'package:dio/dio.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/core/network/network_client.dart';
import 'package:tlucalendar/features/tuition/data/models/tuition_fee_model.dart';

abstract class TuitionRemoteDataSource {
  Future<TuitionFeeModel> getTuitionFee(String accessToken);
}

class TuitionRemoteDataSourceImpl implements TuitionRemoteDataSource {
  final NetworkClient client;

  TuitionRemoteDataSourceImpl({required this.client});

  @override
  Future<TuitionFeeModel> getTuitionFee(String accessToken) async {
    try {
      final response = await client.get(
        '/education/api/student/viewstudentpayablebyLoginUser',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      return TuitionFeeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Unknown Dio Error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
