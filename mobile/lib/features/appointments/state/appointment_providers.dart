import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/appointment_repository.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.watch(dioProvider));
});

final myAppointmentsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(appointmentRepositoryProvider).listMine();
});
