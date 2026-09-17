import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../../../core/errors/app_exception.dart';
import 'database_migrations.dart';
import 'database_schema.dart';

/// One owner per app. Repositories share this lazily opened connection.
class AppDatabase {
  AppDatabase({this.factory, String? databasePath, DateTime Function()? now})
    : _path = databasePath,
      _now = now ?? DateTime.now;

  final DatabaseFactory? factory;
  final String? _path;
  final DateTime Function() _now;
  Future<Database>? _opening;
  bool _closed = false;

  Future<Database> get database {
    if (_closed) {
      return Future.error(
        const StorageException('The database has been closed.'),
      );
    }
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
      final factory = this.factory ?? databaseFactory;
      final location =
          _path ?? path.join(await factory.getDatabasesPath(), 'packmate.db');
      return await factory.openDatabase(
        location,
        options: OpenDatabaseOptions(
          version: DatabaseSchema.version,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, version) =>
              DatabaseMigrations.migrate(db, 0, version, _now()),
          onUpgrade: (db, oldVersion, newVersion) =>
              DatabaseMigrations.migrate(db, oldVersion, newVersion, _now()),
          onDowngrade: (db, oldVersion, newVersion) async {
            throw const StorageException(
              'This database requires a newer app version.',
            );
          },
        ),
      );
    } on DatabaseException {
      _opening = null;
      throw const StorageException('Could not open the packing database.');
    }
  }

  /// Terminal lifecycle operation; create a new owner to reopen the file.
  Future<void> close() async {
    _closed = true;
    final opening = _opening;
    if (opening != null) {
      await (await opening).close();
    }
  }
}
