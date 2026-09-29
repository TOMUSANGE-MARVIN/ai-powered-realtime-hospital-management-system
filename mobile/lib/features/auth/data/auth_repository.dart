import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'app_user.dart';

/// Thrown by [AuthRepository.signIn] when the password was right but the
/// account has two-factor authentication on — the caller must follow up with
/// [AuthRepository.verifySecondFactor] to finish signing in.
class TwoFactorRequiredException implements Exception {
  @override
  String toString() => 'Enter the code from your authenticator app';
}

/// What `/two-factor/enable` hands back: the `otpauth://` URI to show as a
/// QR code, and one-time recovery codes.
class TotpEnrollment {
  const TotpEnrollment({required this.totpUri, required this.backupCodes});

  final String totpUri;
  final List<String> backupCodes;

  /// The base32 secret, for typing into an authenticator by hand.
  String get secret => Uri.parse(totpUri).queryParameters['secret'] ?? '';
}

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

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/sign-in/email',
        data: {'email': email, 'password': password},
      );
      final data = response.data;
      if (data is Map && data['twoFactorRedirect'] == true) {
        throw TwoFactorRequiredException();
      }
      return _userFromAuthResponse(response);
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  /// Completes a sign-in that [signIn] paused with
  /// [TwoFactorRequiredException], using either a 6-digit authenticator code
  /// or one of the recovery codes.
  Future<AppUser> verifySecondFactor(
    String code, {
    bool isBackupCode = false,
  }) async {
    try {
      final response = await _dio.post(
        isBackupCode
            ? '/api/auth/two-factor/verify-backup-code'
            : '/api/auth/two-factor/verify-totp',
        data: {'code': code, 'trustDevice': true},
      );
      return _userFromAuthResponse(response);
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  /// Starts 2FA enrollment. 2FA isn't switched on until the first code is
  /// confirmed with [confirmTotp].
  Future<TotpEnrollment> enableTwoFactor(String password) async {
    final data = await _post('/api/auth/two-factor/enable', {
      'password': password,
    });
    return TotpEnrollment(
      totpUri: data['totpURI'] as String,
      backupCodes: [
        for (final code in data['backupCodes'] as List) code.toString(),
      ],
    );
  }

  /// Confirms the first authenticator code, which turns 2FA on.
  Future<void> confirmTotp(String code) async {
    await _post('/api/auth/two-factor/verify-totp', {'code': code});
  }

  Future<void> disableTwoFactor(String password) async {
    await _post('/api/auth/two-factor/disable', {'password': password});
  }

  /// Replaces the recovery codes (the old ones stop working).
  Future<List<String>> regenerateBackupCodes(String password) async {
    final data = await _post('/api/auth/two-factor/generate-backup-codes', {
      'password': password,
    });
    return [for (final code in data['backupCodes'] as List) code.toString()];
  }

  Future<Map> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(path, data: body);
      ApiException.checkStatus(response);
      final data = response.data;
      return data is Map ? data : const {};
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/sign-up/email',
        data: {'name': name, 'email': email, 'password': password},
      );
      return _userFromAuthResponse(response);
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _dio.post('/api/auth/sign-out');
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
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
