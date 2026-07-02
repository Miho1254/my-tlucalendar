import 'package:dio/dio.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/core/network/network_client.dart';
import 'package:tlucalendar/features/education_program/data/models/education_program_model.dart';

abstract class EducationProgramRemoteDataSource {
  Future<EducationProgramModel> getEducationProgram(String accessToken);
}

class EducationProgramRemoteDataSourceImpl implements EducationProgramRemoteDataSource {
  final NetworkClient client;

  EducationProgramRemoteDataSourceImpl({required this.client});

  @override
  Future<EducationProgramModel> getEducationProgram(String accessToken) async {
    try {
      // Step 1: Get student info to find program ID
      final studentResponse = await client.get(
        '/education/api/student/getstudentbylogin',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      final studentData = studentResponse.data as Map<String, dynamic>;
      final programs = studentData['programs'] as List<dynamic>? ?? [];

      if (programs.isEmpty) {
        throw ServerFailure('Không tìm thấy chương trình đào tạo');
      }

      final programId = programs[0]['program']['id'] as int;

      // Step 2: Fetch education program tree
      final programResponse = await client.get(
        '/education/api/programsubject/tree/$programId/1/10000',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      final programData = programResponse.data as Map<String, dynamic>;
      return EducationProgramModel.fromJson(programData, programs[0]['program']);
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Unknown Dio Error');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString());
    }
  }
}
