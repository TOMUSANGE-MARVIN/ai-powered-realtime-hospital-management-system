import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/data/app_user.dart';
import 'active_invoice.dart';
import 'medical_document.dart';
import 'patient_prescription.dart';

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<AppUser> updateMe(Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/users/me', data: data);
    ApiException.checkStatus(response);
    return AppUser.fromJson((response.data as Map)['updatedUser'] as Map<String, dynamic>);
  }

  Future<void> deleteMe() async {
    final response = await _dio.delete('/api/users/me');
    ApiException.checkStatus(response);
  }

  Future<List<MedicalDocument>> listMyDocuments() async {
    final response = await _dio.get('/api/medical-documents/mine');
    ApiException.checkStatus(response);
    return (response.data as List)
        .map((json) => MedicalDocument.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> uploadDocument({required String title, required String url}) async {
    final response = await _dio.post(
      '/api/medical-documents',
      data: {'title': title, 'url': url},
    );
    ApiException.checkStatus(response);
  }

  Future<List<PatientPrescription>> listMyPrescriptions() async {
    final response = await _dio.get('/api/prescriptions/mine');
    ApiException.checkStatus(response);
    final results = (response.data as Map)['res'] as List;
    return results
        .map((json) => PatientPrescription.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ActiveInvoice?> getActiveInvoice() async {
    final response = await _dio.get('/api/invoices/my-active-invoice');
    if (response.statusCode == 404) return null;
    ApiException.checkStatus(response);
    return ActiveInvoice.fromJson(response.data as Map<String, dynamic>);
  }
}
