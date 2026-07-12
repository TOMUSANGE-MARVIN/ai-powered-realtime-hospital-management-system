import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../doctors/data/doctor.dart';
import '../../doctors/state/doctor_providers.dart';
import '../../payments/state/payment_providers.dart';
import '../state/appointment_providers.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final _reasonController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  String _consultationType = 'video';
  bool _isEmergency = false;
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

  Future<void> _submit(Doctor doctor) async {
    final date = _isEmergency ? DateTime.now() : _date;
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a date')),
      );
      return;
    }

    // Pay-before-book: doctors with a fee require a completed payment first.
    String? paymentId;
    if (doctor.consultationFee != null) {
      paymentId = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _PaymentSheet(doctor: doctor),
      );
      if (paymentId == null) return; // user backed out of payment
    }
    if (!mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(appointmentRepositoryProvider).book(
            doctorId: widget.doctorId,
            date: date,
            time: _time?.format(context),
            reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
            consultationType: _consultationType,
            isEmergency: _isEmergency,
            paymentId: paymentId,
          );
      ref.invalidate(myAppointmentsProvider);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
          title: Text(_isEmergency ? 'Emergency request sent' : 'Appointment requested'),
          content: Text(
            _isEmergency
                ? "Your emergency request has been sent — the doctor's team will attend to you as soon as possible."
                : "We've sent your request to the doctor's team. You'll see it under My Appointments once confirmed.",
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
    final doctorAsync = ref.watch(doctorDetailProvider(widget.doctorId));
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final feeFormat = NumberFormat.decimalPattern();

    return Scaffold(
      appBar: AppBar(title: Text(doctorAsync.value?.name ?? 'Book appointment')),
      body: doctorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (doctor) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Consultation type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'physical',
                    label: Text('Physical'),
                    icon: Icon(Icons.local_hospital_outlined),
                  ),
                  ButtonSegment(
                    value: 'voice',
                    label: Text('Voice'),
                    icon: Icon(Icons.call_outlined),
                  ),
                  ButtonSegment(
                    value: 'video',
                    label: Text('Video'),
                    icon: Icon(Icons.videocam_outlined),
                  ),
                ],
                selected: {_consultationType},
                onSelectionChanged: (value) =>
                    setState(() => _consultationType = value.first),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                color: _isEmergency
                    ? Theme.of(context).colorScheme.errorContainer
                    : null,
                child: SwitchListTile(
                  secondary: Icon(
                    Icons.emergency,
                    color: _isEmergency
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                  title: const Text('This is an emergency'),
                  subtitle: Text(
                    _isEmergency
                        ? 'Booked for today — you will get immediate attention'
                        : 'Need immediate attention today?',
                  ),
                  value: _isEmergency,
                  onChanged: (value) => setState(() => _isEmergency = value),
                ),
              ),
              const SizedBox(height: 12),
              if (!_isEmergency)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(_date == null ? 'Choose a date' : dateFormat.format(_date!)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDate,
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text('Today, ${dateFormat.format(DateTime.now())}'),
                  subtitle: const Text('Emergency bookings are always for today'),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(_time == null ? 'Choose a time (optional)' : _time!.format(context)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickTime,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for visit (optional)',
                ),
              ),
              const SizedBox(height: 16),
              if (doctor.consultationFee != null)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Consultation fee')),
                        Text(
                          'UGX ${feeFormat.format(doctor.consultationFee)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : () => _submit(doctor),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(doctor.consultationFee != null ? 'Pay & Book' : 'Request appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simulated payment sheet: choose MoMo provider, enter number, "pay".
/// Pops with the paid payment's id on success.
class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.doctor});

  final Doctor doctor;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  final _phoneController = TextEditingController();
  String _method = 'mtn_momo';
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final payment = await repo.initiate(
        doctorId: widget.doctor.id,
        method: _method,
        phoneNumber: phone,
      );
      // Simulated processing delay — stands in for the user approving the
      // MoMo prompt on their phone once a real provider is wired in.
      await Future<void>.delayed(const Duration(seconds: 2));
      final confirmed = await repo.confirm(payment.id);
      if (!mounted) return;
      Navigator.of(context).pop(confirmed.id);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _processing = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feeFormat = NumberFormat.decimalPattern();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pay consultation fee',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'UGX ${feeFormat.format(widget.doctor.consultationFee)} · ${widget.doctor.name}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'mtn_momo', label: Text('MTN MoMo')),
              ButtonSegment(value: 'airtel_money', label: Text('Airtel Money')),
            ],
            selected: {_method},
            onSelectionChanged: _processing
                ? null
                : (value) => setState(() => _method = value.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: !_processing,
            decoration: InputDecoration(
              labelText: 'Mobile money number',
              hintText: '07XXXXXXXX',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _processing ? null : _pay,
            child: _processing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Text('Processing payment…'),
                    ],
                  )
                : const Text('Pay now'),
          ),
        ],
      ),
    );
  }
}
