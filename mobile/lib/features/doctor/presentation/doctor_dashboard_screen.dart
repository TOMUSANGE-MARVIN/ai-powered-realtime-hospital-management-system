import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../appointments/data/appointment.dart';
import '../../appointments/state/appointment_providers.dart';
import '../../auth/state/auth_controller.dart';
import '../state/doctor_providers.dart';

String _greetingName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return 'Doctor';
  final parts = fullName.trim().split(RegExp(r'\s+'));
  // Skip a leading title (e.g. "Dr.", "Prof.") so the greeting shows the
  // doctor's actual first name rather than just the honorific.
  final firstNonTitle = parts.firstWhere(
    (p) => !RegExp(r'^(Dr|Prof|Mr|Mrs|Ms)\.?$', caseSensitive: false).hasMatch(p),
    orElse: () => parts.first,
  );
  return firstNonTitle;
}

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    final earningsAsync = ref.watch(earningsProvider);
    final todaysAsync = ref.watch(todaysAssignedAppointmentsProvider);
    final requestsAsync = ref.watch(assignedRequestsProvider);
    final currencyFormat = NumberFormat.decimalPattern();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${_greetingName(userAsync.value?.name)}'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(earningsProvider);
          ref.invalidate(todaysAssignedAppointmentsProvider);
          ref.invalidate(assignedRequestsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earnings today',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    earningsAsync.when(
                      data: (earnings) => Text(
                        'UGX ${currencyFormat.format(earnings.today)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      loading: () => const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, _) => const Text('—'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Appointments", style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.go('/doctor-home/appointments'),
                  child: const Text('View all'),
                ),
              ],
            ),
            todaysAsync.when(
              data: (appointments) {
                if (appointments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No appointments scheduled for today.'),
                  );
                }
                return Column(
                  children: appointments
                      .map((a) => _AppointmentTile(appointment: a))
                      .toList(),
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )),
              error: (error, _) => Text(error.toString()),
            ),
            const SizedBox(height: 24),
            Text('Appointment Requests', style: Theme.of(context).textTheme.titleMedium),
            requestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No pending requests.'),
                  );
                }
                return Column(
                  children: requests
                      .map((a) => _RequestTile(appointment: a))
                      .toList(),
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )),
              error: (error, _) => Text(error.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(appointment.patientName ?? 'Patient'),
        subtitle: Text(appointment.time ?? DateFormat('MMM d').format(appointment.date)),
        trailing: Chip(label: Text(appointment.status)),
      ),
    );
  }
}

class _RequestTile extends ConsumerWidget {
  const _RequestTile({required this.appointment});

  final Appointment appointment;

  Future<void> _respond(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateAssigned(appointment.id, status: status);
      ref.invalidate(assignedRequestsProvider);
      ref.invalidate(todaysAssignedAppointmentsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(appointment.patientName ?? 'Patient',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (appointment.isEmergency)
                  Chip(
                    avatar: Icon(Icons.emergency,
                        size: 15, color: Theme.of(context).colorScheme.onError),
                    label: const Text('EMERGENCY'),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${dateFormat.format(appointment.date)}${appointment.time != null ? ' · ${appointment.time}' : ''}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _respond(context, ref, 'confirmed'),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(context, ref, 'cancelled'),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
