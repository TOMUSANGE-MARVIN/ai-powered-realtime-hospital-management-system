import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';

class InitiatedPayment {
  InitiatedPayment({required this.id, required this.amount, required this.status});

  final String id;
  final int amount;
  final String status;

  factory InitiatedPayment.fromJson(Map<String, dynamic> json) {
    return InitiatedPayment(
      id: (json['id'] ?? json['_id']).toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

/// Pay-before-book flow. Currently backed by the backend's simulated rail;
/// when a real provider (e.g. MarzPay) lands, initiate triggers the actual
/// MoMo prompt and confirm becomes a status poll — this API stays the same.
class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  Future<InitiatedPayment> initiate({
    required String doctorId,
    required String method,
    required String phoneNumber,
  }) async {
    final response = await _dio.post(
      '/api/payments/initiate',
      data: {'doctorId': doctorId, 'method': method, 'phoneNumber': phoneNumber},
    );
    ApiException.checkStatus(response);
    return InitiatedPayment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<InitiatedPayment> confirm(String paymentId) async {
    final response = await _dio.post('/api/payments/$paymentId/confirm');
    ApiException.checkStatus(response);
    return InitiatedPayment.fromJson(response.data as Map<String, dynamic>);
  }
}
