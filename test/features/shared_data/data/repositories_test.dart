import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:csc4330prog3/core/errors/app_exception.dart';
import 'package:csc4330prog3/features/shared_data/data/database/app_database.dart';
import 'package:csc4330prog3/features/trips/data/sqlite_trip_repository.dart';
import 'package:csc4330prog3/features/trips/domain/trip.dart';
import 'package:csc4330prog3/features/packing/data/sqlite_packing_item_repository.dart';
import 'package:csc4330prog3/features/packing/domain/packing_item.dart';
import 'package:csc4330prog3/features/templates/data/sqlite_packing_template_repository.dart';

void main() {
  sqfliteFfiInit();
  final now = DateTime.utc(2026, 9, 17);
  late AppDatabase database;
  late SqliteTripRepository trips;
  late SqlitePackingItemRepository items;
  late SqlitePackingTemplateRepository templates;
  Trip trip({String name = ' Trip ', DateTime? start}) => Trip(
    name: name,
    destination: ' Park ',
    startDate: start ?? now,
    createdAt: now,
  );
  PackingItem item(
    int tripId, {
    String name = ' Shirt ',
    String category = ' Clothing ',
    int quantity = 2,
    bool packed = false,
    DateTime? created,
  }) => PackingItem(
    tripId: tripId,
    name: name,
    category: category,
    quantity: quantity,
    isPacked: packed,
    createdAt: created ?? now,
  );
  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
      now: () => now,
    );
    trips = SqliteTripRepository(database, now: () => now);
    items = SqlitePackingItemRepository(database);
    templates = SqlitePackingTemplateRepository(database, now: () => now);
  });
  tearDown(() => database.close());

  test(
    'trip CRUD, trimming, UTC serialization and deterministic ordering',
    () async {
      final later = await trips.createTrip(
        trip(start: now.add(const Duration(days: 1))),
      );
      final first = await trips.createTrip(trip());
      final tied = await trips.createTrip(trip());
      expect((await trips.getAllTrips()).map((t) => t.id), [
        first,
        tied,
        later,
      ]);
      final saved = (await trips.getTripById(first))!;
      expect(saved.name, 'Trip');
      expect(saved.destination, 'Park');
      expect(saved.startDate.isUtc, isTrue);
      await trips.updateTrip(saved.copyWith(name: ' New ', destination: null));
      expect((await trips.getTripById(first))!.name, 'New');
      expect((await trips.getTripById(first))!.destination, isNull);
      await trips.deleteTrip(first);
      expect(await trips.getTripById(first), isNull);
    },
  );

  test(
    'packing CRUD, category/date/id order and trip-scoped packed deletion',
    () async {
      final a = await trips.createTrip(trip());
      final b = await trips.createTrip(trip());
      final z = await items.createItem(item(a, category: 'z'));
      final early = await items.createItem(
        item(
          a,
          category: ' a ',
          created: now.subtract(const Duration(seconds: 1)),
        ),
      );
      final tied1 = await items.createItem(item(a, category: 'A'));
      final tied2 = await items.createItem(item(a, category: ' a'));
      final other = await items.createItem(item(b, packed: true));
      final all = await items.getItemsForTrip(a);
      expect(all.map((i) => i.id), [early, tied1, tied2, z]);
      expect(all.first.name, 'Shirt');
      expect(all.first.category, 'a');
      await items.updateItem(all.first.copyWith(name: ' Socks ', quantity: 3));
      expect((await items.getItemsForTrip(a)).first.quantity, 3);
      await items.setPacked(early, true);
      expect((await items.getItemsForTrip(a)).first.isPacked, isTrue);
      await items.deletePackedItems(a);
      expect((await items.getItemsForTrip(a)).map((i) => i.id), [
        tied1,
        tied2,
        z,
      ]);
      expect((await items.getItemsForTrip(b)).single.id, other);
      await items.deleteItem(z);
      await trips.deleteTrip(a);
      expect(await items.getItemsForTrip(a), isEmpty);
      expect(await items.getItemsForTrip(b), hasLength(1));
    },
  );

  test(
    'validation and typed not-found errors cover every ID-based write',
    () async {
      final id = await trips.createTrip(trip());
      await expectLater(
        trips.createTrip(trip(name: ' ')),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        trips.updateTrip(trip()),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        trips.createTrip(
          trip().copyWith(endDate: now.subtract(const Duration(days: 1))),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        items.createItem(item(id, quantity: 0)),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        items.createItem(item(id, name: ' ')),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        items.updateItem(item(id)),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        templates.saveTripAsTemplate(id, ' '),
        throwsA(isA<ValidationException>()),
      );
      final operations = <Future<dynamic> Function()>[
        () => trips.updateTrip(trip().copyWith(id: 999)),
        () => trips.deleteTrip(999),
        () => trips.duplicateTrip(999, newName: 'Copy', newStartDate: now),
        () => items.createItem(item(999)),
        () => items.updateItem(item(id).copyWith(id: 999)),
        () => items.setPacked(999, true),
        () => items.deleteItem(999),
        () => items.deletePackedItems(999),
        () => templates.getTemplateItems(999),
        () => templates.saveTripAsTemplate(999, 'Saved'),
        () => templates.applyTemplateToTrip(999, id),
        () => templates.applyTemplateToTrip(1, 999),
        () => templates.deleteTemplate(999),
      ];
      for (final operation in operations) {
        await expectLater(operation(), throwsA(isA<NotFoundException>()));
      }
    },
  );

  test('save/apply skips normalized and intra-template duplicates, preserves quantities', () async {
    final source = await trips.createTrip(trip());
    await items.createItem(item(source, packed: true));
    await items.createItem(
      item(source, name: 'SHIRT', category: 'clothing', quantity: 8),
    );
    await items.createItem(
      item(source, name: 'Shirt', category: 'Gear', packed: true),
    );
    final template = await templates.saveTripAsTemplate(source, ' Saved ');
    expect(
      (await templates.getAllTemplates())
          .firstWhere((t) => t.id == template)
          .name,
      'Saved',
    );
    expect(await templates.getTemplateItems(template), hasLength(3));
    final target = await trips.createTrip(trip());
    await items.createItem(
      item(
        target,
        name: 'shirt',
        category: 'CLOTHING',
        quantity: 9,
        packed: true,
      ),
    );
    await templates.applyTemplateToTrip(template, target);
    await templates.applyTemplateToTrip(template, target);
    final applied = await items.getItemsForTrip(target);
    expect(applied, hasLength(2));
    expect(applied.first.quantity, 9);
    expect(applied.first.isPacked, isTrue);
    expect(applied.last.isPacked, isFalse);
    final empty = await trips.createTrip(trip());
    await templates.applyTemplateToTrip(template, empty);
    expect(await items.getItemsForTrip(empty), hasLength(2));
    await templates.deleteTemplate(template);
    final db = await database.database;
    expect(
      await db.query(
        'template_items',
        where: 'template_id = ?',
        whereArgs: [template],
      ),
      isEmpty,
    );
    expect(await items.getItemsForTrip(target), hasLength(2));
  });

  test(
    'trip ordering respects fractional seconds of different precision',
    () async {
      final later = await trips.createTrip(
        trip(start: now.add(const Duration(microseconds: 1))),
      );
      final earlier = await trips.createTrip(trip());
      expect((await trips.getAllTrips()).map((t) => t.id), [earlier, later]);
    },
  );

  test('empty trips can be saved as empty templates', () async {
    final source = await trips.createTrip(trip());
    final template = await templates.saveTripAsTemplate(source, 'Empty');
    expect(await templates.getTemplateItems(template), isEmpty);
    await templates.applyTemplateToTrip(template, source);
    expect(await items.getItemsForTrip(source), isEmpty);
  });

  test(
    'duplicated trips have independent unpacked rows and requested dates',
    () async {
      final source = await trips.createTrip(
        trip().copyWith(endDate: now.add(const Duration(days: 1))),
      );
      final originalItem = await items.createItem(item(source, packed: true));
      final copy = await trips.duplicateTrip(
        source,
        newName: ' Copy ',
        newStartDate: now.add(const Duration(days: 4)),
      );
      final copiedTrip = (await trips.getTripById(copy))!;
      expect(copiedTrip.name, 'Copy');
      expect(copiedTrip.endDate, isNull);
      expect(copiedTrip.startDate, now.add(const Duration(days: 4)));
      final copiedItem = (await items.getItemsForTrip(copy)).single;
      expect(copiedItem.id, isNot(originalItem));
      expect(copiedItem.isPacked, isFalse);
      expect(copiedItem.quantity, 2);
      await items.updateItem(copiedItem.copyWith(quantity: 7));
      await trips.deleteTrip(copy);
      expect((await items.getItemsForTrip(source)).single.isPacked, isTrue);
      expect((await items.getItemsForTrip(source)).single.quantity, 2);
    },
  );

  test(
    'SQLite constraints enforce foreign keys, quantities and booleans',
    () async {
      final db = await database.database;
      await expectLater(
        db.insert('packing_items', item(999).toMap()),
        throwsA(isA<DatabaseException>()),
      );
      final id = await trips.createTrip(trip());
      await expectLater(
        db.insert('packing_items', item(id, quantity: 0).toMap()),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.insert('packing_items', {...item(id).toMap(), 'is_packed': 2}),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.insert('template_items', {
          'template_id': 999,
          'name': 'a',
          'category': 'b',
          'quantity': 1,
        }),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test(
    'failed batch operations roll back all rows and map storage errors',
    () async {
      final source = await trips.createTrip(trip());
      await items.createItem(item(source));
      await items.createItem(item(source, name: 'Fail'));
      final template = await templates.saveTripAsTemplate(source, 'Atomic');
      final target = await trips.createTrip(trip());
      final db = await database.database;
      await db.execute(
        "CREATE TRIGGER fail_item BEFORE INSERT ON packing_items WHEN NEW.name = 'Fail' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      await expectLater(
        templates.applyTemplateToTrip(template, target),
        throwsA(isA<StorageException>()),
      );
      expect(await items.getItemsForTrip(target), isEmpty);
      final before = (await trips.getAllTrips()).length;
      await expectLater(
        trips.duplicateTrip(source, newName: 'Copy', newStartDate: now),
        throwsA(isA<StorageException>()),
      );
      expect(await trips.getAllTrips(), hasLength(before));
      await db.execute(
        "CREATE TRIGGER fail_template BEFORE INSERT ON template_items WHEN NEW.name = 'Fail' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      final beforeTemplates = (await templates.getAllTemplates()).length;
      await expectLater(
        templates.saveTripAsTemplate(source, 'Fail'),
        throwsA(isA<StorageException>()),
      );
      expect(await templates.getAllTemplates(), hasLength(beforeTemplates));
    },
  );
}
