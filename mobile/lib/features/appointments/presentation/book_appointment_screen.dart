import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../doctors/data/doctor.dart';
import '../../doctors/presentation/doctor_card.dart' show DoctorImage;
import '../../doctors/state/doctor_providers.dart';
import '../data/booking_draft.dart';
import '../state/appointment_providers.dart';

const _ink = darkTealBackground;
const _muted = Color(0xFF6B7A7A);
const _danger = Color(0xFFD32F2F);

/// How many days ahead the date strip offers.
const _bookingWindowDays = 14;

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final _reasonController = TextEditingController();
  DateTime? _date;
  int? _slotMinutes;
  String _consultationType = 'video';
  bool _isEmergency = false;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Slots on [day] that haven't already passed (only matters for today).
  List<int> _openSlots(DateTime day, List<int> slots) {
    final now = DateTime.now();
    if (_dayOnly(now) != day) return slots;
    final nowMinutes = now.hour * 60 + now.minute;
    return slots.where((m) => m > nowMinutes).toList();
  }

  bool _isDayBookable(DateTime day, Set<int>? weekdays, List<int> slots) {
    if (weekdays != null && !weekdays.contains(day.weekday)) return false;
    return _openSlots(day, slots).isNotEmpty;
  }

  String _formatSlot(int minutes) =>
      DateFormat.jm().format(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60));

  BookingDraft? _draft(Doctor doctor) {
    final reason = _reasonController.text.trim();
    if (_isEmergency) {
      return BookingDraft(
        doctor: doctor,
        date: DateTime.now(),
        consultationType: _consultationType,
        reason: reason.isEmpty ? null : reason,
        isEmergency: true,
      );
    }
    if (_date == null || _slotMinutes == null) return null;
    return BookingDraft(
      doctor: doctor,
      date: _date!.add(Duration(minutes: _slotMinutes!)),
      time: _formatSlot(_slotMinutes!),
      consultationType: _consultationType,
      reason: reason.isEmpty ? null : reason,
    );
  }

  Future<void> _continue(Doctor doctor) async {
    final draft = _draft(doctor);
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a date and time first')),
      );
      return;
    }
    // Doctors with a fee: pay first, the payment screen books on success.
    if (doctor.consultationFee != null) {
      context.push('/book/${doctor.id}/pay', extra: draft);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(appointmentRepositoryProvider).book(
            doctorId: doctor.id,
            date: draft.date,
            time: draft.time,
            reason: draft.reason,
            consultationType: draft.consultationType,
            isEmergency: draft.isEmergency,
          );
      ref.invalidate(myAppointmentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment requested — we'll notify you once it's confirmed")),
      );
      context.go('/home/appointments');
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

    return Scaffold(
      backgroundColor: tealBackground,
      appBar: AppBar(
        backgroundColor: tealBackground,
        title: const Text('Book appointment'),
        centerTitle: true,
      ),
      body: doctorAsync.when(
        loading: () => const SkeletonForm(),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (doctor) {
          final weekdays = parseAvailableWeekdays(doctor.availabilityDays);
          final slots = parseSlotMinutes(doctor.availabilityHours);
          final today = _dayOnly(DateTime.now());
          final days = [
            for (var i = 0; i < _bookingWindowDays; i++) today.add(Duration(days: i)),
          ];
          // Default to the first bookable day so the time grid is never empty.
          _date ??= days.cast<DateTime?>().firstWhere(
                (d) => _isDayBookable(d!, weekdays, slots),
                orElse: () => null,
              );
          // Times already past today are dropped rather than shown disabled.
          final openSlots = _date == null ? const <int>[] : _openSlots(_date!, slots);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _DoctorSummary(doctor: doctor),
                    const SizedBox(height: 20),
                    const _SectionLabel('Consultation type'),
                    const SizedBox(height: 10),
                    _ConsultationTypePicker(
                      value: _consultationType,
                      onChanged: (v) => setState(() => _consultationType = v),
                    ),
                    const SizedBox(height: 12),
                    _EmergencyToggle(
                      value: _isEmergency,
                      onChanged: (v) => setState(() => _isEmergency = v),
                    ),
                    const SizedBox(height: 20),
                    if (!_isEmergency) ...[
                      SoftCard(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const _SectionLabel('Choose date'),
                                  const Spacer(),
                                  if (_date != null)
                                    Text(
                                      DateFormat('MMMM yyyy').format(_date!),
                                      style: const TextStyle(fontSize: 13, color: _muted),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: days.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 8),
                                itemBuilder: (context, i) {
                                  final day = days[i];
                                  return _DateChip(
                                    date: day,
                                    selected: day == _date,
                                    enabled: _isDayBookable(day, weekdays, slots),
                                    onTap: () => setState(() {
                                      _date = day;
                                      _slotMinutes = null;
                                    }),
                                  );
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: _SectionLabel('Choose time'),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _date == null
                                  ? const Text(
                                      'No open days in the next two weeks. '
                                      'Message the doctor or mark this as an emergency.',
                                      style: TextStyle(color: _muted),
                                    )
                                  : _SlotGrid(
                                      slots: openSlots,
                                      open: openSlots.toSet(),
                                      selected: _slotMinutes,
                                      label: _formatSlot,
                                      onSelect: (m) => setState(() => _slotMinutes = m),
                                    ),
                            ),
                            if (doctor.availabilityHours != null) ...[
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Working hours: ${[doctor.availabilityDays, doctor.availabilityHours].whereType<String>().join(', ')}',
                                  style: const TextStyle(fontSize: 12.5, color: _muted),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const _SectionLabel('Reason for visit'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      minLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Briefly describe your symptoms (optional)',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              _CheckoutBar(
                fee: doctor.consultationFee,
                busy: _submitting,
                ready: _isEmergency || (_date != null && _slotMinutes != null),
                onPressed: () => _continue(doctor),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
    );
  }
}

class _DoctorSummary extends StatelessWidget {
  const _DoctorSummary({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final specialty = doctor.specialization ?? doctor.department;
    return SoftCard(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: ClipOval(child: DoctorImage(url: doctor.image, name: doctor.name)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
                ),
                if (specialty != null)
                  Text(
                    [specialty, ?doctor.hospitalName].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultationTypePicker extends StatelessWidget {
  const _ConsultationTypePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('video', 'Video call', Icons.videocam_outlined),
    ('voice', 'Voice call', Icons.call_outlined),
    ('physical', 'In person', Icons.local_hospital_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (key, label, icon) in _options) ...[
          if (key != _options.first.$1) const SizedBox(width: 10),
          Expanded(
            child: _ChoiceTile(
              selected: value == key,
              onTap: () => onChanged(key),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: value == key ? Colors.white : seedTeal),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value == key ? Colors.white : _ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A flat selectable tile: teal fill when selected, white with a hairline
/// border otherwise, muted when disabled.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  final bool selected;
  final bool enabled;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? seedTeal
          : enabled
              ? Colors.white
              : const Color(0xFFEFF3F3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: selected ? BorderSide.none : BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(padding: padding, child: Center(child: child)),
      ),
    );
  }
}

class _EmergencyToggle extends StatelessWidget {
  const _EmergencyToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: value ? const Color(0xFFFFE9E9) : Colors.white,
      borderSide: value ? const BorderSide(color: Color(0xFFF6C4C4)) : null,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Icon(Icons.emergency_outlined, color: value ? _danger : _muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is an emergency',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: value ? _danger : _ink,
                  ),
                ),
                Text(
                  value
                      ? 'Booked for today — the doctor’s team attends to you as soon as possible'
                      : 'Need to be seen today?',
                  style: const TextStyle(fontSize: 12.5, color: _muted),
                ),
              ],
            ),
          ),
          Switch(value: value, activeTrackColor: _danger, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : enabled
            ? _ink
            : const Color(0xFFA9B4B4);
    return SizedBox(
      width: 56,
      child: _ChoiceTile(
        selected: selected,
        enabled: enabled,
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE').format(date),
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : (enabled ? _muted : fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.slots,
    required this.open,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  final List<int> slots;
  final Set<int> open;
  final int? selected;
  final String Function(int) label;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.6,
      children: [
        for (final m in slots)
          _ChoiceTile(
            selected: m == selected,
            enabled: open.contains(m),
            onTap: () => onSelect(m),
            padding: EdgeInsets.zero,
            child: Text(
              label(m),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: m == selected
                    ? Colors.white
                    : open.contains(m)
                        ? _ink
                        : const Color(0xFFA9B4B4),
              ),
            ),
          ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.fee,
    required this.busy,
    required this.ready,
    required this.onPressed,
  });

  final int? fee;
  final bool busy;
  final bool ready;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (fee != null) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consultation fee', style: TextStyle(fontSize: 12.5, color: _muted)),
                  Text(
                    'UGX ${NumberFormat.decimalPattern().format(fee)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: busy || !ready ? null : onPressed,
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          fee != null ? 'Continue to payment' : 'Request appointment',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
