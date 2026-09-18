import 'package:flutter/material.dart';

/// Destructive confirmation that names the trip and its packing items.
class TripDeleteDialog extends StatelessWidget {
  const TripDeleteDialog({super.key, required this.tripName});
  final String tripName;

  static Future<bool> confirm(BuildContext context, String tripName) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => TripDeleteDialog(tripName: tripName),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete trip?'),
    content: Text(
      'Deleting "$tripName" also deletes every packing item saved for it. '
      'This cannot be undone.',
    ),
    actions: [
      TextButton(
        key: const ValueKey('trip-delete-cancel'),
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('trip-delete-confirm'),
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Delete trip'),
      ),
    ],
  );
}
