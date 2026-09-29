import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/doctor_prescription_repository.dart';
import '../data/earnings_repository.dart';
import '../data/patient_history.dart';

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return EarningsRepository(ref.watch(dioProvider));
});

final earningsProvider = FutureProvider((ref) {
  return ref.watch(earningsRepositoryProvider).getMine();
});

final doctorPrescriptionRepositoryProvider =
    Provider<DoctorPrescriptionRepository>((ref) {
      return DoctorPrescriptionRepository(ref.watch(dioProvider));
    });

final patientHistoryRepositoryProvider = Provider<PatientHistoryRepository>((
  ref,
) {
  return PatientHistoryRepository(ref.watch(dioProvider));
});

final patientHistoryProvider = FutureProvider.autoDispose
    .family<PatientHistory, String>((ref, patientId) {
      return ref.watch(patientHistoryRepositoryProvider).getHistory(patientId);
    });
