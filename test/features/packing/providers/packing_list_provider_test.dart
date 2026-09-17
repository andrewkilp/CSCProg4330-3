import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:csc4330prog3/core/errors/app_exception.dart';
import 'package:csc4330prog3/features/packing/domain/packing_item.dart';
import 'package:csc4330prog3/features/packing/providers/packing_list_provider.dart';

import '../../shared_data/providers/fake_repositories.dart';

Future<void> tick() => Future<void>.delayed(Duration.zero);
void main() {
  late FakePackingRepository repository;
  late PackingListProvider provider;
  setUp(() {
    repository = FakePackingRepository();
    provider = PackingListProvider(repository, tripId: 1);
  });
  tearDown(() => provider.dispose());

  test(
    'initial/refresh loading, immutable snapshot and retained data on error',
    () async {
      expect(provider.completionPercentage, 0);
      final gate = Completer<List<PackingItem>>();
      repository.onLoad = () => gate.future;
      final first = provider.loadItems();
      expect(identical(first, provider.loadItems()), isTrue);
      await tick();
      expect(provider.isInitialLoading, isTrue);
      gate.complete(repository.rows);
      await first;
      expect(() => provider.items.clear(), throwsUnsupportedError);
      await provider.loadItems();
      expect(repository.loads, 1);
      final refreshGate = Completer<List<PackingItem>>();
      repository.onLoad = () => refreshGate.future;
      final refresh = provider.loadItems(force: true);
      await tick();
      expect(provider.isInitialLoading, isFalse);
      expect(provider.isRefreshing, isTrue);
      expect(provider.items, hasLength(1));
      refreshGate.completeError(const StorageException('Refresh failed.'));
      await refresh;
      expect(provider.items, hasLength(1));
      expect(provider.error, isA<StorageException>());
    },
  );

  test('optimistic toggle updates counts before persistence and rolls back on failure', () async {
    await provider.loadItems();
    final gate = Completer<void>();
    repository.onPacked = (_, _) => gate.future;
    final toggle = provider.setPacked(1, true);
    await tick();
    expect(provider.items.single.isPacked, isTrue);
    expect(provider.packedCount, 1);
    expect(provider.totalCount, 1);
    expect(provider.completionPercentage, 100);
    expect(repository.rows.single.isPacked, isFalse);
    expect(provider.isMutating, isTrue);
    final failed = expectLater(toggle, throwsA(isA<StorageException>()));
    gate.completeError(const StorageException('Toggle failed.'));
    await failed;
    expect(provider.packedCount, 0);
    expect(provider.items.single.isPacked, isFalse);
    expect(provider.error?.message, 'Toggle failed.');
    repository.onPacked = null;
    await provider.setPacked(1, true);
    expect(repository.rows.single.isPacked, isTrue);
    expect(provider.items.single.isPacked, isTrue);
    expect(provider.error, isNull);
  });

  test('rapid opposite toggles are persisted in order', () async {
    await provider.loadItems();
    final gate = Completer<void>();
    var calls = 0;
    repository.onPacked = (_, _) async {
      if (++calls == 1) await gate.future;
    };
    final first = provider.setPacked(1, true);
    final second = provider.setPacked(1, false);
    await tick();
    expect(calls, 1);
    gate.complete();
    await Future.wait([first, second]);
    expect(calls, 2);
    expect(provider.items.single.isPacked, isFalse);
    expect(repository.rows.single.isPacked, isFalse);
  });

  test('CRUD, packed deletion and trip ownership guards', () async {
    await provider.loadItems();
    final id = await provider.createItem(testItem(null));
    await provider.updateItem(testItem(id).copyWith(quantity: 4));
    expect(provider.items.last.quantity, 4);
    await provider.setPacked(1, true);
    await provider.deletePackedItems();
    expect(provider.items.single.id, id);
    await expectLater(
      provider.createItem(testItem(null).copyWith(tripId: 2)),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      provider.updateItem(testItem(id).copyWith(tripId: 2)),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      provider.setPacked(999, true),
      throwsA(isA<NotFoundException>()),
    );
    await expectLater(
      provider.deleteItem(999),
      throwsA(isA<NotFoundException>()),
    );
    await provider.deleteItem(id);
    expect(provider.items, isEmpty);
  });

  test(
    'template reload queues behind in-flight load and ignores other trips',
    () async {
      final gate = Completer<List<PackingItem>>();
      repository.onLoad = () => gate.future;
      final first = provider.loadItems();
      await tick();
      final reload = provider.reloadAfterTemplate(1);
      repository.rows.add(testItem(2));
      repository.onLoad = null;
      gate.complete([testItem()]);
      await Future.wait([first, reload]);
      expect(provider.items, hasLength(2));
      expect(repository.loads, 2);
      await provider.reloadAfterTemplate(2);
      expect(repository.loads, 2);
    },
  );

  test(
    'dispose while a toggle fails does not notify disposed listeners',
    () async {
      final local = PackingListProvider(repository, tripId: 1);
      await local.loadItems();
      final gate = Completer<void>();
      repository.onPacked = (_, _) => gate.future;
      final toggle = local.setPacked(1, true);
      await tick();
      local.dispose();
      final failed = expectLater(toggle, throwsA(isA<StorageException>()));
      gate.completeError(const StorageException('Failed.'));
      await failed;
    },
  );
}
