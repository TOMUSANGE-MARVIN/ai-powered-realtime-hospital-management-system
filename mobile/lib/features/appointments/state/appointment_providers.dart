import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/appointment_repository.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.watch(dioProvider));
});

final myAppointmentsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(appointmentRepositoryProvider).listMine();
});

/// Doctor dashboard/appointments: today's assigned appointments.
final todaysAssignedAppointmentsProvider = FutureProvider.autoDispose((ref) {
  final today = DateTime.now();
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  return ref.watch(appointmentRepositoryProvider).listAssigned(date: dateStr);
});

/// Doctor dashboard/appointments: pending appointment requests.
final assignedRequestsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(appointmentRepositoryProvider).listAssigned(status: 'requested');
});

/// Doctor appointments tab: full assigned list, unfiltered.
final allAssignedAppointmentsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(appointmentRepositoryProvider).listAssigned();
});
