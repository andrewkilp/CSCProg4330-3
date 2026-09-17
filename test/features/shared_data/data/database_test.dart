import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:csc4330prog3/core/errors/app_exception.dart';
import 'package:csc4330prog3/features/shared_data/data/database/app_database.dart';
import 'package:csc4330prog3/features/shared_data/data/database/database_migrations.dart';

void main() {
  sqfliteFfiInit();
  test(
    'concurrent opens share a future and instance; schema and indexes exist',
    () async {
      final owner = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(owner.close);
      final first = owner.database;
      expect(identical(first, owner.database), isTrue);
      final db = await first;
      expect(identical(db, await owner.database), isTrue);
      expect(await db.getVersion(), 1);
      expect(
        (await db.rawQuery('PRAGMA foreign_keys')).single.values.single,
        1,
      );
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ?',
        whereArgs: ['table'],
      );
      expect(
        tables.map((r) => r['name']),
        containsAll([
          'trips',
          'packing_items',
          'packing_templates',
          'template_items',
        ]),
      );
      final indexes = await db.query(
        'sqlite_master',
        where: 'type = ?',
        whereArgs: ['index'],
      );
      expect(
        indexes.map((r) => r['name']),
        containsAll([
          'packing_items_trip',
          'packing_items_packed',
          'template_items_template',
          'trips_start_date',
        ]),
      );
      await expectLater(
        DatabaseMigrations.migrate(db, 1, 2, DateTime.utc(2026)),
        throwsA(isA<StorageException>()),
      );
    },
  );

  test(
    'creation seeds once; reopening never restores deleted presets',
    () async {
      final directory = await Directory.systemTemp.createTemp('packmate_test_');
      addTearDown(() => directory.delete(recursive: true));
      final location = path.join(directory.path, 'test.db');
      final first = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: location,
      );
      final db = await first.database;
      final templates = await db.query('packing_templates');
      expect(
        templates.map((row) => row['name']),
        unorderedEquals(['Weekend Trip', 'Beach Trip', 'Business Trip']),
      );
      expect(await db.query('template_items'), hasLength(8));
      final removed = templates.first['id'];
      await db.delete(
        'packing_templates',
        where: 'id = ?',
        whereArgs: [removed],
      );
      expect(
        await db.query(
          'template_items',
          where: 'template_id = ?',
          whereArgs: [removed],
        ),
        isEmpty,
      );
      await first.close();
      await expectLater(first.database, throwsA(isA<StorageException>()));
      for (var i = 0; i < 2; i++) {
        final reopened = AppDatabase(
          factory: databaseFactoryFfi,
          databasePath: location,
        );
        try {
          final db = await reopened.database;
          expect(await db.query('packing_templates'), hasLength(2));
          expect(await db.query('template_items'), hasLength(6));
        } finally {
          await reopened.close();
        }
      }
    },
  );

  test('close during initialization closes the eventual connection', () async {
    final owner = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    final opening = owner.database;
    await owner.close();
    expect((await opening).isOpen, isFalse);
  });
}
