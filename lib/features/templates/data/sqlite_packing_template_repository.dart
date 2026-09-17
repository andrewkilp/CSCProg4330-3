import '../domain/packing_template.dart';
import '../domain/packing_template_repository.dart';
import '../domain/template_item.dart';
import '../../shared_data/data/database/app_database.dart';
import '../../shared_data/data/repository_support.dart';

class SqlitePackingTemplateRepository implements PackingTemplateRepository {
  SqlitePackingTemplateRepository(this._database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final AppDatabase _database;
  final DateTime Function() _now;

  @override
  Future<List<PackingTemplate>> getAllTemplates() =>
      withStorageContext('Could not load templates.', () async {
        final db = await _database.database;
        return (await db.query(
          'packing_templates',
          orderBy: 'name COLLATE NOCASE, id',
        )).map(PackingTemplate.fromMap).toList();
      });

  @override
  Future<List<TemplateItem>> getTemplateItems(int templateId) =>
      withStorageContext('Could not load template items.', () async {
        final db = await _database.database;
        return db.transaction((txn) async {
          await requireRow(txn, 'packing_templates', templateId, 'Template');
          return (await txn.query(
            'template_items',
            where: 'template_id = ?',
            whereArgs: [templateId],
            orderBy: 'id',
          )).map(TemplateItem.fromMap).toList();
        });
      });

  @override
  Future<int> saveTripAsTemplate(int tripId, String templateName) =>
      withStorageContext('Could not save the template.', () async {
        final template = PackingTemplate(
          name: templateName.trim(),
          createdAt: _now(),
        );
        template.validate();
        final db = await _database.database;
        return db.transaction((txn) async {
          await requireRow(txn, 'trips', tripId, 'Trip');
          final items = await txn.query(
            'packing_items',
            where: 'trip_id = ?',
            whereArgs: [tripId],
            orderBy: 'id',
          );
          final id = await txn.insert('packing_templates', template.toMap());
          final batch = txn.batch();
          for (final item in items) {
            batch.insert('template_items', {
              'template_id': id,
              'name': item['name'],
              'category': item['category'],
              'quantity': item['quantity'],
            });
          }
          await batch.commit(noResult: true);
          return id;
        });
      });

  @override
  Future<void> applyTemplateToTrip(int templateId, int tripId) =>
      withStorageContext('Could not apply the template.', () async {
        final db = await _database.database;
        await db.transaction((txn) async {
          await requireRow(txn, 'trips', tripId, 'Trip');
          await requireRow(txn, 'packing_templates', templateId, 'Template');
          final existing = await txn.query(
            'packing_items',
            columns: ['name', 'category'],
            where: 'trip_id = ?',
            whereArgs: [tripId],
          );
          (String, String) key(Map<String, Object?> row) => (
            (row['name'] as String).trim().toLowerCase(),
            (row['category'] as String).trim().toLowerCase(),
          );
          final seen = existing.map(key).toSet();
          final items = await txn.query(
            'template_items',
            where: 'template_id = ?',
            whereArgs: [templateId],
            orderBy: 'id',
          );
          final batch = txn.batch();
          final createdAt = _now().toUtc().toIso8601String();
          for (final item in items) {
            if (!seen.add(key(item))) continue;
            batch.insert('packing_items', {
              'trip_id': tripId,
              'name': (item['name'] as String).trim(),
              'category': (item['category'] as String).trim(),
              'quantity': item['quantity'],
              'is_packed': 0,
              'created_at': createdAt,
            });
          }
          await batch.commit(noResult: true);
        });
      });

  @override
  Future<void> deleteTemplate(int templateId) =>
      withStorageContext('Could not delete the template.', () async {
        final db = await _database.database;
        requireChanged(
          await db.delete(
            'packing_templates',
            where: 'id = ?',
            whereArgs: [templateId],
          ),
          'Template',
        );
      });
}
