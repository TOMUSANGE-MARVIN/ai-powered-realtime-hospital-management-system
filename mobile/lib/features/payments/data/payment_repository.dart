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

  /// [booking] is stored with the payment so the server can book the
  /// appointment itself once Pesapal confirms, even if the app is closed.
  Future<Payment> initiate({
    required String doctorId,
    String? voucherCode,
    Map<String, dynamic>? booking,
  }) async {
    final response = await _dio.post(
      '/api/payments/initiate',
      data: {
        'doctorId': doctorId,
        'voucherCode': ?voucherCode,
        'booking': ?booking,
      },
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

/// Server price for a consultation: voucher discount, tax and total.
class PriceQuote {
  const PriceQuote({
    required this.discount,
    required this.tax,
    required this.total,
    this.voucherCode,
  });

  final String? voucherCode;
  final int discount;
  final int tax;
  final int total;

  factory PriceQuote.fromJson(Map<String, dynamic> json) => PriceQuote(
    voucherCode: json['voucherCode'] as String?,
    discount: (json['discount'] as num?)?.toInt() ?? 0,
    tax: (json['tax'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );
}

class PricingRepository {
  PricingRepository(this._dio);

  final Dio _dio;

  /// Price without a voucher (shows tax up front).
  Future<PriceQuote> quote(String doctorId) => _call(
    () => _dio.get(
      '/api/payments/quote',
      queryParameters: {'doctorId': doctorId},
    ),
  );

  /// Price with [code] applied; throws [ApiException] if it can't be used.
  Future<PriceQuote> applyVoucher({
    required String code,
    required String doctorId,
  }) => _call(
    () => _dio.post(
      '/api/vouchers/validate',
      data: {'code': code, 'doctorId': doctorId},
    ),
  );

  Future<PriceQuote> _call(Future<Response> Function() request) async {
    try {
      final response = await request();
      ApiException.checkStatus(response);
      return PriceQuote.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }
}
