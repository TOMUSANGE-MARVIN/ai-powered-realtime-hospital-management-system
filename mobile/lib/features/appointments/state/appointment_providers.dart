import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/providers.dart';
import '../data/appointment_repository.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.watch(dioProvider));
});

// None of the providers below are autoDispose: they're unparameterized "my
// session" data, so keeping the last result cached across navigation avoids
// re-fetching (with a loading spinner) every time a screen remounts. Pull-
// to-refresh / explicit ref.invalidate still forces a real refetch.
final myAppointmentsProvider = FutureProvider((ref) {
  return ref.watch(appointmentRepositoryProvider).listMine();
});

/// Doctor dashboard/appointments: today's assigned appointments.
final todaysAssignedAppointmentsProvider = FutureProvider((ref) {
  final today = DateTime.now();
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  return ref.watch(appointmentRepositoryProvider).listAssigned(date: dateStr);
});

/// Doctor dashboard/appointments: pending appointment requests.
final assignedRequestsProvider = FutureProvider((ref) {
  return ref.watch(appointmentRepositoryProvider).listAssigned(status: 'requested');
});

/// Doctor appointments tab: full assigned list, unfiltered.
final allAssignedAppointmentsProvider = FutureProvider((ref) {
  return ref.watch(appointmentRepositoryProvider).listAssigned();
});
