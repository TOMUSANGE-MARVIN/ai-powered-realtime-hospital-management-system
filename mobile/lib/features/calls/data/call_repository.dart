import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'call_log.dart';

class CallRepository {
  CallRepository(this._dio);

  final Dio _dio;

  /// Logs the outcome of a call — called once, by the caller's device,
  /// once the terminal outcome/duration is known (see
  /// [CallController._finish]), so the Calls tab shows real history.
  Future<void> recordCall({
    required String calleeId,
    required String type,
    String status = 'answered',
    int? durationSeconds,
  }) async {
    final response = await _dio.post('/api/calls', data: {
      'calleeId': calleeId,
      'type': type,
      'status': status,
      'durationSeconds': ?durationSeconds,
    });
    ApiException.checkStatus(response);
  }

  Future<List<CallLogEntry>> listMine() async {
    final response = await _dio.get('/api/calls/mine');
    ApiException.checkStatus(response);
    final results = (response.data as Map)['res'] as List;
    return results
        .map((json) => CallLogEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
