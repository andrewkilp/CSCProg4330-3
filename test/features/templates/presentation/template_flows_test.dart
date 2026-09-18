import 'dart:async';

import 'package:csc4330prog3/core/errors/app_exception.dart';
import 'package:csc4330prog3/features/templates/domain/packing_template.dart';
import 'package:csc4330prog3/features/templates/domain/template_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../packing/presentation/packing_list_screen_test.dart'
    show openPackingList;

final seeded = DateTime.utc(2026, 1, 1);

PackingTemplate template(int id, String name) =>
    PackingTemplate(id: id, name: name, createdAt: seeded);

TemplateItem templateItem({
  required int id,
  required String name,
  String category = 'Clothing',
  int quantity = 1,
  int templateId = 1,
}) => TemplateItem(
  id: id,
  templateId: templateId,
  name: name,
  category: category,
  quantity: quantity,
);

Future<TestHarness> openTemplates(
  WidgetTester tester, {
  TestHarness? harness,
}) async {
  final active = await pumpApp(tester, harness: harness);
  await tester.tap(find.text('Templates'));
  await tester.pumpAndSettle();
  return active;
}

void main() {
  group('template list', () {
    testWidgets('shows a cold-load indicator, then starter templates', (
      tester,
    ) async {
      final completer = Completer<List<PackingTemplate>>();
      final harness = TestHarness();
      harness.templateRepository.onLoad = () => completer.future;
      // The shell builds every tab, so the pending template load keeps a
      // progress indicator animating; settle only once it resolves.
      await pumpApp(tester, harness: harness, settle: false);
      await tester.pump();
      await tester.tap(find.text('Templates'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('template-list-loading')),
        findsOneWidget,
      );
      completer.complete([
        template(1, 'Weekend Trip'),
        template(2, 'Beach Trip'),
        template(3, 'My list'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Weekend Trip'), findsOneWidget);
      expect(find.text('Beach Trip'), findsOneWidget);
      expect(find.text('My list'), findsOneWidget);
    });

    testWidgets('empty state explains how templates are made', (tester) async {
      final harness = TestHarness();
      harness.templateRepository.rows = [];
      await openTemplates(tester, harness: harness);
      expect(find.text('Your templates'), findsOneWidget);
      expect(
        find.text('Save a packing list as a template to reuse it on any trip.'),
        findsOneWidget,
      );
    });

    testWidgets('a load failure offers a retry', (tester) async {
      final harness = TestHarness();
      var attempts = 0;
      harness.templateRepository.onLoad = () async {
        attempts++;
        if (attempts == 1) {
          throw const StorageException('Templates could not be read.');
        }
        return [template(1, 'Weekend Trip')];
      };
      await openTemplates(tester, harness: harness);
      expect(find.text('Templates could not be loaded'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Weekend Trip'), findsOneWidget);
    });

    testWidgets('delete requires confirmation naming the template', (
      tester,
    ) async {
      final harness = TestHarness();
      harness.templateRepository.rows = [template(1, 'Weekend Trip')];
      await openTemplates(tester, harness: harness);
      await tester.tap(find.byTooltip('Delete template'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Weekend Trip'), findsWidgets);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(harness.templateRepository.rows, hasLength(1));
      await tester.tap(find.byTooltip('Delete template'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-template-confirm')));
      await tester.pumpAndSettle();
      expect(harness.templateRepository.rows, isEmpty);
      expect(find.text('Your templates'), findsOneWidget);
    });
  });

  group('template preview', () {
    testWidgets('loads items only when the preview opens, grouped', (
      tester,
    ) async {
      final harness = TestHarness();
      harness.templateRepository.rows = [template(1, 'Weekend Trip')];
      harness.templateRepository.items = [
        templateItem(id: 1, name: 'Shirts', quantity: 2),
        templateItem(id: 2, name: 'Passport', category: 'Documents'),
        templateItem(id: 3, name: 'Belt', category: ' clothing '),
      ];
      await openTemplates(tester, harness: harness);
      expect(harness.templateRepository.itemLoads, 0);
      await tester.tap(find.text('Weekend Trip'));
      await tester.pumpAndSettle();
      expect(harness.templateRepository.itemLoads, 1);
      expect(find.text('Clothing (2)'), findsOneWidget);
      expect(find.text('Documents (1)'), findsOneWidget);
      expect(find.text('Quantity: 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('template-item-2')), findsOneWidget);
    });
  });

  group('apply a template', () {
    testWidgets('confirms, explains duplicate skipping and reports success', (
      tester,
    ) async {
      final harness = TestHarness();
      harness.templateRepository.rows = [template(1, 'Weekend Trip')];
      var applied = 0;
      harness.templateRepository.onWrite = () async => applied++;
      await openTemplates(tester, harness: harness);
      await tester.tap(find.text('Weekend Trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-template-button')));
      await tester.pumpAndSettle();
      expect(find.text('Trip'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('apply-target-1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('is skipped'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(applied, 0);
      await tester.tap(find.byKey(const ValueKey('apply-target-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-template-confirm')));
      await tester.pumpAndSettle();
      expect(applied, 1);
      expect(find.textContaining('Applied Weekend Trip'), findsOneWidget);
      // The apply screen pops back to the preview after success.
      expect(
        find.byKey(const ValueKey('apply-template-button')),
        findsOneWidget,
      );
    });

    testWidgets('a failure keeps the chooser open and reports it', (
      tester,
    ) async {
      final harness = TestHarness();
      harness.templateRepository.rows = [template(1, 'Weekend Trip')];
      harness.templateRepository.onWrite = () async =>
          throw const StorageException('Template could not be applied.');
      await openTemplates(tester, harness: harness);
      await tester.tap(find.text('Weekend Trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-template-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-target-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-template-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Template could not be applied.'), findsOneWidget);
      expect(find.byKey(const ValueKey('apply-target-1')), findsOneWidget);
    });
  });

  group('save a trip as a template', () {
    testWidgets('rejects a blank name and keeps the packing list visible', (
      tester,
    ) async {
      final harness = await openPackingList(tester);
      await tester.tap(find.byKey(const ValueKey('packing-list-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save as template'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('save-template-name')),
        '   ',
      );
      await tester.tap(find.byKey(const ValueKey('save-template-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a template name.'), findsOneWidget);
      expect(harness.templateRepository.rows, hasLength(1));
    });

    testWidgets('saves through the provider and stays on the packing list', (
      tester,
    ) async {
      final harness = await openPackingList(tester);
      await tester.tap(find.byKey(const ValueKey('packing-list-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save as template'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('save-template-name')),
        '  Weekend Template  ',
      );
      await tester.tap(find.byKey(const ValueKey('save-template-confirm')));
      await tester.pumpAndSettle();
      expect(harness.templateRepository.rows.last.name, 'Weekend Template');
      expect(
        find.text('Saved Weekend Template as a template.'),
        findsOneWidget,
      );
      // The app bar title and the trip summary both name the trip.
      expect(find.text('Weekend Away'), findsWidgets);
    });
  });
}
