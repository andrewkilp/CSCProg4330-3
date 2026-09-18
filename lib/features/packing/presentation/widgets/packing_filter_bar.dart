import 'package:flutter/material.dart';

import '../models/packing_filter.dart';

/// Search, packed-status and category controls. All filtering happens in
/// memory, so there is no loading indicator and nothing is persisted.
class PackingFilterBar extends StatelessWidget {
  const PackingFilterBar({
    super.key,
    required this.filter,
    required this.searchController,
    required this.categories,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.onClear,
  });
  final PackingFilter filter;
  final TextEditingController searchController;
  final List<PackingCategoryOption> categories;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PackedStatusFilter> onStatusChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final known = categories.map((option) => option.key).toSet();
    final selectedCategory = known.contains(filter.category)
        ? filter.category
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('item-search-field'),
            controller: searchController,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Search items',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _Dropdown<PackedStatusFilter>(
            dropdownKey: const ValueKey('item-status-filter'),
            label: 'Packed status',
            value: filter.status,
            items: [
              for (final status in PackedStatusFilter.values)
                DropdownMenuItem(value: status, child: Text(status.label)),
            ],
            onChanged: (value) => onStatusChanged(value!),
          ),
          const SizedBox(height: 12),
          _Dropdown<String?>(
            dropdownKey: const ValueKey('item-category-filter'),
            label: 'Category',
            value: selectedCategory,
            items: [
              for (final option in categories)
                DropdownMenuItem(value: option.key, child: Text(option.label)),
            ],
            onChanged: onCategoryChanged,
          ),
          if (filter.isActive)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey('clear-filters-button'),
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear filters'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.dropdownKey,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final Key dropdownKey;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        key: dropdownKey,
        value: value,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}
