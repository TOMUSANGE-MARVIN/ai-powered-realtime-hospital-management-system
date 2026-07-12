import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'call_log.dart';

class CallRepository {
  CallRepository(this._dio);

  final Dio _dio;

  /// Logs a call attempt. Voice/video calling itself is a UI-only stub for
  /// now (see chat_screen.dart) — this just records that it was attempted,
  /// so the Calls tab has real history.
  Future<void> recordCall({required String calleeId, required String type}) async {
    final response = await _dio.post('/api/calls', data: {'calleeId': calleeId, 'type': type});
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
