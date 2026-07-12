import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'doctor.dart';

class DoctorRepository {
  DoctorRepository(this._dio);

  final Dio _dio;

  Future<List<Doctor>> listDoctors({
    String? search,
    String? specialization,
    bool featured = false,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/doctors',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (specialization != null && specialization != 'all') 'specialization': specialization,
        if (featured) 'featured': 'true',
        'limit': limit,
      },
    );
    ApiException.checkStatus(response);
    final results = (response.data as Map)['res'] as List;
    return results
        .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Specialty>> listSpecialties() async {
    final response = await _dio.get('/api/doctors/specialties');
    ApiException.checkStatus(response);
    final results = response.data as List;
    return results
        .map((json) => Specialty.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Doctor> getDoctor(String id) async {
    final response = await _dio.get('/api/doctors/$id');
    ApiException.checkStatus(response);
    return Doctor.fromJson(response.data as Map<String, dynamic>);
  }
}
