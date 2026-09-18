import 'dart:async';

import 'package:csc4330prog3/core/errors/app_exception.dart';
import 'package:csc4330prog3/features/trips/domain/trip.dart';
import 'package:csc4330prog3/shared/widgets/trip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';

Trip trip({
  required int id,
  required String name,
  required DateTime start,
  DateTime? end,
}) => Trip(
  id: id,
  name: name,
  startDate: start,
  endDate: end,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  DateTime day(int offset) => DateTime.now().add(Duration(days: offset));

  testWidgets('shows a cold-load indicator, then the trips', (tester) async {
    final completer = Completer<List<Trip>>();
    final harness = TestHarness();
    harness.tripRepository.onLoad = () => completer.future;
    await pumpApp(tester, harness: harness, settle: false);
    await tester.pump();
    expect(find.byKey(const ValueKey('trip-list-loading')), findsOneWidget);
    completer.complete([trip(id: 1, name: 'Weekend Away', start: day(3))]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trip-list-loading')), findsNothing);
    expect(find.text('Weekend Away'), findsOneWidget);
  });

  testWidgets('empty state offers a create action', (tester) async {
    final harness = TestHarness();
    harness.tripRepository.rows = [];
    await pumpApp(tester, harness: harness);
    expect(find.text('Your trips'), findsOneWidget);
    expect(
      find.text('Create your first trip to start a packing list.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('create-trip-button')));
    await tester.pumpAndSettle();
    expect(find.text('New trip'), findsOneWidget);
  });

  testWidgets('load failure shows a retry that reloads', (tester) async {
    final harness = TestHarness();
    var attempts = 0;
    harness.tripRepository.onLoad = () async {
      attempts++;
      if (attempts == 1) {
        throw const StorageException('Trips could not be read.');
      }
      return [trip(id: 1, name: 'Recovered', start: day(2))];
    };
    await pumpApp(tester, harness: harness);
    expect(find.text('Trips could not be loaded'), findsOneWidget);
    expect(find.text('Trips could not be read.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered'), findsOneWidget);
  });

  testWidgets('divides upcoming and past trips in order', (tester) async {
    final harness = TestHarness();
    harness.tripRepository.rows = [
      trip(id: 1, name: 'Later', start: day(20)),
      trip(id: 2, name: 'Old', start: day(-30)),
      trip(id: 3, name: 'Soon', start: day(2)),
      trip(id: 4, name: 'Recent', start: day(-3)),
    ];
    await pumpApp(tester, harness: harness);
    expect(find.text('Upcoming (2)'), findsOneWidget);
    expect(find.text('Past (2)'), findsOneWidget);
    final cards = tester
        .widgetList<TripCard>(find.byType(TripCard))
        .map((card) => card.trip.name)
        .toList();
    expect(cards, ['Soon', 'Later', 'Recent', 'Old']);
  });

  testWidgets('delete asks for confirmation naming the trip', (tester) async {
    final harness = TestHarness();
    harness.tripRepository.rows = [
      trip(id: 1, name: 'Weekend Away', start: day(4)),
    ];
    await pumpApp(tester, harness: harness);
    await tester.tap(find.byTooltip('Delete trip'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Weekend Away'), findsWidgets);
    expect(find.textContaining('packing item'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('trip-delete-cancel')));
    await tester.pumpAndSettle();
    expect(harness.tripRepository.rows, hasLength(1));
    await tester.tap(find.byTooltip('Delete trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trip-delete-confirm')));
    await tester.pumpAndSettle();
    expect(harness.tripRepository.rows, isEmpty);
    expect(find.text('Your trips'), findsOneWidget);
  });

  testWidgets('duplicate collects a name and calls the provider', (
    tester,
  ) async {
    final harness = TestHarness();
    harness.tripRepository.rows = [
      trip(id: 1, name: 'Weekend Away', start: day(4)),
    ];
    await pumpApp(tester, harness: harness);
    await tester.tap(find.byTooltip('Duplicate trip'));
    await tester.pumpAndSettle();
    expect(find.text('Weekend Away copy'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('duplicate-trip-name')),
      '  Second Trip  ',
    );
    await tester.tap(find.byKey(const ValueKey('duplicate-trip-confirm')));
    await tester.pumpAndSettle();
    expect(harness.tripRepository.rows, hasLength(2));
    expect(harness.tripRepository.rows.last.name, 'Second Trip');
    expect(find.text('Second Trip'), findsWidgets);
  });

  testWidgets('a blank duplicate name is rejected in the dialog', (
    tester,
  ) async {
    final harness = TestHarness();
    harness.tripRepository.rows = [
      trip(id: 1, name: 'Weekend Away', start: day(4)),
    ];
    await pumpApp(tester, harness: harness);
    await tester.tap(find.byTooltip('Duplicate trip'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('duplicate-trip-name')),
      '   ',
    );
    await tester.tap(find.byKey(const ValueKey('duplicate-trip-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a trip name.'), findsOneWidget);
    expect(harness.tripRepository.rows, hasLength(1));
  });

  testWidgets('a failed refresh keeps the visible trips', (tester) async {
    final harness = TestHarness();
    harness.tripRepository.rows = [
      trip(id: 1, name: 'Weekend Away', start: day(4)),
    ];
    await pumpApp(tester, harness: harness);
    expect(find.text('Weekend Away'), findsOneWidget);
    harness.tripRepository.onLoad = () async =>
        throw const StorageException('Refresh failed.');
    await harness.dependencies.trips.loadTrips(force: true);
    await tester.pumpAndSettle();
    expect(find.text('Weekend Away'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('trip-list-error-banner')),
      findsOneWidget,
    );
  });
}
