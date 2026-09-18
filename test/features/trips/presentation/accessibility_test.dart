import 'package:csc4330prog3/features/packing/domain/packing_item.dart';
import 'package:csc4330prog3/features/templates/domain/packing_template.dart';
import 'package:csc4330prog3/features/trips/domain/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';

const longName = 'Weekend Away with the extended family and far too much gear';

TestHarness populatedHarness() {
  final harness = TestHarness();
  harness.tripRepository.rows = [
    Trip(
      id: 1,
      name: longName,
      destination: 'A destination with a deliberately long readable label',
      startDate: DateTime.now().add(const Duration(days: 3)),
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
  harness.itemRepository.rows = [
    PackingItem(
      id: 1,
      tripId: 1,
      name: 'Passport and travel documents folder',
      category: 'Documents',
      quantity: 1,
      isPacked: false,
      createdAt: DateTime(2026, 1, 1),
    ),
    PackingItem(
      id: 2,
      tripId: 1,
      name: 'Shirts',
      category: 'Clothing',
      quantity: 2,
      isPacked: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
  harness.templateRepository.rows = [
    PackingTemplate(
      id: 1,
      name: 'Weekend Trip',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  ];
  return harness;
}

void main() {
  testWidgets('icon-only controls expose tooltips and semantic labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, harness: populatedHarness());
    expect(find.byTooltip('Create trip'), findsOneWidget);
    expect(find.byTooltip('Edit trip'), findsOneWidget);
    expect(find.byTooltip('Duplicate trip'), findsOneWidget);
    expect(find.byTooltip('Delete trip'), findsOneWidget);

    await tester.tap(find.text(longName));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Packing list actions'), findsOneWidget);
    expect(find.byTooltip('Add packing item'), findsOneWidget);
    expect(find.byTooltip('Edit item'), findsWidgets);
    expect(find.byTooltip('Delete item'), findsWidgets);
    // Progress announces both counts rather than relying on the bar alone.
    expect(find.bySemanticsLabel(RegExp('1 of 2 items packed')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Pack Shirts')), findsWidgets);
    semantics.dispose();
  });

  testWidgets('template list delete control is labelled', (tester) async {
    await pumpApp(tester, harness: populatedHarness());
    await tester.tap(find.text('Templates'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Delete template'), findsOneWidget);
  });

  testWidgets('packed state is shown by the checkbox and text, not colour', (
    tester,
  ) async {
    await pumpApp(tester, harness: populatedHarness());
    await tester.tap(find.text(longName));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Checkbox>(find.byKey(const ValueKey('item-check-2'))).value,
      isTrue,
    );
    expect(
      tester.widget<Text>(find.text('Shirts')).style?.decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('main workflows survive 200 percent text on a phone viewport', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(
      tester,
      harness: populatedHarness(),
      surfaceSize: const Size(360, 1600),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(longName));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('add-item-button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
