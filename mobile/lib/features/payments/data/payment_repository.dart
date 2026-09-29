import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';

class Payment {
  Payment({
    required this.id,
    required this.amount,
    required this.status,
    this.currency = 'UGX',
    this.method,
    this.reference,
    this.redirectUrl,
  });

  final String id;
  final int amount;
  final String currency;

  /// pending | paid | failed | reversed
  final String status;

  /// Pesapal's payment method once paid (e.g. "MTN UG", "Visa").
  final String? method;
  final String? reference;

  /// Pesapal hosted checkout URL — only present right after [PaymentRepository.initiate].
  final String? redirectUrl;

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: (json['id'] ?? json['_id']).toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'UGX',
      status: json['status'] as String? ?? 'pending',
      method: json['method'] as String?,
      reference: json['reference'] as String?,
      redirectUrl: json['redirectUrl'] as String?,
    );
  }
}

/// Pay-before-book through Pesapal. [initiate] creates the order and returns
/// the hosted checkout URL; the patient pays there (card or mobile money) and
/// [status] reports the result the backend got from Pesapal.
class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  /// Path Pesapal redirects to after checkout — the WebView closes on it.
  static const callbackPath = '/api/payments/pesapal/callback';

  Future<Payment> initiate({
    required String doctorId,
    String? voucherCode,
  }) async {
    final response = await _dio.post(
      '/api/payments/initiate',
      data: {'doctorId': doctorId, 'voucherCode': ?voucherCode},
    );
    ApiException.checkStatus(response);
    return Payment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Payment> status(String paymentId) async {
    final response = await _dio.get('/api/payments/$paymentId/status');
    ApiException.checkStatus(response);
    return Payment.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Result of checking a voucher code against a doctor's fee.
class VoucherQuote {
  const VoucherQuote({
    required this.code,
    required this.discount,
    required this.total,
  });

  final String code;
  final int discount;
  final int total;
}

class VoucherRepository {
  VoucherRepository(this._dio);

  final Dio _dio;

  Future<VoucherQuote> validate({
    required String code,
    required String doctorId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/vouchers/validate',
        data: {'code': code, 'doctorId': doctorId},
      );
      ApiException.checkStatus(response);
      final data = response.data as Map<String, dynamic>;
      return VoucherQuote(
        code: data['code'] as String,
        discount: (data['discount'] as num).toInt(),
        total: (data['total'] as num).toInt(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }
}
