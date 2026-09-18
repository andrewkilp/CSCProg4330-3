import 'package:flutter/material.dart';

/// Destructive confirmation naming the template being removed.
class DeleteTemplateDialog extends StatelessWidget {
  const DeleteTemplateDialog({super.key, required this.templateName});
  final String templateName;

  static Future<bool> confirm(
    BuildContext context,
    String templateName,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => DeleteTemplateDialog(templateName: templateName),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete template?'),
    content: Text(
      '"$templateName" and its saved items are removed. Trips that already '
      'used it keep their items.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('delete-template-confirm'),
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Delete template'),
      ),
    ],
  );
}
