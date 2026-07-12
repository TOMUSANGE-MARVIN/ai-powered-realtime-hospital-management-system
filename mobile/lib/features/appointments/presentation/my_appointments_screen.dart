import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../chat/data/chat_args.dart';
import '../../doctors/state/doctor_providers.dart';
import '../data/appointment.dart';
import '../state/appointment_providers.dart';

/// Appointment ids reviewed in this session — flips the button to
/// "Reviewed ✓" immediately without another backend lookup.
final _reviewedAppointmentsProvider = StateProvider<Set<String>>((ref) => {});

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

  Future<void> _review(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({int rating, String comment})>(
      context: context,
      builder: (context) => _ReviewDialog(doctorName: appointment.doctorName),
    );
    if (result == null) return;
    try {
      await ref.read(reviewRepositoryProvider).submit(
            appointmentId: appointment.id,
            rating: result.rating,
            comment: result.comment.isEmpty ? null : result.comment,
          );
      ref
          .read(_reviewedAppointmentsProvider.notifier)
          .update((ids) => {...ids, appointment.id});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your review!')),
        );
      }
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
            if (appointment.isEmergency)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.emergency, size: 15, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      'Emergency',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            if (appointment.doctorId != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Message doctor'),
                  onPressed: () => context.push(
                    '/chat/${appointment.doctorId}',
                    extra: ChatArgs(name: appointment.doctorName),
                  ),
                ),
              ),
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
            if (appointment.status == 'completed') ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ref.watch(_reviewedAppointmentsProvider).contains(appointment.id)
                    ? const TextButton(
                        onPressed: null,
                        child: Text('Reviewed ✓'),
                      )
                    : TextButton.icon(
                        icon: const Icon(Icons.star_outline, size: 18),
                        label: const Text('Leave a review'),
                        onPressed: () => _review(context, ref),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.doctorName});

  final String doctorName;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _commentController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate ${widget.doctorName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => setState(() => _rating = i + 1),
              );
            }),
          ),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _rating == 0
              ? null
              : () => Navigator.of(context).pop(
                    (rating: _rating, comment: _commentController.text.trim()),
                  ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
