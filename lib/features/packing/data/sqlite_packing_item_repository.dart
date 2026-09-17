import '../domain/packing_item.dart';
import '../domain/packing_item_repository.dart';
import '../../shared_data/data/database/app_database.dart';
import '../../shared_data/data/repository_support.dart';

class SqlitePackingItemRepository implements PackingItemRepository {
  SqlitePackingItemRepository(this._database);
  final AppDatabase _database;

  PackingItem _clean(PackingItem item) {
    final clean = item.copyWith(
      name: item.name.trim(),
      category: item.category.trim(),
    );
    clean.validate();
    return clean;
  }

  @override
  Future<List<PackingItem>> getItemsForTrip(int tripId) =>
      withStorageContext('Could not load packing items.', () async {
        final db = await _database.database;
        final items = (await db.query(
          'packing_items',
          where: 'trip_id = ?',
          whereArgs: [tripId],
        )).map(PackingItem.fromMap).toList();
        // Dart normalization also handles non-ASCII text consistently with templates.
        items.sort((a, b) {
          final category = a.category.trim().toLowerCase().compareTo(
            b.category.trim().toLowerCase(),
          );
          if (category != 0) return category;
          final created = a.createdAt.compareTo(b.createdAt);
          return created != 0 ? created : a.id!.compareTo(b.id!);
        });
        return items;
      });

  @override
  Future<int> createItem(PackingItem item) =>
      withStorageContext('Could not create the packing item.', () async {
        final clean = _clean(item).copyWith(id: null);
        final db = await _database.database;
        return db.transaction((txn) async {
          await requireRow(txn, 'trips', clean.tripId, 'Trip');
          return txn.insert('packing_items', clean.toMap());
        });
      });

  @override
  Future<void> updateItem(PackingItem item) =>
      withStorageContext('Could not update the packing item.', () async {
        final id = persistedId(item.id);
        final clean = _clean(item);
        final db = await _database.database;
        await db.transaction((txn) async {
          await requireRow(txn, 'trips', clean.tripId, 'Trip');
          requireChanged(
            await txn.update(
              'packing_items',
              clean.toMap(),
              where: 'id = ?',
              whereArgs: [id],
            ),
            'Packing item',
          );
        });
      });

  @override
  Future<void> setPacked(int itemId, bool isPacked) =>
      withStorageContext('Could not change packed status.', () async {
        final db = await _database.database;
        requireChanged(
          await db.update(
            'packing_items',
            {'is_packed': isPacked ? 1 : 0},
            where: 'id = ?',
            whereArgs: [itemId],
          ),
          'Packing item',
        );
      });

  @override
  Future<void> deleteItem(int itemId) => withStorageContext(
    'Could not delete the packing item.',
    () async {
      final db = await _database.database;
      requireChanged(
        await db.delete('packing_items', where: 'id = ?', whereArgs: [itemId]),
        'Packing item',
      );
    },
  );

  @override
  Future<void> deletePackedItems(int tripId) =>
      withStorageContext('Could not delete packed items.', () async {
        final db = await _database.database;
        await db.transaction((txn) async {
          await requireRow(txn, 'trips', tripId, 'Trip');
          await txn.delete(
            'packing_items',
            where: 'trip_id = ? AND is_packed = 1',
            whereArgs: [tripId],
          );
        });
      });
}
