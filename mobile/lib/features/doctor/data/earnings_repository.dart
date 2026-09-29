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

  Future<void> requestWithdrawal({
    required int amount,
    required String method,
    required String provider,
    required String accountName,
    required String accountNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/api/withdrawals',
        data: {
          'amount': amount,
          'method': method,
          'provider': provider,
          'accountName': accountName,
          'accountNumber': accountNumber,
        },
      );
      ApiException.checkStatus(response);
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }
}
