import '../../doctors/data/doctor.dart';

/// Everything the patient chose on the booking screen, carried to the payment
/// screen (as the route's `extra`) so the appointment is only created once the
/// Pesapal payment is confirmed.
class BookingDraft {
  const BookingDraft({
    required this.doctor,
    required this.date,
    required this.consultationType,
    this.time,
    this.reason,
    this.isEmergency = false,
    this.voucherCode,
    this.discount = 0,
  });

  final Doctor doctor;
  final DateTime date;

  /// Display time, e.g. "10:30 AM" — null for emergencies.
  final String? time;

  /// physical | voice | video
  final String consultationType;
  final String? reason;
  final bool isEmergency;

  /// Voucher accepted on the Confirmation screen; the server re-checks it
  /// when the payment starts.
  final String? voucherCode;

  /// UGX taken off the consultation fee by [voucherCode].
  final int discount;

  int get fee => doctor.consultationFee ?? 0;
  int get total => fee - discount;

  BookingDraft withVoucher(String? code, int discount) => BookingDraft(
    doctor: doctor,
    date: date,
    consultationType: consultationType,
    time: time,
    reason: reason,
    isEmergency: isEmergency,
    voucherCode: code,
    discount: code == null ? 0 : discount,
  );

  String get serviceLabel => switch (consultationType) {
    'physical' => 'In-person consultation',
    'voice' => 'Voice call consultation',
    _ => 'Video call consultation',
  };
}

const _weekdayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

/// Parses a doctor's free-text `availabilityDays` ("Mon - Fri",
/// "Monday, Wednesday, Friday", "Mon-Sat") into [DateTime.weekday] numbers.
/// Returns null when the text can't be understood, meaning "any day".
Set<int>? parseAvailableWeekdays(String? text) {
  if (text == null) return null;
  final lower = text.toLowerCase();
  if (lower.contains('daily') || lower.contains('every'))
    return {1, 2, 3, 4, 5, 6, 7};

  final matches = RegExp(
    r'(mon|tue|wed|thu|fri|sat|sun)[a-z]*',
  ).allMatches(lower).toList();
  if (matches.isEmpty) return null;

  final days = <int>{};
  for (var i = 0; i < matches.length; i++) {
    final day = _weekdayKeys.indexOf(matches[i].group(1)!) + 1;
    days.add(day);
    if (i + 1 < matches.length) {
      final between = lower.substring(matches[i].end, matches[i + 1].start);
      if (between.contains('-') ||
          between.contains('to') ||
          between.contains('–')) {
        final end = _weekdayKeys.indexOf(matches[i + 1].group(1)!) + 1;
        for (var d = day; d != end; d = d % 7 + 1) {
          days.add(d);
        }
      }
    }
  }
  return days;
}

/// Half-hour slot start times (minutes after midnight) inside a doctor's
/// free-text `availabilityHours` ("9:00 AM - 5:00 PM", "08:00-17:00").
/// Falls back to 8:00–17:00 when the text can't be parsed.
List<int> parseSlotMinutes(String? text, {int stepMinutes = 30}) {
  var start = 8 * 60;
  var end = 17 * 60;
  if (text != null) {
    final times =
        RegExp(
              r'(\d{1,2})(?::(\d{2}))?\s*([ap])?\.?\s*m?',
              caseSensitive: false,
            )
            .allMatches(text)
            .map((m) {
              var hour = int.parse(m.group(1)!);
              final minute = int.tryParse(m.group(2) ?? '') ?? 0;
              final meridiem = m.group(3)?.toLowerCase();
              if (meridiem == 'p' && hour < 12) hour += 12;
              if (meridiem == 'a' && hour == 12) hour = 0;
              return hour * 60 + minute;
            })
            .where((t) => t < 24 * 60)
            .toList();
    if (times.length >= 2 && times[1] > times[0]) {
      start = times[0];
      end = times[1];
    }
  }
  return [for (var t = start; t + stepMinutes <= end; t += stepMinutes) t];
}
