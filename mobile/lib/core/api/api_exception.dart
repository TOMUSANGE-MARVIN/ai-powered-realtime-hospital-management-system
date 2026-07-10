import 'package:dio/dio.dart';

/// Normalizes backend error responses (`{ "message": "..." }`) and network
/// failures into a single user-displayable string.
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  factory ApiException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return ApiException(data['message'] as String);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException('Could not reach the server. Check your connection.');
    }
    return ApiException(error.message ?? 'Something went wrong');
  }

  @override
  String toString() => message;

  /// Throws when a response was allowed through (status < 500) but still
  /// represents a client error (4xx), since [Dio]'s `validateStatus` is
  /// configured to not treat those as exceptions on their own.
  static void checkStatus(Response response) {
    final status = response.statusCode ?? 0;
    if (status < 400) return;
    final data = response.data;
    if (data is Map && data['message'] is String) {
      throw ApiException(data['message'] as String);
    }
    throw ApiException('Request failed with status $status');
  }
}
