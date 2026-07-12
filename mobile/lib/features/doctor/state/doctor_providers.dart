import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/doctor_prescription_repository.dart';
import '../data/earnings_repository.dart';

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return EarningsRepository(ref.watch(dioProvider));
});

final earningsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(earningsRepositoryProvider).getMine();
});

final doctorPrescriptionRepositoryProvider =
    Provider<DoctorPrescriptionRepository>((ref) {
  return DoctorPrescriptionRepository(ref.watch(dioProvider));
});
