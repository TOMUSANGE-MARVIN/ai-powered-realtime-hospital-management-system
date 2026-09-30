import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/widgets/skeleton.dart';
import '../../appointments/data/appointment.dart';
import '../../appointments/state/appointment_providers.dart';
import '../../calls/state/call_controller.dart';
import '../../chat/data/chat_args.dart';
import 'appointment_dialogs.dart';

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
    extends ConsumerState<DoctorAppointmentsScreen> {
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
                _FilterChip(
                  label: 'All',
                  value: 'all',
                  selected: _filter,
                  onSelect: (v) => setState(() => _filter = v),
                ),
                _FilterChip(
                  label: 'Requested',
                  value: 'requested',
                  selected: _filter,
                  onSelect: (v) => setState(() => _filter = v),
                ),
                _FilterChip(
                  label: 'Confirmed',
                  value: 'confirmed',
                  selected: _filter,
                  onSelect: (v) => setState(() => _filter = v),
                ),
                _FilterChip(
                  label: 'In progress',
                  value: 'in_progress',
                  selected: _filter,
                  onSelect: (v) => setState(() => _filter = v),
                ),
                _FilterChip(
                  label: 'Completed',
                  value: 'completed',
                  selected: _filter,
                  onSelect: (v) => setState(() => _filter = v),
                ),
                _FilterChip(
                  label: 'Cancelled',
                  value: 'cancelled',
                  selected: _filter,
                  onSelect: (v) => setState(() => _filter = v),
                ),
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
                  onRefresh: () =>
                      ref.refresh(allAssignedAppointmentsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _DoctorAppointmentCard(appointment: filtered[index]),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonCardList(cardHeight: 110),
              ),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelect,
  });

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

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String? status, {
    String? notes,
    String? cancellationReason,
  }) async {
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateAssigned(
            appointment.id,
            status: status,
            notes: notes,
            cancellationReason: cancellationReason,
          );
      ref.invalidate(allAssignedAppointmentsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  bool get _isCallVisit =>
      appointment.consultationType == 'voice' ||
      appointment.consultationType == 'video';

  void _call(WidgetRef ref) {
    ref
        .read(callControllerProvider.notifier)
        .startOutgoingCall(
          appointment.patientId!,
          appointment.patientName ?? 'Patient',
          isVideo: appointment.consultationType == 'video',
        );
  }

  /// Marks the visit in progress and, for video / voice visits, rings the
  /// patient straight away.
  Future<void> _start(BuildContext context, WidgetRef ref) async {
    await _updateStatus(context, ref, 'in_progress');
    if (_isCallVisit && appointment.patientId != null) _call(ref);
  }

  Future<void> _end(BuildContext context, WidgetRef ref) async {
    final summary = await askVisitSummary(
      context,
      patientName: appointment.patientName ?? 'The patient',
      initial: appointment.notes,
      action: 'End consultation',
    );
    if (summary == null || !context.mounted) return;
    await _updateStatus(
      context,
      ref,
      'completed',
      notes: summary.isEmpty ? null : summary,
    );
  }

  Future<void> _editSummary(BuildContext context, WidgetRef ref) async {
    final summary = await askVisitSummary(
      context,
      patientName: appointment.patientName ?? 'The patient',
      initial: appointment.notes,
      action: 'Save summary',
    );
    if (summary == null || !context.mounted) return;
    await _updateStatus(context, ref, null, notes: summary);
  }

  Future<void> _cancelWithReason(
    BuildContext context,
    WidgetRef ref, {
    required bool isReject,
  }) async {
    final reason = await askCancellationReason(
      context,
      patientName: appointment.patientName ?? 'the patient',
      isReject: isReject,
    );
    if (reason == null || !context.mounted) return;
    await _updateStatus(
      context,
      ref,
      'cancelled',
      cancellationReason: reason.isEmpty ? null : reason,
    );
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final date = await showDatePicker(
      context: context,
      initialDate: appointment.date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!context.mounted) return;
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateAssigned(
            appointment.id,
            date: date,
            time: time?.format(context),
          );
      ref.invalidate(allAssignedAppointmentsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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
                  child: Text(
                    appointment.patientName ?? 'Patient',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Chip(
                  label: Text(appointment.status),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${dateFormat.format(appointment.date)}${appointment.time != null ? ' · ${appointment.time}' : ''}',
            ),
            if (appointment.reason != null) ...[
              const SizedBox(height: 4),
              Text(
                appointment.reason!,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (appointment.isPending) ...[
                  FilledButton(
                    onPressed: () => _updateStatus(context, ref, 'confirmed'),
                    child: const Text('Accept'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _cancelWithReason(context, ref, isReject: true),
                    child: const Text('Reject'),
                  ),
                ],
                if (appointment.status == 'confirmed') ...[
                  OutlinedButton(
                    onPressed: () => _reschedule(context, ref),
                    child: const Text('Reschedule'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _cancelWithReason(context, ref, isReject: false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    icon: Icon(
                      _isCallVisit
                          ? (appointment.consultationType == 'video'
                                ? Icons.videocam_outlined
                                : Icons.call_outlined)
                          : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    onPressed: () => _start(context, ref),
                    label: const Text('Start consultation'),
                  ),
                ],
                if (appointment.status == 'in_progress') ...[
                  if (_isCallVisit && appointment.patientId != null)
                    OutlinedButton.icon(
                      icon: Icon(
                        appointment.consultationType == 'video'
                            ? Icons.videocam_outlined
                            : Icons.call_outlined,
                        size: 16,
                      ),
                      onPressed: () => _call(ref),
                      label: const Text('Call patient'),
                    ),
                  FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    onPressed: () => _end(context, ref),
                    label: const Text('End consultation'),
                  ),
                ],
                if (appointment.status == 'completed')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.notes_rounded, size: 16),
                    onPressed: () => _editSummary(context, ref),
                    label: Text(
                      appointment.notes?.isNotEmpty == true
                          ? 'Edit summary'
                          : 'Add summary',
                    ),
                  ),
                if ((appointment.status == 'completed' ||
                        appointment.status == 'in_progress') &&
                    appointment.patientId != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long, size: 16),
                    onPressed: () => context.push(
                      '/doctor-home/prescriptions/new',
                      extra: {
                        'patientId': appointment.patientId,
                        'patientName': appointment.patientName,
                        'appointmentId': appointment.id,
                      },
                    ),
                    label: const Text('Write Prescription'),
                  ),
                if (appointment.patientId != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.history, size: 16),
                    onPressed: () => context.push(
                      '/patients/${appointment.patientId}/history',
                    ),
                    label: const Text('Full History'),
                  ),
                if (appointment.patientId != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    onPressed: () => context.push(
                      '/chat/${appointment.patientId}',
                      extra: ChatArgs(
                        name: appointment.patientName ?? 'Patient',
                      ),
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
