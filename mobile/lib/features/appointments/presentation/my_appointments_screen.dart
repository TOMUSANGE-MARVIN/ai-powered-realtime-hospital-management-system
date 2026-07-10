import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../data/appointment.dart';
import '../state/appointment_providers.dart';

class MyAppointmentsScreen extends ConsumerWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return const Center(child: Text('No appointments yet — book one from the Doctors tab.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myAppointmentsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _AppointmentCard(appointment: appointments[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text('Cancel your appointment with ${appointment.doctorName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(appointmentRepositoryProvider).cancel(appointment.id);
      ref.invalidate(myAppointmentsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(appointment.doctorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Chip(
                  label: Text(appointment.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: _statusColor(appointment.status),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${dateFormat.format(appointment.date)}'
              '${appointment.time != null ? ' · ${appointment.time}' : ''}',
            ),
            if (appointment.reason != null) ...[
              const SizedBox(height: 4),
              Text(appointment.reason!, style: TextStyle(color: Colors.grey.shade600)),
            ],
            if (appointment.isCancellable) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _cancel(context, ref),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
