import '../../../packing/presentation/models/packing_filter.dart';
import '../../domain/template_item.dart';

/// Preview grouping for a template's items. It reuses the packing list's
/// category normalization so a preview reads the same way a trip does.
class TemplateCategoryGroup {
  const TemplateCategoryGroup({required this.label, required this.items});
  final String label;
  final List<TemplateItem> items;
}

List<TemplateCategoryGroup> groupTemplateItems(List<TemplateItem> items) {
  final labels = <String, String>{};
  final grouped = <String, List<TemplateItem>>{};
  for (final item in items) {
    final key = normalizeCategory(item.category);
    labels.putIfAbsent(key, () => categoryLabel(item.category));
    grouped.putIfAbsent(key, () => <TemplateItem>[]).add(item);
  }
  final keys = grouped.keys.toList()..sort();
  return [
    for (final key in keys)
      TemplateCategoryGroup(
        label: labels[key]!,
        items: grouped[key]!..sort(_byName),
      ),
  ];
}

int _byName(TemplateItem a, TemplateItem b) {
  final byName = a.name.trim().toLowerCase().compareTo(
    b.name.trim().toLowerCase(),
  );
  return byName != 0 ? byName : (a.id ?? 0).compareTo(b.id ?? 0);
}
