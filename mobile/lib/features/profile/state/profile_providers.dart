import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../../appointments/state/appointment_providers.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

final myMedicalDocumentsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(profileRepositoryProvider).listMyDocuments();
});

final myPrescriptionsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(profileRepositoryProvider).listMyPrescriptions();
});

final myActiveInvoiceProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(profileRepositoryProvider).getActiveInvoice();
});

/// Completed appointments only, for the "Consultation History" section.
final myConsultationHistoryProvider = FutureProvider.autoDispose((ref) async {
  final appointments = await ref.watch(myAppointmentsProvider.future);
  return appointments.where((a) => a.status == 'completed').toList();
});
