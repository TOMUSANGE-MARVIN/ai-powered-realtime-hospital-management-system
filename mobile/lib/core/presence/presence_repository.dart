import 'package:dio/dio.dart';

import '../api/api_exception.dart';

class PresenceRepository {
  PresenceRepository(this._dio);

  final Dio _dio;

  Future<bool> isOnline(String userId) async {
    final response = await _dio.get('/api/users/$userId/online');
    ApiException.checkStatus(response);
    return (response.data as Map)['online'] as bool? ?? false;
  }
}
