import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'review.dart';

class ReviewRepository {
  ReviewRepository(this._dio);

  final Dio _dio;

  Future<DoctorReviews> listForDoctor(String doctorId, {int limit = 20}) async {
    final response = await _dio.get(
      '/api/reviews/doctor/$doctorId',
      queryParameters: {'limit': limit},
    );
    ApiException.checkStatus(response);
    return DoctorReviews.fromJson(response.data as Map<String, dynamic>);
  }

  /// The signed-in doctor's own reviews, for the reply screen.
  Future<DoctorReviews> listMine({int limit = 50}) async {
    final response = await _dio.get('/api/reviews/mine', queryParameters: {'limit': limit});
    ApiException.checkStatus(response);
    return DoctorReviews.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> reply({required String reviewId, required String reply}) async {
    final response = await _dio.post('/api/reviews/$reviewId/reply', data: {'reply': reply});
    ApiException.checkStatus(response);
  }

  /// Rate a completed appointment. Re-submitting replaces the earlier review.
  Future<void> submit({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    final response = await _dio.post(
      '/api/reviews',
      data: {
        'appointmentId': appointmentId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    ApiException.checkStatus(response);
  }
}
