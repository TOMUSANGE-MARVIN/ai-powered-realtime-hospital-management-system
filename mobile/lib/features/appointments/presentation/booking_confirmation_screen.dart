import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/state/auth_controller.dart';
import '../../doctors/presentation/doctor_card.dart' show DoctorImage;
import '../../payments/data/payment_repository.dart';
import '../../payments/state/payment_providers.dart';
import '../data/booking_draft.dart';
import '../state/appointment_providers.dart';

final _money = NumberFormat.decimalPattern();

/// Last step before paying: the patient checks what they chose, sees their
/// insurance, and can apply a voucher. Doctors without a fee are booked
/// straight from here.
class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({super.key, required this.draft});

  final BookingDraft draft;

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  final _voucherController = TextEditingController();
  late BookingDraft _draft = widget.draft;
  bool _applying = false;
  bool _booking = false;
  String? _voucherError;

  @override
  void initState() {
    super.initState();
    if (_draft.fee > 0) _loadQuote();
  }

  /// Picks up tax before any voucher is entered.
  Future<void> _loadQuote() async {
    try {
      final quote = await ref
          .read(pricingRepositoryProvider)
          .quote(_draft.doctor.id);
      if (mounted && _draft.voucherCode == null) {
        setState(() => _draft = _applyQuote(quote));
      }
    } on ApiException {
      // Without a quote the payment screen still charges the server total.
    }
  }

  BookingDraft _applyQuote(PriceQuote quote) => _draft.withPricing(
    voucherCode: quote.voucherCode,
    discount: quote.discount,
    tax: quote.tax,
  );

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _applying = true;
      _voucherError = null;
    });
    try {
      final quote = await ref
          .read(pricingRepositoryProvider)
          .applyVoucher(code: code, doctorId: _draft.doctor.id);
      setState(() => _draft = _applyQuote(quote));
    } on ApiException catch (e) {
      setState(() => _voucherError = e.message);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _removeVoucher() {
    _voucherController.clear();
    setState(() {
      _draft = _draft.withPricing(voucherCode: null, discount: 0, tax: 0);
      _voucherError = null;
    });
    _loadQuote();
  }

  Future<void> _confirm() async {
    if (_draft.fee > 0) {
      context.push('/book/${_draft.doctor.id}/pay', extra: _draft);
      return;
    }
    setState(() => _booking = true);
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .book(
            doctorId: _draft.doctor.id,
            date: _draft.date,
            time: _draft.time,
            reason: _draft.reason,
            consultationType: _draft.consultationType,
            isEmergency: _draft.isEmergency,
          );
      ref.invalidate(myAppointmentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Appointment requested — we'll notify you once it's confirmed",
          ),
        ),
      );
      context.go('/home/appointments');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final user = ref.watch(authControllerProvider).value;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final when = draft.isEmergency
        ? 'Today · Emergency'
        : '${draft.time ?? ''}${draft.time != null ? ' | ' : ''}'
              '${DateFormat('dd/MM/yyyy').format(draft.date)}';
    final type = switch (draft.consultationType) {
      'physical' => (Icons.local_hospital_outlined, 'In-person visit'),
      'voice' => (Icons.call_outlined, 'Voice Call'),
      _ => (Icons.videocam_outlined, 'Video Call'),
    };

    return Scaffold(
      appBar: AppBar(title: const _StepIndicator(current: 2)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Confirmation',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Service',
                  value: draft.doctor.specialization ?? 'General consultation',
                  trailing: draft.fee > 0
                      ? Text(
                          'UGX ${_money.format(draft.fee)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                _SummaryRow(icon: type.$1, label: 'Type', value: type.$2),
                _SummaryRow(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: ClipOval(
                      child: DoctorImage(
                        url: draft.doctor.image,
                        name: draft.doctor.name,
                        gender: draft.doctor.gender,
                      ),
                    ),
                  ),
                  label: 'Doctor',
                  value: draft.doctor.name,
                ),
                _SummaryRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date & Time',
                  value: when,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Change date or time',
                    onPressed: () => context.pop(),
                  ),
                ),
                _SummaryRow(
                  icon: Icons.info_outline,
                  label: 'Note',
                  value: draft.reason ?? 'No note added',
                ),
              ],
            ),
          ),
          if (user?.role != 'doctor') ...[
            const SizedBox(height: 24),
            const _Heading('Insurance'),
            const SizedBox(height: 8),
            SoftCard(
              onTap: () => context.push('/edit-profile'),
              child: Row(
                children: [
                  Expanded(
                    child: user?.hasInsurance == true
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user!.insuranceProvider!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (user.insuranceMemberNo?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Member no. ${user.insuranceMemberNo}',
                                  style: TextStyle(color: muted, fontSize: 13),
                                ),
                              ],
                            ],
                          )
                        : Text(
                            'Add your insurance details',
                            style: TextStyle(color: muted),
                          ),
                  ),
                  const Icon(Icons.chevron_right, color: seedTeal),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Show your insurance card at the visit. Online payment is '
              'charged in full.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
          if (draft.fee > 0) ...[
            const SizedBox(height: 24),
            const _Heading('Voucher'),
            const SizedBox(height: 8),
            if (draft.voucherCode != null)
              SoftCard(
                borderSide: const BorderSide(color: seedTeal),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_outlined, color: seedTeal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${draft.voucherCode} applied · '
                        '-UGX ${_money.format(draft.discount)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _removeVoucher,
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _voucherController,
                      textCapitalization: TextCapitalization.characters,
                      enabled: !_applying,
                      decoration: InputDecoration(
                        hintText: 'Enter voucher code',
                        errorText: _voucherError,
                      ),
                      onSubmitted: (_) => _applyVoucher(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _applying ? null : _applyVoucher,
                      child: _applying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Apply'),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (draft.fee > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      'UGX ${_money.format(draft.total)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: seedTeal,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _booking ? null : _confirm,
                child: _booking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Doctor → Schedule → Confirm, as three connected dots.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    Widget dot(int i) => Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: i < current ? seedTeal : Colors.transparent,
        border: Border.all(color: i <= current ? seedTeal : outline, width: 2),
      ),
      child: i < current
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
    Widget line(int i) => Container(
      width: 40,
      height: 2,
      color: i < current ? seedTeal : outline,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [dot(0), line(0), dot(1), line(1), dot(2)],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.icon,
    this.leading,
    this.trailing,
  });

  final IconData? icon;
  final Widget? leading;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          leading ??
          CircleAvatar(
            radius: 20,
            backgroundColor: seedTeal.withValues(alpha: 0.12),
            child: Icon(icon, color: seedTeal, size: 20),
          ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      trailing: trailing,
    );
  }
}
