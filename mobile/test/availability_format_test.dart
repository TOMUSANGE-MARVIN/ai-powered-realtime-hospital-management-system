import 'package:ask_musawo/features/appointments/data/booking_draft.dart';
import 'package:flutter_test/flutter_test.dart';

// Edit Profile writes a doctor's availability as text; the booking screen
// parses it back into bookable days and slots. These must agree.
void main() {
  test('comma-separated days written by Edit Profile parse back', () {
    expect(parseAvailableWeekdays('Mon, Wed, Fri'), {1, 3, 5});
    expect(parseAvailableWeekdays('Mon, Tue, Wed, Thu, Fri, Sat, Sun'), {
      1, 2, 3, 4, 5, 6, 7,
    });
    expect(parseAvailableWeekdays('Sat'), {6});
  });

  test('working hours written by Edit Profile parse into slots', () {
    final slots = parseSlotMinutes('8:00 AM - 5:00 PM');
    expect(slots.first, 8 * 60);
    expect(slots.last, 16 * 60 + 30);
    final evening = parseSlotMinutes('2:30 PM - 9:00 PM');
    expect(evening.first, 14 * 60 + 30);
    expect(evening.last, 20 * 60 + 30);
  });
}
