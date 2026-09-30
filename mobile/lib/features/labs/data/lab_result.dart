import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';

/// A lab result (X-ray, blood test, …). Patients only receive reviewed ones,
/// without the AI analysis; doctors see everything in Full History.
class LabResult {
  const LabResult({
    required this.id,
    required this.testType,
    required this.createdAt,
    this.bodyPart,
    this.imageUrl,
    this.doctorNotes,
    this.aiAnalysis,
    this.status,
  });

  final String id;
  final String testType;
  final String? bodyPart;
  final String? imageUrl;
  final String? doctorNotes;
  final String? aiAnalysis;

  /// pending | analyzed | reviewed
  final String? status;
  final DateTime createdAt;

  String get title => bodyPart == null ? testType : '$testType · $bodyPart';

  factory LabResult.fromJson(Map<String, dynamic> json) => LabResult(
    id: json['id'] as String,
    testType: json['testType'] as String? ?? 'Lab test',
    bodyPart: json['bodyPart'] as String?,
    imageUrl: json['imageUrl'] as String?,
    doctorNotes: json['doctorNotes'] as String?,
    aiAnalysis: json['aiAnalysis'] as String?,
    status: json['status'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
  );
}

final myLabResultsProvider = FutureProvider.autoDispose<List<LabResult>>((
  ref,
) async {
  try {
    final response = await ref.watch(dioProvider).get('/api/lab-results/mine');
    ApiException.checkStatus(response);
    return [
      for (final r in response.data as List)
        LabResult.fromJson(r as Map<String, dynamic>),
    ];
  } on DioException catch (error) {
    throw ApiException.fromDioError(error);
  }
});
