import 'package:sqflite/sqflite.dart';

import '../../../core/errors/app_exception.dart';

Future<T> withStorageContext<T>(
  String message,
  Future<T> Function() action,
) async {
  try {
    return await action();
  } on DatabaseException {
    throw StorageException(message);
  }
}

int persistedId(int? id) {
  if (id == null) {
    throw const ValidationException('A saved record ID is required.');
  }
  return id;
}

void requireChanged(int count, String entity) {
  if (count == 0) {
    throw NotFoundException('$entity was not found.');
  }
}

Future<Map<String, Object?>> requireRow(
  DatabaseExecutor db,
  String table,
  int id,
  String entity,
) async {
  final rows = await db.query(
    table,
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  if (rows.isEmpty) {
    throw NotFoundException('$entity was not found.');
  }
  return rows.single;
}
