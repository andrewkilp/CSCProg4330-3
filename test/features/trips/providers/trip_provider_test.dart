import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:csc4330prog3/core/errors/app_exception.dart';
import 'package:csc4330prog3/features/trips/domain/trip.dart';
import 'package:csc4330prog3/features/trips/providers/trip_provider.dart';

import '../../shared_data/providers/fake_repositories.dart';

Future<void> tick() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeTripRepository repository;
  late TripProvider provider;
  setUp(() {
    repository = FakeTripRepository();
    provider = TripProvider(repository);
  });
  tearDown(() => provider.dispose());

  test('initial load is deduplicated, cached and immutable', () async {
    final pending = Completer<List<Trip>>();
    repository.onLoad = () => pending.future;
    final load = provider.loadTrips();
    expect(identical(load, provider.loadTrips()), isTrue);
    await tick();
    expect(provider.isInitialLoading, isTrue);
    expect(provider.isMutating, isFalse);
    pending.complete(repository.rows);
    await load;
    expect(provider.isInitialLoading, isFalse);
    expect(provider.trips, [testTrip()]);
    expect(() => provider.trips.clear(), throwsUnsupportedError);
    repository.rows.clear();
    expect(provider.trips, hasLength(1));
    await provider.loadTrips();
    expect(repository.loads, 1);
  });

  test(
    'refresh retains data on failure; a new operation clears error',
    () async {
      await provider.loadTrips();
      final pending = Completer<List<Trip>>();
      repository.onLoad = () => pending.future;
      final refresh = provider.loadTrips(force: true);
      await tick();
      expect(provider.isInitialLoading, isFalse);
      expect(provider.isRefreshing, isTrue);
      expect(provider.trips, hasLength(1));
      pending.completeError(const StorageException('Refresh failed.'));
      await refresh;
      expect(provider.error?.message, 'Refresh failed.');
      expect(provider.trips, hasLength(1));
      repository.onLoad = null;
      await provider.loadTrips(force: true);
      expect(provider.error, isNull);
    },
  );

  test('CRUD and duplicate refresh data, mutation remains separate from initial loading', () async {
    await provider.loadTrips();
    final gate = Completer<void>();
    repository.onWrite = () => gate.future;
    final create = provider.createTrip(testTrip(null));
    await tick();
    expect(provider.isMutating, isTrue);
    expect(provider.isInitialLoading, isFalse);
    expect(provider.trips, hasLength(1));
    gate.complete();
    final id = await create;
    repository.onWrite = null;
    await provider.updateTrip(testTrip(id).copyWith(name: 'Changed'));
    expect(provider.trips.last.name, 'Changed');
    final copy = await provider.duplicateTrip(
      id,
      newName: 'Copy',
      newStartDate: testDate,
    );
    expect(provider.trips.last.id, copy);
    await provider.deleteTrip(id);
    expect(provider.trips.map((t) => t.id), [1, copy]);
    expect(provider.isMutating, isFalse);
  });

  test('write failure is exposed and rethrown; queue can recover', () async {
    await provider.loadTrips();
    repository.onWrite = () async =>
        throw const StorageException('Write failed.');
    await expectLater(
      provider.createTrip(testTrip(null)),
      throwsA(isA<StorageException>()),
    );
    expect(provider.error?.message, 'Write failed.');
    expect(provider.trips, hasLength(1));
    expect(provider.isMutating, isFalse);
    repository.onWrite = null;
    await provider.createTrip(testTrip(null));
    expect(provider.error, isNull);
  });

  test(
    'successful write is not reported as failed if subsequent refresh fails',
    () async {
      await provider.loadTrips();
      repository.onLoad = () async =>
          throw const StorageException('Reload failed.');
      expect(await provider.createTrip(testTrip(null)), 2);
      expect(repository.rows, hasLength(2));
      expect(provider.trips, hasLength(1));
      expect(provider.error?.message, 'Reload failed.');
    },
  );

  test('an earlier delayed load cannot overwrite a later mutation', () async {
    final gate = Completer<List<Trip>>();
    repository.onLoad = () => gate.future;
    final load = provider.loadTrips();
    final create = provider.createTrip(testTrip(null));
    await tick();
    expect(repository.rows, hasLength(1));
    repository.onLoad = null;
    gate.complete([testTrip()]);
    await Future.wait([load, create]);
    expect(provider.trips, hasLength(2));
  });

  test(
    'initial failure can retry and empty successful data counts as loaded',
    () async {
      repository.onLoad = () async =>
          throw const StorageException('Unavailable.');
      await provider.loadTrips();
      expect(provider.error, isA<StorageException>());
      expect(provider.isInitialLoading, isFalse);
      repository.onLoad = null;
      repository.rows.clear();
      await provider.loadTrips();
      await provider.loadTrips();
      expect(repository.loads, 2);
      expect(provider.error, isNull);
    },
  );

  test(
    'late completion does not notify or replace data after disposal',
    () async {
      final local = TripProvider(repository);
      var notifications = 0;
      local.addListener(() => notifications++);
      final gate = Completer<List<Trip>>();
      repository.onLoad = () => gate.future;
      final load = local.loadTrips();
      await tick();
      local.dispose();
      final before = notifications;
      gate.complete(repository.rows);
      await load;
      expect(notifications, before);
      expect(local.trips, isEmpty);
    },
  );
}
