import 'package:sqflite/sqflite.dart';

/// Called only from onCreate, inside sqflite's creation transaction.
Future<void> seedStarterTemplates(DatabaseExecutor db, DateTime now) async {
  const presets = {
    'Weekend Trip': [('Shirt', 'Clothing', 2), ('Toothbrush', 'Toiletries', 1)],
    'Beach Trip': [
      ('Swimsuit', 'Clothing', 1),
      ('Sunscreen', 'Toiletries', 1),
      ('Towel', 'Gear', 1),
    ],
    'Business Trip': [
      ('Business outfit', 'Clothing', 2),
      ('Laptop', 'Electronics', 1),
      ('Charger', 'Electronics', 1),
    ],
  };
  for (final preset in presets.entries) {
    final id = await db.insert('packing_templates', {
      'name': preset.key,
      'created_at': now.toUtc().toIso8601String(),
    });
    final batch = db.batch();
    for (final (name, category, quantity) in preset.value) {
      batch.insert('template_items', {
        'template_id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
      });
    }
    await batch.commit(noResult: true);
  }
}
