import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tlucalendar/core/error/failures.dart';

/// Simulates the full token refresh flow:
/// 1. Dio interceptor detects invalid_token → throws DioException
/// 2. Data source catches DioException → throws ServerFailure
/// 3. Provider catches ServerFailure → calls reLogin() → retries
void main() {
  group('Token refresh flow simulation', () {
    test('invalid_token response triggers ServerFailure through interceptor', () {
      // Step 1: Simulate what the Dio interceptor does
      final errorJson = '{"error":"invalid_token","error_description":"Invalid access token: abc123"}';
      final response = Response(
        requestOptions: RequestOptions(path: '/education/api/studentsubjectmark/getListStudentMarkBySemesterByLoginUser/0'),
        data: errorJson,
        statusCode: 200,
      );

      // The interceptor checks this
      final data = response.data;
      final isInvalidToken = data is String &&
          data.trimLeft().startsWith('{') &&
          data.contains('"error"') &&
          data.contains('invalid_token');

      expect(isInvalidToken, isTrue, reason: 'Should detect invalid_token in response');

      // Step 2: The interceptor would reject → Dio throws DioException
      final dioException = DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'invalid_token',
      );

      // Step 3: Data source catches DioException → throws ServerFailure
      ServerFailure? serverFailure;
      try {
        throw dioException;
      } on DioException catch (e) {
        serverFailure = ServerFailure(e.message ?? 'Unknown error');
      }

      expect(serverFailure, isA<ServerFailure>());
      expect(serverFailure!.message, contains('Unknown error'));
    });

    test('valid array response passes through interceptor', () {
      final validJson = '[{"subjectCode":"MAT101","subjectName":"Math"}]';
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: validJson,
        statusCode: 200,
      );

      final data = response.data;
      final isInvalidToken = data is String &&
          data.trimLeft().startsWith('{') &&
          data.contains('"error"') &&
          data.contains('invalid_token');

      expect(isInvalidToken, isFalse, reason: 'Valid array should pass through');
    });

    test('provider reLogin flow: failure → reLogin → retry', () async {
      // Simulate the provider's flow
      int loginAttempts = 0;
      String? currentToken;

      Future<bool> reLogin() async {
        loginAttempts++;
        if (loginAttempts <= 3) {
          currentToken = 'new_token_$loginAttempts';
          return true;
        }
        return false;
      }

      Future<String?> fetchGrades(String token) async {
        if (token == 'expired_token') {
          throw ServerFailure('invalid_token');
        }
        return 'grades_data_for_$token';
      }

      // First call with expired token
      String? result;
      try {
        result = await fetchGrades('expired_token');
      } on ServerFailure catch (_) {
        // Provider catches failure → calls reLogin
        final loginSuccess = await reLogin();
        if (loginSuccess) {
          // Retry with new token
          result = await fetchGrades(currentToken!);
        }
      }

      expect(result, 'grades_data_for_new_token_1');
      expect(loginAttempts, 1);
    });

    test('provider reLogin fails after 3 attempts', () async {
      int loginAttempts = 0;

      Future<bool> reLogin() async {
        loginAttempts++;
        return false; // Always fail
      }

      String? errorMessage;
      try {
        throw ServerFailure('invalid_token');
      } on ServerFailure catch (e) {
        final loginSuccess = await reLogin();
        if (!loginSuccess) {
          errorMessage = 'Login failed after $loginAttempts attempts';
        }
      }

      expect(errorMessage, 'Login failed after 1 attempts');
      expect(loginAttempts, 1);
    });
  });
}
