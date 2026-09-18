import 'package:flutter/material.dart';

/// Destructive confirmation naming the item being removed.
class PackingItemDeleteDialog extends StatelessWidget {
  const PackingItemDeleteDialog({super.key, required this.itemName});
  final String itemName;

  static Future<bool> confirm(BuildContext context, String itemName) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => PackingItemDeleteDialog(itemName: itemName),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete item?'),
    content: Text('"$itemName" is removed from this packing list.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('item-delete-confirm'),
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Delete item'),
      ),
    ],
  );
}
