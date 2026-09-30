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

  /// Set once the doctor loads; its time off removes whole days.
  Doctor? _doctor;

  bool _isDayBookable(DateTime day, Set<int>? weekdays, List<int> slots) {
    if (weekdays != null && !weekdays.contains(day.weekday)) return false;
    if (_doctor?.isAwayOn(day) ?? false) return false;
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
      appBar: AppBar(title: const Text('Book appointment'), centerTitle: true),
      body: doctorAsync.when(
        loading: () => const SkeletonForm(),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (doctor) {
          _doctor = doctor;
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
                          color: context.palette.card,
                          child: Text(
                            'No open days in the next two weeks. '
                            'Message the doctor or mark this as an emergency.',
                            style: TextStyle(color: context.palette.muted),
                          ),
                        )
                      else ...[
                        _DateStrip(
                          days: [
                            for (var i = 0; i < _bookingWindowDays; i++)
                              _dayOnly(DateTime.now()).add(Duration(days: i)),
                          ],
                          selected: _date!,
                          isBookable: (d) => _isDayBookable(d, weekdays, slots),
                          onSelect: (d) => setState(() {
                            _date = d;
                            _slotMinutes = null;
                          }),
                        ),
                        const SizedBox(height: 14),
                        _SlotChips(
                          slots: _openSlots(_date!, slots),
                          selected: _slotMinutes,
                          format: _formatSlot,
                          onSelect: (m) => setState(() => _slotMinutes = m),
                        ),
                      ],
                      if (doctor.availabilityHours != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Working hours: ${[doctor.availabilityDays, doctor.availabilityHours].whereType<String>().join(', ')}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.palette.muted,
                          ),
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
                      decoration: InputDecoration(
                        hintText: 'Briefly describe your symptoms (optional)',
                        filled: true,
                        fillColor: context.palette.card,
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
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: context.palette.ink,
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
      color: context.palette.card,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: ClipOval(
              child: DoctorImage(
                url: doctor.image,
                name: doctor.name,
                gender: doctor.gender,
              ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.palette.ink,
                  ),
                ),
                if (specialty != null)
                  Text(
                    [specialty, ?doctor.hospitalName].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.palette.muted,
                    ),
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
                      color: value == key ? Colors.white : context.palette.ink,
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
      color: selected ? seedTeal : context.palette.card,
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
      color: value ? context.palette.dangerTint : context.palette.card,
      borderSide: value
          ? BorderSide(color: context.palette.dangerBorder)
          : null,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Icon(
            Icons.emergency_outlined,
            color: value ? _danger : context.palette.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is an emergency',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: value ? _danger : context.palette.ink,
                  ),
                ),
                Text(
                  value
                      ? 'Booked for today — the doctor’s team attends to you as soon as possible'
                      : 'Need to be seen today?',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.palette.muted,
                  ),
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
        color: context.palette.card,
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
                  Text(
                    'Consultation fee',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.palette.muted,
                    ),
                  ),
                  Text(
                    'UGX ${NumberFormat.decimalPattern().format(fee)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.palette.ink,
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

/// Horizontal strip of the next days; closed days are dimmed.
class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.days,
    required this.selected,
    required this.isBookable,
    required this.onSelect,
  });

  final List<DateTime> days;
  final DateTime selected;
  final bool Function(DateTime) isBookable;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = days[i];
          final open = isBookable(day);
          final isSelected = DateUtils.isSameDay(day, selected);
          return Opacity(
            opacity: open ? 1 : 0.4,
            child: Material(
              color: isSelected ? seedTeal : context.palette.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kCardRadius),
                side: isSelected ? BorderSide.none : BorderSide(color: outline),
              ),
              child: InkWell(
                onTap: open ? () => onSelect(day) : null,
                child: SizedBox(
                  width: 58,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(day),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : context.palette.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : context.palette.ink,
                        ),
                      ),
                      Text(
                        open ? DateFormat('MMM').format(day) : 'Closed',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white
                              : context.palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The open half-hour slots for the chosen day.
class _SlotChips extends StatelessWidget {
  const _SlotChips({
    required this.slots,
    required this.selected,
    required this.format,
    required this.onSelect,
  });

  final List<int> slots;
  final int? selected;
  final String Function(int) format;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Text(
        'No times left on this day — pick another date.',
        style: TextStyle(color: context.palette.muted),
      );
    }
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in slots)
          Material(
            color: m == selected ? seedTeal : context.palette.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kCardRadius),
              side: m == selected
                  ? BorderSide.none
                  : BorderSide(color: outline),
            ),
            child: InkWell(
              onTap: () => onSelect(m),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  format(m),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: m == selected ? Colors.white : context.palette.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
