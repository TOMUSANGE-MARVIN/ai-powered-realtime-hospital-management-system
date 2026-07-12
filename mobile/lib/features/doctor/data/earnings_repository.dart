import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'earnings.dart';

class EarningsRepository {
  EarningsRepository(this._dio);

  final Dio _dio;

  Future<Earnings> getMine() async {
    final response = await _dio.get('/api/earnings/mine');
    ApiException.checkStatus(response);
    return Earnings.fromJson(response.data as Map<String, dynamic>);
  }
}
