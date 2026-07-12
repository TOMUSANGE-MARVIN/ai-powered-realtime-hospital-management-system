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
    bool isEmergency = false,
    String? paymentId,
  }) async {
    final response = await _dio.post(
      '/api/appointments/book',
      data: {
        'doctorId': doctorId,
        'date': date.toIso8601String(),
        'time': ?time,
        'reason': ?reason,
        'consultationType': consultationType,
        'isEmergency': isEmergency,
        'paymentId': ?paymentId,
      },
    );
    ApiException.checkStatus(response);
  }

  Future<void> cancel(String appointmentId) async {
    final response = await _dio.patch('/api/appointments/$appointmentId/cancel');
    ApiException.checkStatus(response);
  }

  /// Doctor's own assigned appointments. [status] filters (e.g. "requested"
  /// for pending requests); [date] filters to a single day (yyyy-MM-dd).
  Future<List<Appointment>> listAssigned({String? status, String? date}) async {
    final response = await _dio.get(
      '/api/appointments/assigned',
      queryParameters: {
        'status': ?status,
        'date': ?date,
        'limit': 50,
      },
    );
    ApiException.checkStatus(response);
    final results = (response.data as Map)['res'] as List;
    return results
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Doctor updating one of their assigned appointments — accept/reject
  /// (status), reschedule (date/time), etc.
  Future<void> updateAssigned(
    String appointmentId, {
    String? status,
    DateTime? date,
    String? time,
  }) async {
    final response = await _dio.put(
      '/api/appointments/$appointmentId',
      data: {
        'status': ?status,
        if (date != null) 'date': date.toIso8601String(),
        'time': ?time,
      },
    );
    ApiException.checkStatus(response);
  }
}
