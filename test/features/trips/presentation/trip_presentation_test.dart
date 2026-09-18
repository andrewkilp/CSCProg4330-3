import 'package:csc4330prog3/features/trips/domain/trip.dart';
import 'package:csc4330prog3/features/trips/presentation/trip_schedule_text.dart';
import 'package:csc4330prog3/features/trips/presentation/trip_sections.dart';
import 'package:csc4330prog3/features/trips/presentation/validation/trip_form_validator.dart';
import 'package:flutter_test/flutter_test.dart';

Trip trip({
  required int id,
  required DateTime start,
  DateTime? end,
  String name = 'Trip',
}) => Trip(
  id: id,
  name: name,
  startDate: start,
  endDate: end,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  final now = DateTime(2026, 9, 17, 9, 30);
  DateTime day(int offset) => DateTime(2026, 9, 17 + offset);

  group('splitTrips', () {
    test('divides upcoming and past and orders each section', () {
      final sections = splitTrips([
        trip(id: 1, start: day(5), name: 'Later'),
        trip(id: 2, start: day(-10), name: 'Old'),
        trip(id: 3, start: day(1), name: 'Soon'),
        trip(id: 4, start: day(-2), name: 'Recent'),
        trip(id: 5, start: day(0), name: 'Today'),
      ], now);
      expect(sections.upcoming.map((t) => t.name), ['Today', 'Soon', 'Later']);
      expect(sections.past.map((t) => t.name), ['Recent', 'Old']);
      expect(sections.isEmpty, isFalse);
    });

    test('a trip in progress stays upcoming instead of disappearing', () {
      final sections = splitTrips([
        trip(id: 1, start: day(-2), end: day(3), name: 'Ongoing'),
      ], now);
      expect(sections.upcoming.map((t) => t.name), ['Ongoing']);
      expect(sections.past, isEmpty);
    });

    test('an ended trip uses its end date', () {
      final sections = splitTrips([
        trip(id: 1, start: day(-9), end: day(-1), name: 'Ended'),
      ], now);
      expect(sections.past.map((t) => t.name), ['Ended']);
    });

    test('equal start dates fall back to ID order', () {
      final sections = splitTrips([
        trip(id: 9, start: day(2), name: 'Second'),
        trip(id: 4, start: day(2), name: 'First'),
      ], now);
      expect(sections.upcoming.map((t) => t.name), ['First', 'Second']);
    });

    test('an empty snapshot produces empty sections', () {
      expect(splitTrips(const [], now).isEmpty, isTrue);
    });
  });

  group('tripScheduleLabel', () {
    test('covers today, one day, many days, started and ended', () {
      expect(tripScheduleLabel(trip(id: 1, start: day(0)), now), 'Today');
      expect(tripScheduleLabel(trip(id: 1, start: day(1)), now), '1 day away');
      expect(tripScheduleLabel(trip(id: 1, start: day(4)), now), '4 days away');
      expect(
        tripScheduleLabel(trip(id: 1, start: day(-1), end: day(2)), now),
        'Started',
      );
      expect(
        tripScheduleLabel(trip(id: 1, start: day(-5), end: day(-1)), now),
        'Ended',
      );
      expect(tripScheduleLabel(trip(id: 1, start: day(-5)), now), 'Ended');
    });
  });

  group('TripFormValidator', () {
    test('name must not be blank', () {
      expect(TripFormValidator.name(null), isNotNull);
      expect(TripFormValidator.name('   '), isNotNull);
      expect(TripFormValidator.name(' Weekend '), isNull);
    });

    test('start date is required', () {
      expect(TripFormValidator.startDate(null), isNotNull);
      expect(TripFormValidator.startDate(day(0)), isNull);
    });

    test('end date may not precede the start date', () {
      expect(TripFormValidator.endDate(day(2), day(1)), isNotNull);
      expect(TripFormValidator.endDate(day(2), day(2)), isNull);
      expect(TripFormValidator.endDate(day(2), day(3)), isNull);
      expect(TripFormValidator.endDate(day(2), null), isNull);
      expect(TripFormValidator.endDate(null, day(3)), isNull);
    });
  });
}
