import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_dots.dart';
import '../../../core/widgets/soft_card.dart';
import '../../appointments/data/booking_draft.dart';
import '../../appointments/state/appointment_providers.dart';
import '../data/payment_repository.dart';
import '../state/payment_providers.dart';
import 'pesapal_checkout_screen.dart';

const _ink = darkTealBackground;
const _muted = Color(0xFF6B7A7A);
const _danger = Color(0xFFD32F2F);

/// How long to keep asking the backend for a result after checkout — mobile
/// money approvals on the patient's phone can take a while.
const _pollInterval = Duration(seconds: 3);
const _pollAttempts = 20;

enum _Stage {
  review,
  starting,
  verifying,
  booking,
  success,
  failed,
  stillPending,
  bookingFailed,
}

/// Review → pay on Pesapal → verify → book. The appointment is only created
/// after the backend reports the Pesapal payment as paid.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.draft});

  final BookingDraft draft;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  _Stage _stage = _Stage.review;
  Payment? _payment;
  String? _error;
  _PayMethod _method = _PayMethod.mtn;

  BookingDraft get _draft => widget.draft;
  int get _fee => _draft.total;
  bool get _busy =>
      _stage == _Stage.starting ||
      _stage == _Stage.verifying ||
      _stage == _Stage.booking;

  PaymentRepository get _repo => ref.read(paymentRepositoryProvider);

  Future<void> _pay() async {
    setState(() {
      _stage = _Stage.starting;
      _error = null;
    });
    try {
      // Resume an unfinished checkout instead of creating a second order.
      final existing = _payment;
      final payment =
          existing != null && existing.isPending && existing.redirectUrl != null
          ? existing
          : await _repo.initiate(
              doctorId: _draft.doctor.id,
              voucherCode: _draft.voucherCode,
              booking: {
                'date': _draft.date.toIso8601String(),
                'time': _draft.time,
                'reason': _draft.reason,
                'consultationType': _draft.consultationType,
                'isEmergency': _draft.isEmergency,
              },
            );
      _payment = payment;
      final url = payment.redirectUrl;
      if (url == null) {
        throw ApiException(
          'The payment page is unavailable. Please try again.',
        );
      }
      if (!mounted) return;

      final attempted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PesapalCheckoutScreen(checkoutUrl: url),
        ),
      );
      await _verify(keepPolling: attempted == true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _stage = _Stage.review;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _verify({required bool keepPolling}) async {
    final payment = _payment;
    if (payment == null || !mounted) return;
    setState(() => _stage = _Stage.verifying);

    for (
      var attempt = 0;
      attempt < (keepPolling ? _pollAttempts : 1);
      attempt++
    ) {
      if (attempt > 0) await Future<void>.delayed(_pollInterval);
      if (!mounted) return;
      try {
        final latest = await _repo.status(payment.id);
        _payment = Payment(
          id: latest.id,
          amount: latest.amount,
          currency: latest.currency,
          status: latest.status,
          method: latest.method,
          reference: latest.reference,
          redirectUrl: payment.redirectUrl,
        );
        if (latest.isPaid) {
          await _book();
          return;
        }
        if (!latest.isPending) {
          return setState(() {
            _stage = _Stage.failed;
            _error = latest.status == 'reversed'
                ? 'This payment was reversed.'
                : 'The payment did not go through. You have not been charged.';
          });
        }
      } on ApiException {
        // Transient network error — keep polling.
      }
    }
    if (!mounted) return;
    setState(() {
      if (keepPolling) {
        _stage = _Stage.stillPending;
      } else {
        // Closed the checkout before finishing — back to review, same order.
        _stage = _Stage.review;
        _error =
            'Payment not completed. Tap Pay now to continue where you left off.';
      }
    });
  }

  Future<void> _book() async {
    final payment = _payment;
    if (payment == null || !mounted) return;
    setState(() {
      _stage = _Stage.booking;
      _error = null;
    });
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
            paymentId: payment.id,
          );
      ref.invalidate(myAppointmentsProvider);
      if (mounted) setState(() => _stage = _Stage.success);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _stage = _Stage.bookingFailed;
          _error = e.message;
        });
      }
    }
  }

  void _startOver() => setState(() {
    _payment = null;
    _stage = _Stage.review;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final done = _stage == _Stage.success;
    return PopScope(
      canPop: !_busy && !done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && done) context.go('/home/appointments');
      },
      child: Scaffold(
        backgroundColor: tealBackground,
        appBar: AppBar(
          backgroundColor: tealBackground,
          automaticallyImplyLeading: !_busy && !done,
          title: const Text('Payment'),
          centerTitle: true,
        ),
        body: switch (_stage) {
          _Stage.verifying => const _Progress(
            title: 'Confirming your payment',
            subtitle:
                'If you paid with mobile money, approve the prompt on your phone.',
          ),
          _Stage.booking => const _Progress(
            title: 'Payment received',
            subtitle: 'Booking your appointment…',
          ),
          _Stage.success => _Result(
            icon: Icons.check_rounded,
            color: seedTeal,
            title: 'Appointment requested',
            message:
                "You've paid UGX ${NumberFormat.decimalPattern().format(_payment?.amount ?? _fee)}"
                '${_payment?.reference != null ? ' (ref ${_payment!.reference})' : ''}. '
                "We'll notify you once ${_draft.doctor.name} confirms.",
            primaryLabel: 'View my appointments',
            onPrimary: () => context.go('/home/appointments'),
          ),
          _Stage.failed => _Result(
            icon: Icons.close_rounded,
            color: _danger,
            title: 'Payment failed',
            message: _error ?? 'The payment did not go through.',
            primaryLabel: 'Try again',
            onPrimary: _startOver,
            secondaryLabel: 'Back to booking',
            onSecondary: () => context.pop(),
          ),
          _Stage.stillPending => _Result(
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFFF9800),
            iconColor: const Color(0xFF2B1A00),
            title: 'Still processing',
            message:
                "We haven't received confirmation from Pesapal yet. "
                'If you approved the payment, check again in a moment.',
            primaryLabel: 'Check again',
            onPrimary: () => _verify(keepPolling: true),
            secondaryLabel: 'Back to payment',
            onSecondary: () => setState(() => _stage = _Stage.review),
          ),
          _Stage.bookingFailed => _Result(
            icon: Icons.event_busy_outlined,
            color: _danger,
            title: "Paid, but the booking didn't go through",
            message:
                '${_error ?? 'Something went wrong.'} '
                "Your payment is safe — tap below to finish booking without paying again.",
            primaryLabel: 'Finish booking',
            onPrimary: _book,
          ),
          _ => _Review(
            draft: _draft,
            fee: _fee,
            error: _error,
            method: _method,
            onMethodChanged: (m) => setState(() => _method = m),
            starting: _stage == _Stage.starting,
            onPay: _pay,
            onCancel: () => context.pop(),
          ),
        },
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({
    required this.draft,
    required this.fee,
    required this.error,
    required this.method,
    required this.onMethodChanged,
    required this.starting,
    required this.onPay,
    required this.onCancel,
  });

  final BookingDraft draft;
  final int fee;
  final String? error;
  final _PayMethod method;
  final ValueChanged<_PayMethod> onMethodChanged;
  final bool starting;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final money = 'UGX ${NumberFormat.decimalPattern().format(fee)}';
    final when = draft.isEmergency
        ? 'Today · Emergency'
        : '${DateFormat('EEE, MMM d, yyyy').format(draft.date)}'
              '${draft.time != null ? ' · ${draft.time}' : ''}';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              SoftCard(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Caption('Payment summary'),
                    const SizedBox(height: 12),
                    _Line(label: 'Service', value: draft.serviceLabel),
                    _Line(label: 'Doctor', value: draft.doctor.name),
                    _Line(label: 'Date', value: when),
                    _Line(
                      label: 'Consultation fee',
                      value:
                          'UGX ${NumberFormat.decimalPattern().format(draft.fee)}',
                    ),
                    if (draft.tax > 0)
                      _Line(
                        label: 'Tax/Fees',
                        value:
                            'UGX ${NumberFormat.decimalPattern().format(draft.tax)}',
                      ),
                    if (draft.discount > 0)
                      _Line(
                        label: 'Voucher ${draft.voucherCode}',
                        value:
                            '-UGX ${NumberFormat.decimalPattern().format(draft.discount)}',
                      ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          money,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: seedTeal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _MethodPicker(selected: method, onChanged: onMethodChanged),
              const SizedBox(height: 4),
              if (error != null) ...[
                const SizedBox(height: 16),
                SoftCard(
                  color: const Color(0xFFFFE9E9),
                  borderSide: const BorderSide(color: Color(0xFFF6C4C4)),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: _danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: _danger,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: starting ? null : onPay,
                    child: starting
                        ? const LoadingDots()
                        : Text(
                            'Pay $money',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: starting ? null : onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: _muted),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'A receipt will be sent to your email upon confirmation. '
                        'Payments are processed securely by Pesapal; Ask Musawo '
                        'never sees your card details.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: _muted,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: _muted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingDots(color: seedTeal, size: 10),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.iconColor = Colors.white,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: iconColor),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: _muted,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pesapal's order API takes no preferred method — its checkout lists every
/// option — so the choice here only tailors the instruction for that page.
enum _PayMethod {
  mtn(
    title: 'MTN MoMo',
    subtitle: 'Pay using your MTN Mobile Money account.',
    logo: 'assets/images/payments/mtn.svg',
    // MTN's mark is drawn black and always sits on brand yellow.
    tile: Color(0xFFFFCB05),
    hint:
        'On the next page, choose MTN MoMo and approve the prompt on your phone.',
  ),
  airtel(
    title: 'Airtel Money',
    subtitle: 'Pay using your Airtel Money account.',
    logo: 'assets/images/payments/airtel.svg',
    hint:
        'On the next page, choose Airtel Money and approve the prompt on your phone.',
  ),
  visa(
    title: 'Visa',
    subtitle: 'Pay using your Visa card.',
    logo: 'assets/images/payments/visa.svg',
    hint: 'On the next page, choose Visa and enter your card details.',
  ),
  mastercard(
    title: 'Mastercard',
    subtitle: 'Pay using your Mastercard.',
    logo: 'assets/images/payments/mastercard.svg',
    hint: 'On the next page, choose Mastercard and enter your card details.',
  );

  const _PayMethod({
    required this.title,
    required this.subtitle,
    required this.logo,
    required this.hint,
    this.tile = Colors.white,
  });

  final String title;
  final String subtitle;
  final String logo;
  final String hint;
  final Color tile;
}

class _MethodPicker extends StatelessWidget {
  const _MethodPicker({required this.selected, required this.onChanged});

  final _PayMethod selected;
  final ValueChanged<_PayMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Payment method',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose how you want to pay for your appointment.',
          style: TextStyle(fontSize: 13.5, color: _muted),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F5F4),
            borderRadius: BorderRadius.circular(kCardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: seedTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesapal secure checkout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your payment details are secure and encrypted with Pesapal.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF4A5A5A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final m in _PayMethod.values) ...[
          _MethodRow(
            method: m,
            selected: m == selected,
            onTap: () => onChanged(m),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 16, color: seedTeal),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                selected.hint,
                style: const TextStyle(fontSize: 12.5, color: _muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final _PayMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: method.title,
      child: Material(
        color: selected ? tealBackground : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCardRadius),
          side: BorderSide(
            color: selected ? seedTeal : outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 44,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: method.tile,
                    borderRadius: BorderRadius.circular(kCardRadius),
                    border: method.tile == Colors.white
                        ? Border.all(color: outline)
                        : null,
                  ),
                  child: SvgPicture.asset(method.logo, fit: BoxFit.contain),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        method.subtitle,
                        style: const TextStyle(fontSize: 12.5, color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _RadioDot(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? seedTeal : const Color(0xFFB6C2C2),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: seedTeal,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
