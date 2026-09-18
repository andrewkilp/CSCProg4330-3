import '../../domain/packing_item.dart';
import 'packing_filter.dart';

class PackingCategoryGroup {
  const PackingCategoryGroup({required this.label, required this.items});
  final String label;
  final List<PackingItem> items;
}

/// Groups by normalized category while keeping a readable label. Categories are
/// ordered by their normalized key; inside a category unpacked items come
/// first, then name alphabetically, then ID. Built once per item/filter change.
List<PackingCategoryGroup> groupPackingItems(List<PackingItem> items) {
  final labels = <String, String>{};
  final grouped = <String, List<PackingItem>>{};
  for (final item in items) {
    final key = normalizeCategory(item.category);
    labels.putIfAbsent(key, () => categoryLabel(item.category));
    grouped.putIfAbsent(key, () => <PackingItem>[]).add(item);
  }
  final keys = grouped.keys.toList()..sort();
  return [
    for (final key in keys)
      PackingCategoryGroup(
        label: labels[key]!,
        items: grouped[key]!..sort(_byPackedThenName),
      ),
  ];
}

int _byPackedThenName(PackingItem a, PackingItem b) {
  if (a.isPacked != b.isPacked) return a.isPacked ? 1 : -1;
  final byName = a.name.trim().toLowerCase().compareTo(
    b.name.trim().toLowerCase(),
  );
  return byName != 0 ? byName : (a.id ?? 0).compareTo(b.id ?? 0);
}
