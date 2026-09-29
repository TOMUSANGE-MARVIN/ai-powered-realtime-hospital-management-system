import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/soft_card.dart';
import '../../doctors/data/doctor.dart';
import '../../doctors/presentation/doctor_card.dart' show DoctorImage;
import '../../doctors/state/doctor_providers.dart';
import '../data/booking_draft.dart';

const _ink = darkTealBackground;
const _muted = Color(0xFF6B7A7A);
const _danger = Color(0xFFD32F2F);

/// How many days ahead the date strip offers.
const _bookingWindowDays = 14;

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final _reasonController = TextEditingController();
  DateTime? _date;
  int? _slotMinutes;
  String _consultationType = 'video';
  bool _isEmergency = false;

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

  /// The doctor's next bookable day on/after [from] — used both to seed the
  /// screen's default date and as the earliest [showDatePicker] will offer.
  DateTime? _nextBookableDay(
    DateTime from,
    Set<int>? weekdays,
    List<int> slots,
  ) {
    for (var i = 0; i < _bookingWindowDays; i++) {
      final day = from.add(Duration(days: i));
      if (_isDayBookable(day, weekdays, slots)) return day;
    }
    return null;
  }

  Future<void> _pickDate(Set<int>? weekdays, List<int> slots) async {
    final today = _dayOnly(DateTime.now());
    final lastDay = today.add(const Duration(days: _bookingWindowDays - 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? _nextBookableDay(today, weekdays, slots) ?? today,
      firstDate: today,
      lastDate: lastDay,
      selectableDayPredicate: (day) => _isDayBookable(day, weekdays, slots),
      helpText: 'Choose appointment date',
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _slotMinutes = null;
      });
    }
  }

  Future<void> _pickTime(List<int> slots) async {
    final openSlots = _date == null ? slots : _openSlots(_date!, slots);
    if (openSlots.isEmpty) return;
    final initial = _slotMinutes ?? openSlots.first;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
      helpText: 'Choose appointment time',
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    // The clock face lets the patient drop the hand on any minute, but the
    // doctor's slots are 30-minute steps — snap to the closest open one
    // instead of rejecting anything not exactly on the mark.
    final closest = openSlots.reduce(
      (a, b) => (a - minutes).abs() <= (b - minutes).abs() ? a : b,
    );
    setState(() => _slotMinutes = closest);
  }

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
    // Review, insurance and voucher happen on the Confirmation screen,
    // which books directly for free doctors and pays first otherwise.
    context.push('/book/${doctor.id}/confirm', extra: draft);
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
          // Default to the first bookable day so a time can be picked right away.
          _date ??= _nextBookableDay(today, weekdays, slots);

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
                      const _SectionLabel('Date & time'),
                      const SizedBox(height: 10),
                      if (_date == null)
                        SoftCard(
                          color: Colors.white,
                          child: const Text(
                            'No open days in the next two weeks. '
                            'Message the doctor or mark this as an emergency.',
                            style: TextStyle(color: _muted),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _PickerField(
                                icon: Icons.calendar_month_outlined,
                                label: 'Date',
                                value: DateFormat(
                                  'EEE, MMM d, yyyy',
                                ).format(_date!),
                                onTap: () => _pickDate(weekdays, slots),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PickerField(
                                icon: Icons.access_time_outlined,
                                label: 'Time',
                                value: _slotMinutes == null
                                    ? 'Choose time'
                                    : _formatSlot(_slotMinutes!),
                                placeholder: _slotMinutes == null,
                                onTap: () => _pickTime(slots),
                              ),
                            ),
                          ],
                        ),
                      if (doctor.availabilityHours != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Working hours: ${[doctor.availabilityDays, doctor.availabilityHours].whereType<String>().join(', ')}',
                          style: const TextStyle(fontSize: 12.5, color: _muted),
                        ),
                      ],
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
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
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
            child: ClipOval(
              child: DoctorImage(url: doctor.image, name: doctor.name),
            ),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
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
                  Icon(
                    icon,
                    size: 22,
                    color: value == key ? Colors.white : seedTeal,
                  ),
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
/// border otherwise.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.selected, required this.child, this.onTap});

  final bool selected;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? seedTeal : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: selected
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(child: child),
        ),
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

/// A tappable field styled like the other form controls that opens a native
/// Material picker (showDatePicker / showTimePicker) instead of inline chips.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: seedTeal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11.5, color: _muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: placeholder ? _muted : _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.fee,
    required this.ready,
    required this.onPressed,
  });

  final int? fee;
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
                  const Text(
                    'Consultation fee',
                    style: TextStyle(fontSize: 12.5, color: _muted),
                  ),
                  Text(
                    'UGX ${NumberFormat.decimalPattern().format(fee)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: ready ? onPressed : null,
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
