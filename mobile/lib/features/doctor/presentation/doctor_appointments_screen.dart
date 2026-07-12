import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../appointments/data/appointment.dart';
import '../../appointments/state/appointment_providers.dart';
import '../../chat/data/chat_args.dart';

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(allAssignedAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(label: 'All', value: 'all', selected: _filter, onSelect: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'Requested', value: 'requested', selected: _filter, onSelect: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'Confirmed', value: 'confirmed', selected: _filter, onSelect: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'Completed', value: 'completed', selected: _filter, onSelect: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'Cancelled', value: 'cancelled', selected: _filter, onSelect: (v) => setState(() => _filter = v)),
              ],
            ),
          ),
          Expanded(
            child: appointmentsAsync.when(
              data: (appointments) {
                final filtered = _filter == 'all'
                    ? appointments
                    : appointments.where((a) => a.status == _filter).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No appointments here.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(allAssignedAppointmentsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _DoctorAppointmentCard(appointment: filtered[index]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.value, required this.selected, required this.onSelect});

  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected == value,
        onSelected: (_) => onSelect(value),
      ),
    );
  }
}

class _DoctorAppointmentCard extends ConsumerWidget {
  const _DoctorAppointmentCard({required this.appointment});

  final Appointment appointment;

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(appointmentRepositoryProvider).updateAssigned(appointment.id, status: status);
      ref.invalidate(allAssignedAppointmentsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final date = await showDatePicker(
      context: context,
      initialDate: appointment.date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (!context.mounted) return;
    try {
      await ref.read(appointmentRepositoryProvider).updateAssigned(
            appointment.id,
            date: date,
            time: time?.format(context),
          );
      ref.invalidate(allAssignedAppointmentsProvider);
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
                  child: Text(appointment.patientName ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Chip(label: Text(appointment.status), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${dateFormat.format(appointment.date)}${appointment.time != null ? ' · ${appointment.time}' : ''}',
            ),
            if (appointment.reason != null) ...[
              const SizedBox(height: 4),
              Text(appointment.reason!, style: TextStyle(color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (appointment.isPending) ...[
                  FilledButton(onPressed: () => _updateStatus(context, ref, 'confirmed'), child: const Text('Accept')),
                  OutlinedButton(onPressed: () => _updateStatus(context, ref, 'cancelled'), child: const Text('Reject')),
                ],
                if (appointment.status == 'confirmed') ...[
                  OutlinedButton(onPressed: () => _reschedule(context, ref), child: const Text('Reschedule')),
                  OutlinedButton(onPressed: () => _updateStatus(context, ref, 'cancelled'), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: () => _updateStatus(context, ref, 'completed'),
                    child: const Text('Mark completed'),
                  ),
                ],
                if (appointment.status == 'completed' && appointment.patientId != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long, size: 16),
                    onPressed: () => context.push(
                      '/doctor-home/prescriptions/new',
                      extra: {'patientId': appointment.patientId, 'patientName': appointment.patientName},
                    ),
                    label: const Text('Write Prescription'),
                  ),
                if (appointment.patientId != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    onPressed: () => context.push(
                      '/chat/${appointment.patientId}',
                      extra: ChatArgs(name: appointment.patientName ?? 'Patient'),
                    ),
                    label: const Text('Message'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
