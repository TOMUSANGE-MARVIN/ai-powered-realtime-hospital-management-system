import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../../../core/offline/offline_first.dart';
import '../../appointments/state/appointment_providers.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

final myMedicalDocumentsProvider = FutureProvider((ref) {
  return offlineFirst(
    ref,
    () => ref.watch(profileRepositoryProvider).listMyDocuments(),
  );
});

final myPrescriptionsProvider = FutureProvider((ref) {
  return offlineFirst(
    ref,
    () => ref.watch(profileRepositoryProvider).listMyPrescriptions(),
  );
});

final myActiveInvoiceProvider = FutureProvider((ref) {
  return offlineFirst(
    ref,
    () => ref.watch(profileRepositoryProvider).getActiveInvoice(),
  );
});

/// Completed appointments only, for the "Consultation History" section.
final myConsultationHistoryProvider = FutureProvider((ref) async {
  final appointments = await ref.watch(myAppointmentsProvider.future);
  return appointments.where((a) => a.status == 'completed').toList();
});
