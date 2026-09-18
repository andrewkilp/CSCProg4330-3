import 'package:flutter/material.dart';

import '../../../../shared/widgets/category_heading.dart';
import '../../../../shared/widgets/packing_item_row.dart';
import '../../domain/packing_item.dart';
import '../models/packing_group.dart';

/// Sliver list of category headings and packing rows. Row order and grouping
/// are computed once by the caller and passed in already built.
class CategorizedItemList extends StatelessWidget {
  CategorizedItemList({
    super.key,
    required List<PackingCategoryGroup> groups,
    required this.onPackedChanged,
    required this.onEdit,
    required this.onDelete,
  }) : _rows = [
         for (final group in groups) ...[
           _HeadingRow(group.label, group.items.length),
           ...group.items,
         ],
       ];

  final List<Object> _rows;
  final void Function(PackingItem item, bool isPacked) onPackedChanged;
  final ValueChanged<PackingItem> onEdit;
  final ValueChanged<PackingItem> onDelete;

  @override
  Widget build(BuildContext context) => SliverList.builder(
    itemCount: _rows.length,
    itemBuilder: (context, index) {
      final row = _rows[index];
      if (row is _HeadingRow) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Semantics(
            header: true,
            child: CategoryHeading(
              category: row.label,
              itemCount: row.itemCount,
            ),
          ),
        );
      }
      final item = row as PackingItem;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: PackingItemRow(
          key: ValueKey('item-row-${item.id}'),
          item: item,
          onPackedChanged: (value) => onPackedChanged(item, value),
          onEdit: () => onEdit(item),
          onDelete: () => onDelete(item),
        ),
      );
    },
  );
}

class _HeadingRow {
  const _HeadingRow(this.label, this.itemCount);
  final String label;
  final int itemCount;
}
