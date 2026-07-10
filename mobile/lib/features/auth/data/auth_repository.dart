import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'app_user.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Returns the current user if a valid session cookie exists, or null.
  Future<AppUser?> getSession() async {
    try {
      final response = await _dio.get('/api/me');
      final data = response.data;
      if (data is! Map || data['user'] == null) return null;
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<AppUser> signIn({required String email, required String password}) async {
    final response = await _dio.post(
      '/api/auth/sign-in/email',
      data: {'email': email, 'password': password},
    );
    return _userFromAuthResponse(response);
  }

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/sign-up/email',
      data: {'name': name, 'email': email, 'password': password},
    );
    return _userFromAuthResponse(response);
  }

  Future<void> signOut() async {
    await _dio.post('/api/auth/sign-out');
  }

  AppUser _userFromAuthResponse(Response response) {
    ApiException.checkStatus(response);
    final data = response.data;
    if (data is! Map || data['user'] == null) {
      throw ApiException('Unexpected response from server');
    }
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}
