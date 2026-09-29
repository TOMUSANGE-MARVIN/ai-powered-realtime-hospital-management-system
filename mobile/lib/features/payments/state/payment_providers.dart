import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioProvider));
});

final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  return VoucherRepository(ref.watch(dioProvider));
});
