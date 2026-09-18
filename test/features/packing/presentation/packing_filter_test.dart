import 'package:csc4330prog3/features/packing/domain/packing_item.dart';
import 'package:csc4330prog3/features/packing/presentation/models/packing_filter.dart';
import 'package:csc4330prog3/features/packing/presentation/models/packing_group.dart';
import 'package:csc4330prog3/features/packing/presentation/validation/packing_item_form_validator.dart';
import 'package:flutter_test/flutter_test.dart';

PackingItem item({
  required int id,
  required String name,
  String category = 'Clothing',
  bool packed = false,
  int quantity = 1,
}) => PackingItem(
  id: id,
  tripId: 1,
  name: name,
  category: category,
  quantity: quantity,
  isPacked: packed,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  final items = [
    item(id: 1, name: 'Passport', category: 'Documents'),
    item(id: 2, name: 'Shirts', packed: true, quantity: 2),
    item(id: 3, name: ' shorts ', category: ' clothing '),
    item(id: 4, name: 'Charger', category: 'Electronics', packed: true),
  ];
  List<String> names(List<PackingItem> result) => [
    for (final row in result) row.name.trim(),
  ];

  group('applyPackingFilter', () {
    test('an empty filter keeps every item', () {
      expect(applyPackingFilter(items, PackingFilter.cleared).length, 4);
      expect(PackingFilter.cleared.isActive, isFalse);
    });

    test('search is trimmed and case-insensitive on names', () {
      expect(
        names(applyPackingFilter(items, const PackingFilter(query: '  SHIR '))),
        ['Shirts'],
      );
      expect(
        names(applyPackingFilter(items, const PackingFilter(query: 'r'))),
        ['Passport', 'Shirts', 'shorts', 'Charger'],
      );
    });

    test('status filters packed and unpacked', () {
      expect(
        names(
          applyPackingFilter(
            items,
            const PackingFilter(status: PackedStatusFilter.packed),
          ),
        ),
        ['Shirts', 'Charger'],
      );
      expect(
        names(
          applyPackingFilter(
            items,
            const PackingFilter(status: PackedStatusFilter.unpacked),
          ),
        ),
        ['Passport', 'shorts'],
      );
    });

    test('category matching is normalized', () {
      expect(
        names(
          applyPackingFilter(items, const PackingFilter(category: 'clothing')),
        ),
        ['Shirts', 'shorts'],
      );
    });

    test('search, status and category combine with AND semantics', () {
      expect(
        names(
          applyPackingFilter(
            items,
            const PackingFilter(
              query: 's',
              status: PackedStatusFilter.unpacked,
              category: 'clothing',
            ),
          ),
        ),
        ['shorts'],
      );
      expect(
        applyPackingFilter(
          items,
          const PackingFilter(
            query: 'passport',
            status: PackedStatusFilter.packed,
          ),
        ),
        isEmpty,
      );
    });

    test('copyWith clears the category with an explicit null', () {
      const filter = PackingFilter(query: 'a', category: 'clothing');
      expect(filter.copyWith().category, 'clothing');
      expect(filter.copyWith(category: null).category, isNull);
      expect(filter.copyWith(query: '  ').isActive, isTrue);
      expect(const PackingFilter().copyWith(query: '   ').isActive, isFalse);
    });

    test('category options list All plus present categories', () {
      final options = categoryOptions(items);
      expect(options.first.key, isNull);
      expect(options.first.label, 'All categories');
      expect(options.skip(1).map((o) => o.key), [
        'clothing',
        'documents',
        'electronics',
      ]);
      expect(options.skip(1).map((o) => o.label), [
        'Clothing',
        'Documents',
        'Electronics',
      ]);
    });

    test('a blank category reads as Uncategorized', () {
      expect(categoryLabel('   '), 'Uncategorized');
      expect(normalizeCategory('  Clothing '), 'clothing');
    });
  });

  group('groupPackingItems', () {
    test('groups by normalized category, unpacked first, then name', () {
      final groups = groupPackingItems([
        item(id: 1, name: 'Zip hoodie'),
        item(id: 2, name: 'Belt', packed: true),
        item(id: 3, name: 'anorak', category: ' clothing '),
        item(id: 4, name: 'Passport', category: 'Documents'),
      ]);
      expect(groups.map((g) => g.label), ['Clothing', 'Documents']);
      expect(groups.first.items.map((i) => i.name), [
        'anorak',
        'Zip hoodie',
        'Belt',
      ]);
    });

    test('an empty list produces no groups', () {
      expect(groupPackingItems(const []), isEmpty);
    });
  });

  group('PackingItemFormValidator', () {
    test('rejects blank names and categories', () {
      expect(PackingItemFormValidator.name('  '), isNotNull);
      expect(PackingItemFormValidator.name(' Socks '), isNull);
      expect(PackingItemFormValidator.category(''), isNotNull);
      expect(PackingItemFormValidator.category('Other'), isNull);
    });

    test('quantity must be a whole number of at least one', () {
      expect(PackingItemFormValidator.quantity(''), isNotNull);
      expect(PackingItemFormValidator.quantity('abc'), isNotNull);
      expect(PackingItemFormValidator.quantity('0'), isNotNull);
      expect(PackingItemFormValidator.quantity('-2'), isNotNull);
      expect(PackingItemFormValidator.quantity(' 3 '), isNull);
      expect(PackingItemFormValidator.parseQuantity(' 3 '), 3);
      expect(PackingItemFormValidator.parseQuantity('oops'), 1);
    });
  });
}
