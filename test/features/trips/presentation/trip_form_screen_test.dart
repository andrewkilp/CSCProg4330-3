import 'dart:async';

import 'package:csc4330prog3/core/errors/app_exception.dart';
import 'package:csc4330prog3/features/trips/domain/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';

Trip savedTrip() => Trip(
  id: 1,
  name: 'Weekend Away',
  destination: 'Lake',
  startDate: DateTime.now().add(const Duration(days: 4)),
  endDate: DateTime.now().add(const Duration(days: 6)),
  createdAt: DateTime(2026, 1, 1),
);

Future<TestHarness> openCreateForm(WidgetTester tester) async {
  final harness = TestHarness();
  harness.tripRepository.rows = [];
  await pumpApp(tester, harness: harness);
  await tester.tap(find.byKey(const ValueKey('create-trip-button')));
  await tester.pumpAndSettle();
  return harness;
}

Future<TestHarness> openEditForm(WidgetTester tester) async {
  final harness = TestHarness();
  harness.tripRepository.rows = [savedTrip()];
  await pumpApp(tester, harness: harness);
  await tester.tap(find.byTooltip('Edit trip'));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  testWidgets('create mode reports a blank name and a missing start date', (
    tester,
  ) async {
    final harness = await openCreateForm(tester);
    await tester.tap(find.byKey(const ValueKey('trip-form-save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a trip name.'), findsOneWidget);
    expect(find.text('Choose a start date.'), findsOneWidget);
    expect(harness.tripRepository.rows, isEmpty);
  });

  testWidgets('create mode saves a trimmed name with a chosen date', (
    tester,
  ) async {
    final harness = await openCreateForm(tester);
    await tester.enterText(
      find.byKey(const ValueKey('trip-name-field')),
      '  Weekend Away  ',
    );
    await tester.tap(find.text('Not set').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trip-form-save')));
    await tester.pumpAndSettle();
    expect(harness.tripRepository.rows, hasLength(1));
    expect(harness.tripRepository.rows.single.name, 'Weekend Away');
    expect(harness.tripRepository.rows.single.destination, isNull);
    expect(find.text('Weekend Away'), findsOneWidget);
  });

  testWidgets('edit mode populates existing values', (tester) async {
    await openEditForm(tester);
    expect(find.text('Edit trip'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Weekend Away'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Lake'), findsOneWidget);
    expect(find.text('Not set'), findsNothing);
  });

  testWidgets('an end date before the start date is rejected', (tester) async {
    final harness = await openEditForm(tester);
    await tester.tap(find.byTooltip('Clear End date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not set'));
    await tester.pumpAndSettle();
    // The picker opens on today, which is before this trip's start date.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      find.text('End date cannot be before the start date.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('trip-form-save')));
    await tester.pumpAndSettle();
    expect(harness.tripRepository.rows.single.name, 'Weekend Away');
    expect(find.text('Edit trip'), findsOneWidget);
  });

  testWidgets('the submit guard blocks a double tap', (tester) async {
    final harness = await openEditForm(tester);
    var writes = 0;
    final completer = Completer<void>();
    harness.tripRepository.onWrite = () async {
      writes++;
      await completer.future;
    };
    await tester.enterText(
      find.byKey(const ValueKey('trip-name-field')),
      'Renamed',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('trip-form-save')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('trip-form-save')));
    await tester.pump();
    expect(writes, 1);
    completer.complete();
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(harness.tripRepository.rows.single.name, 'Renamed');
  });

  testWidgets('a save failure keeps the entered values on screen', (
    tester,
  ) async {
    final harness = await openEditForm(tester);
    harness.tripRepository.onWrite = () async =>
        throw const StorageException('Trip could not be saved.');
    await tester.enterText(
      find.byKey(const ValueKey('trip-name-field')),
      'Renamed',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('trip-form-save')));
    await tester.pumpAndSettle();
    expect(find.text('Trip could not be saved.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Renamed'), findsOneWidget);
    expect(find.text('Edit trip'), findsOneWidget);
  });

  testWidgets('leaving a changed form asks before discarding', (tester) async {
    await openEditForm(tester);
    await tester.enterText(
      find.byKey(const ValueKey('trip-name-field')),
      'Renamed',
    );
    await tester.pump();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
    navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Edit trip'), findsOneWidget);
    navigator.maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trip-form-discard')));
    await tester.pumpAndSettle();
    expect(find.text('Edit trip'), findsNothing);
  });
}
