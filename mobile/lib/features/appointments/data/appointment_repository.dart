import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'appointment.dart';

class AppointmentRepository {
  AppointmentRepository(this._dio);

  final Dio _dio;

  Future<List<Appointment>> listMine() async {
    final response = await _dio.get('/api/appointments/mine');
    ApiException.checkStatus(response);
    final results = (response.data as Map)['res'] as List;
    return results
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> book({
    required String doctorId,
    required DateTime date,
    String? time,
    String? reason,
    required String consultationType,
  }) async {
    final response = await _dio.post(
      '/api/appointments/book',
      data: {
        'doctorId': doctorId,
        'date': date.toIso8601String(),
        'time': ?time,
        'reason': ?reason,
        'consultationType': consultationType,
      },
    );
    ApiException.checkStatus(response);
  }

  Future<void> cancel(String appointmentId) async {
    final response = await _dio.patch('/api/appointments/$appointmentId/cancel');
    ApiException.checkStatus(response);
  }
}
