import '../../domain/packing_item.dart';

const Object _unset = Object();

/// Packed-state filter offered beside search and category.
enum PackedStatusFilter {
  all('All'),
  unpacked('Unpacked'),
  packed('Packed');

  const PackedStatusFilter(this.label);
  final String label;
}

/// Matching key for a category: trimmed and case-insensitive, the same rule the
/// repository uses when it skips duplicate template items.
String normalizeCategory(String category) => category.trim().toLowerCase();

/// Readable label for a category; a blank category reads as Uncategorized.
String categoryLabel(String category) =>
    category.trim().isEmpty ? 'Uncategorized' : category.trim();

class PackingCategoryOption {
  const PackingCategoryOption({required this.key, required this.label});

  /// Normalized key, or null for the "All categories" entry.
  final String? key;
  final String label;
}

/// Transient presentation-only filter state. It is never persisted, so filters
/// reset on every launch.
class PackingFilter {
  const PackingFilter({
    this.query = '',
    this.status = PackedStatusFilter.all,
    this.category,
  });
  final String query;
  final PackedStatusFilter status;

  /// Normalized category key; null means every category.
  final String? category;

  static const cleared = PackingFilter();

  bool get isActive =>
      query.trim().isNotEmpty ||
      status != PackedStatusFilter.all ||
      category != null;

  PackingFilter copyWith({
    String? query,
    PackedStatusFilter? status,
    Object? category = _unset,
  }) => PackingFilter(
    query: query ?? this.query,
    status: status ?? this.status,
    category: identical(category, _unset) ? this.category : category as String?,
  );
}

/// Pure AND combination of search, packed status and category. Search is
/// trimmed and case-insensitive over item names.
List<PackingItem> applyPackingFilter(
  List<PackingItem> items,
  PackingFilter filter,
) {
  final query = filter.query.trim().toLowerCase();
  final category = filter.category;
  return [
    for (final item in items)
      if ((query.isEmpty || item.name.trim().toLowerCase().contains(query)) &&
          (filter.status == PackedStatusFilter.all ||
              item.isPacked == (filter.status == PackedStatusFilter.packed)) &&
          (category == null || normalizeCategory(item.category) == category))
        item,
  ];
}

/// "All categories" plus every category present in the unfiltered list.
List<PackingCategoryOption> categoryOptions(List<PackingItem> items) {
  final labels = <String, String>{};
  for (final item in items) {
    labels.putIfAbsent(
      normalizeCategory(item.category),
      () => categoryLabel(item.category),
    );
  }
  final keys = labels.keys.toList()..sort();
  return [
    const PackingCategoryOption(key: null, label: 'All categories'),
    for (final key in keys)
      PackingCategoryOption(key: key, label: labels[key]!),
  ];
}
