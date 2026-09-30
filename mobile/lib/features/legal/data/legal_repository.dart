import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../../../core/offline/offline_first.dart';

/// Terms of Service, Privacy Policy and the telemedicine consent wording,
/// as currently published. Terms and Privacy share one [version]; when an
/// admin publishes a new one, everyone is asked to accept again.
class LegalDocuments {
  const LegalDocuments({
    required this.version,
    required this.updatedAt,
    required this.terms,
    required this.privacy,
    required this.telemedicineConsent,
  });

  final String version;
  final DateTime updatedAt;
  final String terms;
  final String privacy;
  final String telemedicineConsent;

  factory LegalDocuments.fromJson(Map<String, dynamic> json) => LegalDocuments(
    version: json['version'] as String,
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    terms: json['terms'] as String? ?? '',
    privacy: json['privacy'] as String? ?? '',
    telemedicineConsent: json['telemedicineConsent'] as String? ?? '',
  );
}

class LegalRepository {
  LegalRepository(this._dio);

  final Dio _dio;

  Future<LegalDocuments> fetch() async {
    try {
      final response = await _dio.get('/api/legal');
      ApiException.checkStatus(response);
      return LegalDocuments.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  Future<void> accept(String version) async {
    try {
      final response = await _dio.post(
        '/api/legal/accept',
        data: {'version': version},
      );
      ApiException.checkStatus(response);
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }
}

final legalRepositoryProvider = Provider<LegalRepository>(
  (ref) => LegalRepository(ref.watch(dioProvider)),
);

/// Not autoDispose: the router reads it to decide whether to ask the user
/// to accept an updated version.
final legalDocumentsProvider = FutureProvider<LegalDocuments>(
  (ref) => offlineFirst(ref, () => ref.watch(legalRepositoryProvider).fetch()),
);
