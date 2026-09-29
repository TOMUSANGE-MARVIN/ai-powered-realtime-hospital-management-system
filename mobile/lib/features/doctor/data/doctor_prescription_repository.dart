import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'prescription_item_input.dart';

class DoctorPrescriptionRepository {
  DoctorPrescriptionRepository(this._dio);

  final Dio _dio;

  Future<void> create({
    required String patientId,
    required String patientName,
    required List<PrescriptionItemInput> items,
    String? notes,
    String? imageUrl,
    String? signatureUrl,
    String? appointmentId,
    String? licenseNo,
    String? dateIssued,
  }) async {
    final response = await _dio.post(
      '/api/prescriptions',
      data: {
        'patient': patientId,
        'patientName': patientName,
        'items': items.map((i) => i.toJson()).toList(),
        'notes': ?notes,
        'imageUrl': ?imageUrl,
        'signatureUrl': ?signatureUrl,
        'appointmentId': ?appointmentId,
        'licenseNo': ?licenseNo,
        'dateIssued': ?dateIssued,
      },
    );
    ApiException.checkStatus(response);
  }

  /// Reads a photographed prescription (uploaded to /api/uploads first).
  Future<ExtractedPrescription> extract(String imageUrl) async {
    try {
      final response = await _dio.post(
        '/api/prescriptions/extract',
        data: {'imageUrl': imageUrl},
      );
      ApiException.checkStatus(response);
      return ExtractedPrescription.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }
}

/// What the AI read off a prescription photo. Every field may be null; the
/// doctor confirms or corrects each one before sending.
class ExtractedPrescription {
  const ExtractedPrescription({
    required this.goodQuality,
    required this.medications,
    this.dateIssued,
    this.doctorName,
    this.licenseNo,
    this.patientName,
  });

  final bool goodQuality;
  final DateTime? dateIssued;
  final String? doctorName;
  final String? licenseNo;
  final String? patientName;
  final List<PrescriptionItemInput> medications;

  factory ExtractedPrescription.fromJson(Map<String, dynamic> json) {
    return ExtractedPrescription(
      goodQuality: json['quality'] != 'poor',
      dateIssued: DateTime.tryParse(json['dateIssued'] as String? ?? ''),
      doctorName: json['doctorName'] as String?,
      licenseNo: json['licenseNo'] as String?,
      patientName: json['patientName'] as String?,
      medications: [
        for (final m in json['medications'] as List? ?? const [])
          PrescriptionItemInput(
            medicationName: m['name'] as String,
            dosage: m['dosage'] as String? ?? '',
            quantity: (m['quantity'] as num?)?.toInt() ?? 1,
            instructions: m['instructions'] as String?,
          ),
      ],
    );
  }
}
