import 'package:flutter/material.dart';

import '../../features/packing/domain/packing_item.dart';

class PackingItemRow extends StatelessWidget {
  const PackingItemRow({
    super.key,
    required this.item,
    required this.onPackedChanged,
    required this.onEdit,
    required this.onDelete,
  });
  final PackingItem item;
  final ValueChanged<bool> onPackedChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          key: ValueKey('item-check-${item.id}'),
          value: item.isPacked,
          semanticLabel: 'Pack ${item.name}',
          onChanged: (value) => onPackedChanged(value ?? false),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  decoration: item.isPacked ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(item.category),
              if (item.quantity > 1) Text('Quantity: ${item.quantity}'),
              Wrap(
                children: [
                  IconButton(
                    tooltip: 'Edit item',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete item',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
