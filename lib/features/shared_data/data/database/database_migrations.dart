import 'package:sqflite/sqflite.dart';

import '../../../../core/errors/app_exception.dart';
import 'database_schema.dart';
import 'starter_templates.dart';

abstract final class DatabaseMigrations {
  static Future<void> migrate(
    Database db,
    int from,
    int to,
    DateTime now,
  ) async {
    for (var version = from + 1; version <= to; version++) {
      switch (version) {
        case 1:
          await DatabaseSchema.create(db);
          await seedStarterTemplates(db, now);
        default:
          throw const StorageException('Unsupported database version.');
      }
    }
  }
}
