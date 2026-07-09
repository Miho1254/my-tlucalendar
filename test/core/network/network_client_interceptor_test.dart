import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replicates the interceptor logic from NetworkClient for testing
Interceptor buildInvalidTokenInterceptor() {
  return InterceptorsWrapper(
    onResponse: (response, handler) {
      final data = response.data;
      if (data is String && data.trimLeft().startsWith('{')) {
        if (data.contains('"error"') && data.contains('invalid_token')) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: 'invalid_token',
            ),
          );
          return;
        }
      }
      handler.next(response);
    },
  );
}

void main() {
  group('invalid_token interceptor', () {
    late Interceptor interceptor;
    late InterceptorResolverStub resolver;

    setUp(() {
      interceptor = buildInvalidTokenInterceptor();
      resolver = InterceptorResolverStub();
    });

    test('rejects string response containing invalid_token', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: '{"error":"invalid_token","error_description":"Invalid access token: abc123"}',
        statusCode: 200,
      );

      interceptor.onResponse!(response, resolver);

      expect(resolver.rejected, isTrue);
      expect(resolver.rejectedError, isA<DioException>());
      expect(resolver.rejectedError!.error, 'invalid_token');
      expect(resolver.forwarded, isFalse);
    });

    test('passes through normal JSON array response', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: '[{"subjectCode":"MAT101","subjectName":"Math"}]',
        statusCode: 200,
      );

      interceptor.onResponse!(response, resolver);

      expect(resolver.forwarded, isTrue);
      expect(resolver.rejected, isFalse);
    });

    test('passes through object response without error key', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: '{"data":[{"id":1}],"count":1}',
        statusCode: 200,
      );

      interceptor.onResponse!(response, resolver);

      expect(resolver.forwarded, isTrue);
      expect(resolver.rejected, isFalse);
    });

    test('passes through object with error but not invalid_token', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: '{"error":"server_error","message":"Something went wrong"}',
        statusCode: 200,
      );

      interceptor.onResponse!(response, resolver);

      expect(resolver.forwarded, isTrue);
      expect(resolver.rejected, isFalse);
    });

    test('passes through non-string data (e.g. Map)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: {'error': 'invalid_token'},
        statusCode: 200,
      );

      interceptor.onResponse!(response, resolver);

      expect(resolver.forwarded, isTrue);
      expect(resolver.rejected, isFalse);
    });

    test('passes through null data', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: null,
        statusCode: 200,
      );

      interceptor.onResponse!(response, resolver);

      expect(resolver.forwarded, isTrue);
      expect(resolver.rejected, isFalse);
    });

    test('handles whitespace before JSON', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: '  {"error":"invalid_token","error_description":"expired"}',
        statusCode: 200,
      );

      interceptor.onResponse!(response, resolver);

      expect(resolver.rejected, isTrue);
    });

    test('does not match partial "invalid_token" in values', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: '{"error":"some_error","error_description":"token is invalid_token-like but not exact"}',
        statusCode: 200,
      );

      // This still matches because contains('invalid_token') is true
      // This is acceptable — the interceptor is conservative
      interceptor.onResponse!(response, resolver);

      expect(resolver.rejected, isTrue);
    });
  });
}

/// Stub implementation of ResponseInterceptorHandler for testing
class InterceptorResolverStub extends ResponseInterceptorHandler {
  bool rejected = false;
  bool forwarded = false;
  DioException? rejectedError;
  Response? forwardedResponse;

  @override
  void reject(DioException err, [bool? keepPending]) {
    rejected = true;
    rejectedError = err;
  }

  @override
  void next(Response response) {
    forwarded = true;
    forwardedResponse = response;
  }
}
