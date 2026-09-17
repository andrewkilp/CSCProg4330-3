import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:csc4330prog3/core/errors/app_exception.dart';
import 'package:csc4330prog3/features/templates/domain/packing_template.dart';
import 'package:csc4330prog3/features/templates/domain/template_item.dart';
import 'package:csc4330prog3/features/templates/providers/template_provider.dart';
import 'package:csc4330prog3/features/packing/providers/packing_list_provider.dart';

import '../../shared_data/providers/fake_repositories.dart';

Future<void> tick() => Future<void>.delayed(Duration.zero);
void main() {
  late FakeTemplateRepository repository;
  late TemplateProvider provider;
  late List<int> affected;
  setUp(() {
    repository = FakeTemplateRepository();
    affected = [];
    provider = TemplateProvider(
      repository,
      onTripItemsChanged: (id) async => affected.add(id),
    );
  });
  tearDown(() => provider.dispose());

  test(
    'initial load fetches names only; immutable item cache loads on demand',
    () async {
      final gate = Completer<List<PackingTemplate>>();
      repository.onLoad = () => gate.future;
      final first = provider.loadTemplates();
      expect(identical(first, provider.loadTemplates()), isTrue);
      await tick();
      expect(provider.isInitialLoading, isTrue);
      gate.complete(repository.rows);
      await first;
      expect(repository.itemLoads, 0);
      expect(() => provider.templates.clear(), throwsUnsupportedError);
      await provider.loadTemplates();
      expect(repository.loads, 1);
      final itemGate = Completer<List<TemplateItem>>();
      repository.onItemLoad = () => itemGate.future;
      final items = provider.loadTemplateItems(1);
      expect(identical(items, provider.loadTemplateItems(1)), isTrue);
      await tick();
      expect(provider.loadingItemIds, {1});
      expect(() => provider.loadingItemIds.clear(), throwsUnsupportedError);
      itemGate.complete(repository.items);
      await items;
      expect(provider.loadingItemIds, isEmpty);
      expect(() => provider.templateItems.clear(), throwsUnsupportedError);
      expect(() => provider.templateItems[1]!.clear(), throwsUnsupportedError);
      await provider.loadTemplateItems(1);
      expect(repository.itemLoads, 1);
      repository.onItemLoad = null;
      await provider.loadTemplateItems(1, force: true);
      expect(repository.itemLoads, 2);
    },
  );

  test('failed list and item refresh retain previous snapshots', () async {
    await provider.loadTemplates();
    await provider.loadTemplateItems(1);
    repository.onLoad = () async =>
        throw const StorageException('List failed.');
    await provider.loadTemplates(force: true);
    expect(provider.templates, hasLength(1));
    expect(provider.error?.message, 'List failed.');
    repository.onItemLoad = () async =>
        throw const StorageException('Items failed.');
    await provider.loadTemplateItems(1, force: true);
    expect(provider.templateItems[1], hasLength(1));
    expect(provider.error?.message, 'Items failed.');
    expect(provider.loadingItemIds, isEmpty);
  });

  test('save, apply coordination and delete invalidate owned cache', () async {
    await provider.loadTemplates();
    await provider.loadTemplateItems(1);
    final id = await provider.saveTripAsTemplate(1, 'New');
    expect(provider.templates.last.id, id);
    final gate = Completer<void>();
    repository.onWrite = () => gate.future;
    final apply = provider.applyTemplateToTrip(1, 42);
    await tick();
    expect(provider.isMutating, isTrue);
    expect(provider.templates, hasLength(2));
    expect(affected, isEmpty);
    gate.complete();
    await apply;
    expect(affected, [42]);
    repository.onWrite = null;
    await provider.deleteTemplate(1);
    expect(provider.templateItems.containsKey(1), isFalse);
    expect(provider.templates, hasLength(1));
  });

  test('failed apply does not invalidate; retry clears the error', () async {
    repository.onWrite = () async =>
        throw const StorageException('Apply failed.');
    await expectLater(
      provider.applyTemplateToTrip(1, 2),
      throwsA(isA<StorageException>()),
    );
    expect(affected, isEmpty);
    expect(provider.error?.message, 'Apply failed.');
    repository.onWrite = null;
    await provider.applyTemplateToTrip(1, 2);
    expect(affected, [2]);
    expect(provider.error, isNull);
  });

  test(
    'successful apply reloads the affected active packing provider',
    () async {
      final packingRepository = FakePackingRepository();
      final packing = PackingListProvider(packingRepository, tripId: 1);
      final coordinated = TemplateProvider(
        repository,
        onTripItemsChanged: packing.reloadAfterTemplate,
      );
      addTearDown(packing.dispose);
      addTearDown(coordinated.dispose);
      await packing.loadItems();
      repository.onWrite = () async => packingRepository.rows.add(testItem(2));
      await coordinated.applyTemplateToTrip(1, 1);
      expect(packing.items, hasLength(2));
    },
  );

  test('late item completion after dispose does not populate cache', () async {
    final local = TemplateProvider(
      repository,
      onTripItemsChanged: (_) async {},
    );
    final gate = Completer<List<TemplateItem>>();
    repository.onItemLoad = () => gate.future;
    final load = local.loadTemplateItems(1);
    await tick();
    local.dispose();
    gate.complete(repository.items);
    await load;
    expect(local.templateItems, isEmpty);
  });
}
