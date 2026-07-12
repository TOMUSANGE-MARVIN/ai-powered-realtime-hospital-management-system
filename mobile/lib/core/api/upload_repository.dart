import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_exception.dart';

class UploadRepository {
  UploadRepository(this._dio);

  final Dio _dio;

  Future<String> uploadFile(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    return _upload(formData);
  }

  Future<String> uploadBytes(Uint8List bytes, {required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    return _upload(formData);
  }

  Future<String> _upload(FormData formData) async {
    final response = await _dio.post('/api/uploads', data: formData);
    ApiException.checkStatus(response);
    return (response.data as Map)['url'] as String;
  }
}
