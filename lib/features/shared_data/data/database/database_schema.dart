import 'package:sqflite/sqflite.dart';

abstract final class DatabaseSchema {
  static const version = 1;

  static Future<void> create(DatabaseExecutor db) async {
    final batch = db.batch();
    for (final sql in _statements) {
      batch.execute(sql);
    }
    await batch.commit(noResult: true);
  }

  static const _statements = [
    '''CREATE TABLE trips (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL, destination TEXT,
      start_date TEXT NOT NULL, end_date TEXT, created_at TEXT NOT NULL
    )''',
    '''CREATE TABLE packing_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      trip_id INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      name TEXT NOT NULL, category TEXT NOT NULL,
      quantity INTEGER NOT NULL CHECK(quantity >= 1),
      is_packed INTEGER NOT NULL DEFAULT 0 CHECK(is_packed IN (0,1)),
      created_at TEXT NOT NULL
    )''',
    '''CREATE TABLE packing_templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL, created_at TEXT NOT NULL
    )''',
    '''CREATE TABLE template_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      template_id INTEGER NOT NULL REFERENCES packing_templates(id) ON DELETE CASCADE,
      name TEXT NOT NULL, category TEXT NOT NULL,
      quantity INTEGER NOT NULL CHECK(quantity >= 1)
    )''',
    'CREATE INDEX packing_items_trip ON packing_items(trip_id)',
    'CREATE INDEX packing_items_packed ON packing_items(trip_id, is_packed)',
    'CREATE INDEX template_items_template ON template_items(template_id)',
    'CREATE INDEX trips_start_date ON trips(start_date)',
  ];
}
