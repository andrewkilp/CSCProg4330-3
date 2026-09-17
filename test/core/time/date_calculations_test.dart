import 'package:flutter_test/flutter_test.dart';
import 'package:csc4330prog3/core/time/date_calculations.dart';

void main() {
  final now = DateTime(2026, 9, 16, 23, 59);
  for (final offset in [-1, 0, 1]) {
    test('calendar boundary $offset', () {
      final start = DateTime(2026, 9, 16 + offset);
      expect(daysUntilTrip(start, now), offset);
      expect(isTripUpcoming(start, now), offset >= 0);
      expect(isTripPast(start, now), offset < 0);
      expect(compareDates(start, now).sign, offset);
    });
  }
  test('multi-day trip is not past until after end', () {
    expect(
      isTripPast(DateTime(2026, 9, 15), now, endDate: DateTime(2026, 9, 17)),
      isFalse,
    );
  });
  test('month and daylight-saving calendar boundaries', () {
    expect(daysUntilTrip(DateTime(2027, 1, 1), DateTime(2026, 12, 31, 23)), 1);
    expect(daysUntilTrip(DateTime(2026, 3, 9), DateTime(2026, 3, 8)), 1);
  });
}
