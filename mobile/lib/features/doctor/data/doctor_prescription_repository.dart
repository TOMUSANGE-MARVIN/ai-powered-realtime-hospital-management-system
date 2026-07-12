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
      },
    );
    ApiException.checkStatus(response);
  }
}
