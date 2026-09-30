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
    this.requestedBy,
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

  /// Name of the doctor who ordered the test (patient view only).
  final String? requestedBy;

  /// Ordered by a doctor, but no sample or image yet.
  bool get isRequested => status == 'pending' && (imageUrl ?? '').isEmpty;

  String get title => bodyPart == null ? testType : '$testType · $bodyPart';

  factory LabResult.fromJson(Map<String, dynamic> json) => LabResult(
    id: json['id'] as String,
    testType: json['testType'] as String? ?? 'Lab test',
    bodyPart: json['bodyPart'] as String?,
    imageUrl: (json['imageUrl'] as String?)?.nonEmpty,
    doctorNotes: json['doctorNotes'] as String?,
    aiAnalysis: json['aiAnalysis'] as String?,
    status: json['status'] as String?,
    requestedBy: json['requestedBy'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
  );
}

extension on String {
  String? get nonEmpty => isEmpty ? null : this;
}

/// Test types a doctor can order; the same list as the web Test Requests page.
const labTestTypes = [
  'Blood Test',
  'Urinalysis',
  'X-Ray',
  'MRI',
  'CT Scan',
  'Other',
];

/// A doctor orders a lab test for a patient (`POST /api/lab-results`). It
/// shows up on the web Test Requests page and the patient is notified.
Future<void> requestLabTest(
  Dio dio, {
  required String patientId,
  required String testType,
  String? notes,
}) async {
  try {
    final response = await dio.post(
      '/api/lab-results',
      data: {
        'patientId': patientId,
        'testType': testType,
        if (notes != null && notes.isNotEmpty) 'bodyPart': notes,
      },
    );
    ApiException.checkStatus(response);
  } on DioException catch (error) {
    throw ApiException.fromDioError(error);
  }
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
