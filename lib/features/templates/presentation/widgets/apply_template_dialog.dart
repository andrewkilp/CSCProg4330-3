import 'package:flutter/material.dart';

/// Confirms applying a template to one trip and explains duplicate skipping.
/// Duplicate detection itself belongs to the repository, never to this dialog.
class ApplyTemplateDialog extends StatelessWidget {
  const ApplyTemplateDialog({
    super.key,
    required this.templateName,
    required this.tripName,
  });
  final String templateName;
  final String tripName;

  static Future<bool> confirm(
    BuildContext context, {
    required String templateName,
    required String tripName,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) =>
            ApplyTemplateDialog(templateName: templateName, tripName: tripName),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Apply template?'),
    content: Text(
      'Items from "$templateName" are added to "$tripName" and start '
      'unpacked. An item whose name and category already match one in the '
      'trip is skipped, and its existing quantity is kept.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('apply-template-confirm'),
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Apply'),
      ),
    ],
  );
}
