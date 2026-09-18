import 'dart:async';

import 'package:csc4330prog3/core/errors/app_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import 'packing_list_screen_test.dart' show openPackingList, packingItem;

void main() {
  Future<TestHarness> openCreate(WidgetTester tester) async {
    final harness = await openPackingList(tester);
    await tester.tap(find.byKey(const ValueKey('add-item-button')));
    await tester.pumpAndSettle();
    return harness;
  }

  Future<TestHarness> openEdit(WidgetTester tester) async {
    final harness = await openPackingList(
      tester,
      items: [
        packingItem(id: 1, name: 'Shirts', category: 'Clothing', quantity: 2),
      ],
    );
    await tester.tap(find.byTooltip('Edit item'));
    await tester.pumpAndSettle();
    return harness;
  }

  testWidgets('create mode defaults quantity to 1 and validates', (
    tester,
  ) async {
    final harness = await openCreate(tester);
    expect(find.widgetWithText(TextFormField, '1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('item-form-save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter an item name.'), findsOneWidget);
    expect(find.text('Choose a category.'), findsOneWidget);
    expect(harness.itemRepository.rows, isEmpty);
  });

  testWidgets('a quantity below one is rejected', (tester) async {
    final harness = await openCreate(tester);
    await tester.enterText(
      find.byKey(const ValueKey('item-name-field')),
      'Passport',
    );
    await tester.enterText(
      find.byKey(const ValueKey('item-category-field')),
      'Documents',
    );
    await tester.enterText(
      find.byKey(const ValueKey('item-quantity-field')),
      '0',
    );
    await tester.tap(find.byKey(const ValueKey('item-form-save')));
    await tester.pumpAndSettle();
    expect(find.text('Quantity must be at least 1.'), findsOneWidget);
    expect(harness.itemRepository.rows, isEmpty);
  });

  testWidgets('create trims values and starts the item unpacked', (
    tester,
  ) async {
    final harness = await openCreate(tester);
    await tester.enterText(
      find.byKey(const ValueKey('item-name-field')),
      '  Passport  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('item-category-field')),
      '  Documents  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('item-quantity-field')),
      '3',
    );
    await tester.tap(find.byKey(const ValueKey('item-form-save')));
    await tester.pumpAndSettle();
    final saved = harness.itemRepository.rows.single;
    expect(saved.name, 'Passport');
    expect(saved.category, 'Documents');
    expect(saved.quantity, 3);
    expect(saved.isPacked, isFalse);
    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('Documents (1)'), findsOneWidget);
  });

  testWidgets('a category suggestion fills the field', (tester) async {
    await openCreate(tester);
    await tester.tap(find.byKey(const ValueKey('item-category-suggestions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Electronics').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Electronics'), findsOneWidget);
  });

  testWidgets('edit mode populates and updates the item', (tester) async {
    final harness = await openEdit(tester);
    expect(find.text('Edit item'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Shirts'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Clothing'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '2'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('item-name-field')),
      'Linen shirts',
    );
    await tester.tap(find.byKey(const ValueKey('item-form-save')));
    await tester.pumpAndSettle();
    expect(harness.itemRepository.rows.single.name, 'Linen shirts');
    expect(harness.itemRepository.rows.single.quantity, 2);
    expect(find.text('Linen shirts'), findsOneWidget);
  });

  testWidgets('a save failure keeps the entered values', (tester) async {
    final harness = await openCreate(tester);
    harness.itemRepository.onWrite = () async =>
        throw const StorageException('Item could not be saved.');
    await tester.enterText(
      find.byKey(const ValueKey('item-name-field')),
      'Passport',
    );
    await tester.enterText(
      find.byKey(const ValueKey('item-category-field')),
      'Documents',
    );
    await tester.tap(find.byKey(const ValueKey('item-form-save')));
    await tester.pumpAndSettle();
    expect(find.text('Item could not be saved.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Passport'), findsOneWidget);
    expect(find.text('New item'), findsOneWidget);
  });

  testWidgets('the submit guard blocks a double tap', (tester) async {
    final harness = await openCreate(tester);
    var writes = 0;
    final completer = Completer<void>();
    harness.itemRepository.onWrite = () async {
      writes++;
      await completer.future;
    };
    await tester.enterText(
      find.byKey(const ValueKey('item-name-field')),
      'Passport',
    );
    await tester.enterText(
      find.byKey(const ValueKey('item-category-field')),
      'Documents',
    );
    await tester.tap(find.byKey(const ValueKey('item-form-save')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('item-form-save')));
    await tester.pump();
    expect(writes, 1);
    completer.complete();
    await tester.pumpAndSettle();
    expect(harness.itemRepository.rows, hasLength(1));
  });

  testWidgets('leaving a changed item form asks before discarding', (
    tester,
  ) async {
    await openCreate(tester);
    await tester.enterText(
      find.byKey(const ValueKey('item-name-field')),
      'Passport',
    );
    await tester.pump();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
    navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('item-form-discard')));
    await tester.pumpAndSettle();
    expect(find.text('New item'), findsNothing);
  });

  testWidgets('a new item lists existing categories as suggestions', (
    tester,
  ) async {
    await openPackingList(
      tester,
      items: [packingItem(id: 1, name: 'Tent', category: 'Camping gear')],
    );
    await tester.tap(find.byKey(const ValueKey('add-item-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-category-suggestions')));
    await tester.pumpAndSettle();
    expect(find.text('Camping gear'), findsOneWidget);
  });
}
