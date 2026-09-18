import 'package:flutter/material.dart';

/// Destructive confirmation that states how many rows will be removed.
class ClearPackedDialog extends StatelessWidget {
  const ClearPackedDialog({super.key, required this.packedCount});
  final int packedCount;

  static Future<bool> confirm(BuildContext context, int packedCount) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => ClearPackedDialog(packedCount: packedCount),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Clear packed items?'),
    content: Text(
      packedCount == 1
          ? 'This removes 1 packed item from this trip. This cannot be undone.'
          : 'This removes $packedCount packed items from this trip. '
                'This cannot be undone.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('clear-packed-confirm'),
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Clear packed'),
      ),
    ],
  );
}
