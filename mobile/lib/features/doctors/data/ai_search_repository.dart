import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'ai_search_result.dart';

class AiSearchRepository {
  AiSearchRepository(this._dio);

  final Dio _dio;

  Future<AiSearchResult> search(String symptoms) async {
    try {
      final response = await _dio.post(
        '/api/ai/symptom-search',
        data: {'symptoms': symptoms},
      );
      ApiException.checkStatus(response);
      return AiSearchResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // The endpoint can legitimately return 503 when the AI call itself
      // fails (e.g. no key configured) — Dio's validateStatus only lets
      // <500 through silently, so 5xx surfaces as a DioException here
      // rather than via ApiException.checkStatus.
      throw ApiException.fromDioError(e);
    }
  }
}
