import 'dart:async';

import 'package:csc4330prog3/core/errors/app_exception.dart';
import 'package:csc4330prog3/features/packing/domain/packing_item.dart';
import 'package:csc4330prog3/features/trips/domain/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';

PackingItem packingItem({
  required int id,
  required String name,
  String category = 'Clothing',
  bool packed = false,
  int quantity = 1,
}) => PackingItem(
  id: id,
  tripId: 1,
  name: name,
  category: category,
  quantity: quantity,
  isPacked: packed,
  createdAt: DateTime(2026, 1, 1),
);

Future<TestHarness> openPackingList(
  WidgetTester tester, {
  List<PackingItem> items = const [],
  TestHarness? harness,
}) async {
  final active = harness ?? TestHarness();
  active.tripRepository.rows = [
    Trip(
      id: 1,
      name: 'Weekend Away',
      startDate: DateTime.now().add(const Duration(days: 3)),
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
  active.itemRepository.rows = [...items];
  await pumpApp(tester, harness: active);
  await tester.tap(find.text('Weekend Away'));
  await tester.pumpAndSettle();
  return active;
}

void main() {
  testWidgets('groups items and summarizes packed rows', (tester) async {
    await openPackingList(
      tester,
      items: [
        packingItem(id: 1, name: 'Passport', category: 'Documents'),
        packingItem(id: 2, name: 'Shirts', quantity: 2, packed: true),
      ],
    );
    expect(find.text('Clothing (1)'), findsOneWidget);
    expect(find.text('Documents (1)'), findsOneWidget);
    // Quantity does not change the row count: two rows, one of them packed.
    expect(find.text('Packed 1 of 2 items'), findsOneWidget);
    expect(find.text('50% packed'), findsOneWidget);
    expect(find.text('3 days away'), findsOneWidget);
    expect(find.byKey(const ValueKey('item-row-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('item-row-2')), findsOneWidget);
  });

  testWidgets('an empty trip shows the empty state, not a filter message', (
    tester,
  ) async {
    await openPackingList(tester);
    expect(find.text('Nothing packed yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('no-filter-matches')), findsNothing);
    expect(find.text('Packed 0 of 0 items'), findsOneWidget);
    expect(find.text('0% packed'), findsOneWidget);
  });

  testWidgets('toggling a checkbox persists and updates progress', (
    tester,
  ) async {
    final harness = await openPackingList(
      tester,
      items: [packingItem(id: 1, name: 'Passport', category: 'Documents')],
    );
    await tester.tap(find.byKey(const ValueKey('item-check-1')));
    await tester.pumpAndSettle();
    expect(harness.itemRepository.rows.single.isPacked, isTrue);
    expect(find.text('Packed 1 of 1 items'), findsOneWidget);
    expect(find.text('100% packed'), findsOneWidget);
  });

  testWidgets('a failed toggle rolls back and reports the failure', (
    tester,
  ) async {
    final harness = TestHarness();
    final gate = Completer<void>();
    harness.itemRepository.onPacked = (_, _) async {
      await gate.future;
      throw const StorageException('Could not update this item.');
    };
    await openPackingList(
      tester,
      harness: harness,
      items: [packingItem(id: 1, name: 'Passport', category: 'Documents')],
    );
    await tester.tap(find.byKey(const ValueKey('item-check-1')));
    await tester.pump();
    // The row flips before the write completes.
    expect(
      tester.widget<Checkbox>(find.byKey(const ValueKey('item-check-1'))).value,
      isTrue,
    );
    gate.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<Checkbox>(find.byKey(const ValueKey('item-check-1'))).value,
      isFalse,
    );
    // The snack bar reports it and the banner keeps it visible for a retry.
    expect(find.text('Could not update this item.'), findsWidgets);
    expect(find.text('Packed 0 of 1 items'), findsOneWidget);
  });

  testWidgets('search, status and category filters combine and clear', (
    tester,
  ) async {
    await openPackingList(
      tester,
      items: [
        packingItem(id: 1, name: 'Passport', category: 'Documents'),
        packingItem(id: 2, name: 'Shirts', packed: true),
        packingItem(id: 3, name: 'Shorts'),
      ],
    );
    await tester.enterText(
      find.byKey(const ValueKey('item-search-field')),
      'sh',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('item-row-1')), findsNothing);
    expect(find.byKey(const ValueKey('item-row-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('item-row-3')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('item-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unpacked').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('item-row-2')), findsNothing);
    expect(find.byKey(const ValueKey('item-row-3')), findsOneWidget);

    // Shirts is packed, so an unpacked-only search for it matches nothing.
    await tester.enterText(
      find.byKey(const ValueKey('item-search-field')),
      'shirts',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('no-filter-matches')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('clear-filters-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('item-row-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('item-row-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('item-row-3')), findsOneWidget);
  });

  testWidgets('clearing packed items states the count and confirms', (
    tester,
  ) async {
    final harness = await openPackingList(
      tester,
      items: [
        packingItem(
          id: 1,
          name: 'Passport',
          category: 'Documents',
          packed: true,
        ),
        packingItem(id: 2, name: 'Shirts', packed: true),
        packingItem(id: 3, name: 'Shorts'),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('packing-list-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear packed items'));
    await tester.pumpAndSettle();
    expect(find.textContaining('removes 2 packed items'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(harness.itemRepository.rows, hasLength(3));

    await tester.tap(find.byKey(const ValueKey('packing-list-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear packed items'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clear-packed-confirm')));
    await tester.pumpAndSettle();
    expect(harness.itemRepository.rows, hasLength(1));
    expect(find.byKey(const ValueKey('item-row-3')), findsOneWidget);
  });

  testWidgets('deleting an item requires confirmation', (tester) async {
    final harness = await openPackingList(
      tester,
      items: [packingItem(id: 1, name: 'Passport', category: 'Documents')],
    );
    await tester.tap(find.byTooltip('Delete item'));
    await tester.pumpAndSettle();
    expect(find.text('Delete item?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(harness.itemRepository.rows, hasLength(1));
    await tester.tap(find.byTooltip('Delete item'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-delete-confirm')));
    await tester.pumpAndSettle();
    expect(harness.itemRepository.rows, isEmpty);
    expect(find.text('Nothing packed yet'), findsOneWidget);
  });

  testWidgets('a cold load shows one indicator and keeps items on refresh', (
    tester,
  ) async {
    final harness = TestHarness();
    final completer = Completer<List<PackingItem>>();
    harness.itemRepository.onLoad = () => completer.future;
    harness.tripRepository.rows = [
      Trip(
        id: 1,
        name: 'Weekend Away',
        startDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
    await pumpApp(tester, harness: harness);
    await tester.tap(find.text('Weekend Away'));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('packing-list-loading')), findsOneWidget);
    completer.complete([packingItem(id: 1, name: 'Passport')]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('item-row-1')), findsOneWidget);

    harness.itemRepository.onLoad = () async =>
        throw const StorageException('Refresh failed.');
    final provider = harness.dependencies.openPackingProviderFor(1)!;
    await provider.loadItems(force: true);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('item-row-1')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('packing-list-error-banner')),
      findsOneWidget,
    );
  });
}
