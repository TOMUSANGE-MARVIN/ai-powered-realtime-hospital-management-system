import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/providers.dart';
import '../../../core/offline/offline_first.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';

final _money = NumberFormat.decimalPattern();
String _ugx(int n) => 'UGX ${_money.format(n)}';

/// One past payment from `/api/payments/mine`.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.method,
    this.reference,
    this.voucherCode,
    this.discount = 0,
    this.tax = 0,
    this.refundStatus,
    this.refundAmount,
    this.doctorName,
    this.specialization,
    this.visitDate,
    this.visitTime,
  });

  final String id;
  final int amount;

  /// paid | failed | reversed
  final String status;
  final DateTime createdAt;
  final String? method;
  final String? reference;
  final String? voucherCode;
  final int discount;
  final int tax;
  final String? refundStatus;
  final int? refundAmount;
  final String? doctorName;
  final String? specialization;
  final DateTime? visitDate;
  final String? visitTime;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'] as Map<String, dynamic>?;
    final appt = json['appointment'] as Map<String, dynamic>?;
    return PaymentRecord(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      status: json['status'] as String? ?? 'paid',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      method: json['method'] as String?,
      reference: json['reference'] as String?,
      voucherCode: json['voucherCode'] as String?,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      tax: (json['tax'] as num?)?.toInt() ?? 0,
      refundStatus: json['refundStatus'] as String?,
      refundAmount: (json['refundAmount'] as num?)?.toInt(),
      doctorName: doctor?['name'] as String?,
      specialization: doctor?['specialization'] as String?,
      // Visit dates are stored as the booked wall-clock time; don't convert.
      visitDate: appt == null ? null : DateTime.parse(appt['date'] as String),
      visitTime: appt?['time'] as String?,
    );
  }

  String get statusLabel => switch (status) {
    'paid' when refundStatus == 'requested' => 'Refund in progress',
    'paid' => 'Paid',
    'reversed' => 'Refunded',
    'failed' => 'Failed',
    _ => status,
  };

  Color get statusColor => switch (status) {
    'paid' when refundStatus == 'requested' => const Color(0xFFFFA000),
    'paid' => seedTeal,
    'reversed' => const Color(0xFF0B5F60),
    _ => const Color(0xFFD32F2F),
  };

  /// Plain-text receipt for sharing or saving.
  String receipt() {
    final lines = [
      'Ask Musawo — payment receipt',
      '',
      'Date: ${DateFormat('d MMM yyyy, h:mm a').format(createdAt)}',
      if (doctorName != null) 'Doctor: $doctorName',
      if (visitDate != null)
        'Visit: ${DateFormat('EEE d MMM yyyy').format(visitDate!)}'
            '${visitTime != null ? ' at $visitTime' : ''}',
      if (discount > 0) 'Voucher: $voucherCode (−${_ugx(discount)})',
      if (tax > 0) 'Tax: ${_ugx(tax)}',
      'Total paid: ${_ugx(amount)}',
      if (method != null && method != 'pesapal') 'Method: $method',
      if (reference != null) 'Confirmation code: $reference',
      'Status: $statusLabel',
      if (refundAmount != null) 'Refund: ${_ugx(refundAmount!)}',
    ];
    return lines.join('\n');
  }
}

final myPaymentsProvider = FutureProvider.autoDispose<List<PaymentRecord>>(
  (ref) => offlineFirst(ref, () async {
    final dio = ref.watch(dioProvider);
    try {
      final response = await dio.get('/api/payments/mine');
      ApiException.checkStatus(response);
      return [
        for (final p in response.data as List)
          PaymentRecord.fromJson(p as Map<String, dynamic>),
      ];
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }),
);

/// A patient's consultation payments, with shareable receipts.
class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(myPaymentsProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Payments & Billing')),
      body: payments.when(
        loading: () => const SkeletonList(count: 5),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString()),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(myPaymentsProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No payments yet. Payments for booked consultations appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
              ),
            );
          }
          final spent = list
              .where((p) => p.status == 'paid')
              .fold<int>(0, (sum, p) => sum + p.amount);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myPaymentsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SoftCard(
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined, color: seedTeal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total paid',
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                            Text(
                              _ugx(spent),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final p in list) ...[
                  SoftCard(
                    padding: EdgeInsets.zero,
                    onTap: () => _showReceipt(context, p),
                    child: ListTile(
                      title: Text(
                        p.doctorName ?? 'Consultation',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        DateFormat('d MMM yyyy').format(p.createdAt) +
                            (p.voucherCode != null
                                ? ' · ${p.voucherCode}'
                                : ''),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _ugx(p.amount),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: p.statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReceipt(BuildContext context, PaymentRecord p) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Receipt',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SoftCard(
                child: SelectableText(
                  p.receipt(),
                  style: const TextStyle(height: 1.6),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text('Share receipt'),
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: p.receipt(),
                    subject: 'Ask Musawo payment receipt',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
