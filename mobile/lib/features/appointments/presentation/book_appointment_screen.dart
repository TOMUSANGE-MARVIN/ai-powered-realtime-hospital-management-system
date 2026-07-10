import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../state/appointment_providers.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key, required this.doctorId, this.doctorName});

  final String doctorId;
  final String? doctorName;

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final _reasonController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  String _consultationType = 'chat';
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a date')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(appointmentRepositoryProvider).book(
            doctorId: widget.doctorId,
            date: _date!,
            time: _time?.format(context),
            reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
            consultationType: _consultationType,
          );
      ref.invalidate(myAppointmentsProvider);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Appointment requested'),
          content: const Text(
            "We've sent your request to the doctor's team. You'll see it under My Appointments once confirmed.",
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/home/appointments');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(widget.doctorName ?? 'Book appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Consultation type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'chat', label: Text('Virtual (chat)'), icon: Icon(Icons.chat_bubble_outline)),
                ButtonSegment(value: 'in_person', label: Text('In person'), icon: Icon(Icons.local_hospital_outlined)),
              ],
              selected: {_consultationType},
              onSelectionChanged: (value) => setState(() => _consultationType = value.first),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_date == null ? 'Choose a date' : dateFormat.format(_date!)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(_time == null ? 'Choose a time (optional)' : _time!.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickTime,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for visit (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Request appointment'),
            ),
          ],
        ),
      ),
    );
  }
}
