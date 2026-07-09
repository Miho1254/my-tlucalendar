import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/core/network/network_client.dart';
import 'package:tlucalendar/features/grades/data/datasources/grade_remote_data_source.dart';

@GenerateMocks([NetworkClient])
import 'grade_remote_data_source_test.mocks.dart';

void main() {
  late GradeRemoteDataSourceImpl dataSource;
  late MockNetworkClient mockClient;

  setUp(() {
    mockClient = MockNetworkClient();
    dataSource = GradeRemoteDataSourceImpl(client: mockClient);
  });

  group('getGrades', () {
    test('throws ServerFailure when API returns invalid_token error', () async {
      // Simulate the response the Dio interceptor would produce
      // After the interceptor rejects, Dio throws a DioException
      when(mockClient.get(
        any,
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        error: 'invalid_token',
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          data: '{"error":"invalid_token","error_description":"Invalid access token"}',
          statusCode: 200,
        ),
      ));

      expect(
        () => dataSource.getGrades('expired-token'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('returns grades list on valid response', () async {
      final validJson = '[{"subjectCode":"MAT101","subjectName":"Math","numberOfCredit":3,"mark":8.5,"markQT":8.0,"markTHI":9.0,"charMark":"B+","studyTime":"2024-2025","examRound":1,"isCalculateMark":true,"semesterCode":"HK1","semesterName":"Học kỳ 1","semesterId":1}]';

      when(mockClient.get(
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/test'),
        data: validJson,
        statusCode: 200,
      ));

      final result = await dataSource.getGrades('valid-token');
      expect(result, isA<List>());
      expect(result.length, 1);
      expect(result.first.subjectCode, 'MAT101');
    });

    test('returns empty list when response is empty array', () async {
      when(mockClient.get(
        any,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/test'),
        data: '[]',
        statusCode: 200,
      ));

      final result = await dataSource.getGrades('valid-token');
      expect(result, isEmpty);
    });

    test('throws ServerFailure on DioException', () async {
      when(mockClient.get(
        any,
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/test'),
        message: 'Connection timeout',
        type: DioExceptionType.connectionTimeout,
      ));

      expect(
        () => dataSource.getGrades('valid-token'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
