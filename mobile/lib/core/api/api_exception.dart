import 'package:dio/dio.dart';

/// Normalizes backend error responses (`{ "message": "..." }`) and network
/// failures into a single user-displayable string.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;

  /// The HTTP status when the server answered with an error (e.g. 429 when
  /// rate limited); null for network failures.
  final int? statusCode;

  factory ApiException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return ApiException(data['message'] as String);
    }
    if (error.type == DioExceptionType.connectionError) {
      // Covers DNS failures (SocketException: Failed host lookup) and other
      // low-level socket errors, which otherwise surface Dio's raw
      // exception text (e.g. "SocketException: No address associated with
      // hostname") straight to the UI.
      return ApiException(
        "You're offline. This needs an internet connection — try again once you're back online.",
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        'The connection timed out. Check your internet connection and try again.',
      );
    }
    if (error.type == DioExceptionType.cancel) {
      return ApiException('Request was cancelled.');
    }
    return ApiException('Something went wrong. Please try again.');
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
      throw ApiException(data['message'] as String, statusCode: status);
    }
    throw ApiException(
      'Request failed with status $status',
      statusCode: status,
    );
  }
}
