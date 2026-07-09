import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:tlucalendar/core/error/failures.dart';
import 'package:tlucalendar/core/network/network_client.dart';

import 'package:tlucalendar/features/auth/data/models/user_model.dart';
import 'package:tlucalendar/core/native/native_parser.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String studentCode, String password);
  Future<UserModel> getCurrentUser(String accessToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final NetworkClient client;

  AuthRemoteDataSourceImpl({required this.client});

  static const String _tokenEndpoint = '/login';
  static const String _userEndpoint = '/education/api/users/getCurrentUser';
  // Client secrets handled by Worker now
  // static const String _clientId = 'education_client';
  // static const String _clientSecret = 'password';
  // static const String _grantType = 'password';

  @override
  Future<Map<String, dynamic>> login(
    String studentCode,
    String password,
  ) async {
    try {
      // Simplified Login via Cloudflare Worker
      // Worker handles JSON -> Form Data conversion and Secret injection
      final response = await client.post(
        _tokenEndpoint,
        data: {'studentCode': studentCode, 'password': password},
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.plain,
        ),
        // Headers are already 'application/json' by default in Dio/NetworkClient
      );

      if (response.statusCode == 200) {
        final data = NativeParser.parseToken(response.data as String);
        if (data == null || data['access_token'] == null) {
          // Try to extract error description from the response
          final raw = response.data as String;
          String detail = '';
          try {
            final trimmed = raw.trimLeft();
            if (trimmed.startsWith('{')) {
              final decoded = jsonDecode(raw) as Map<String, dynamic>;
              detail = decoded['error_description']?.toString() ??
                  decoded['error']?.toString() ??
                  '';
            }
          } catch (_) {}

          if (detail.isNotEmpty) {
            throw ServerFailure(_mapLoginError(detail));
          }
          throw ServerFailure(
            'Lỗi máy chủ: Không nhận được mã truy cập hợp lệ từ hệ thống.',
          );
        }
        return data;
      } else {
        throw ServerFailure(
          'Không thể kết nối đến máy chủ (Mã lỗi: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Lỗi đăng nhập: $e');
    }
  }

  @override
  Future<UserModel> getCurrentUser(String accessToken) async {
    try {
      final response = await client.get(
        _userEndpoint,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return NativeParser.parseUser(response.data as String) ??
            const UserModel(
              studentId: '',
              fullName: '',
              email: '',
              profileImageUrl: null,
            );
      } else {
        throw ServerFailure('Get User failed: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerFailure('Lỗi lấy thông tin người dùng: $e');
    }
  }

  static String _mapLoginError(String detail) {
    final lower = detail.toLowerCase();
    if (lower.contains('disabled') || lower.contains('vô hiệu')) {
      return 'Tài khoản đã bị vô hiệu hóa. Liên hệ phòng CTSV tại cơ sở để được hỗ trợ.';
    }
    if (lower.contains('invalid_grant') ||
        lower.contains('invalid') && lower.contains('credential')) {
      return 'Mã sinh viên hoặc mật khẩu không đúng.';
    }
    if (lower.contains('expired') || lower.contains('hết hạn')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (lower.contains('locked') || lower.contains('khóa')) {
      return 'Tài khoản đã bị khóa. Liên hệ phòng CTSV tại cơ sở.';
    }
    if (lower.contains('network') || lower.contains('timeout')) {
      return 'Lỗi mạng. Kiểm tra kết nối internet và thử lại.';
    }
    return 'Đăng nhập thất bại: $detail';
  }
}
