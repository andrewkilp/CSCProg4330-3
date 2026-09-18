import 'package:flutter/material.dart';

/// Asks for a nonblank template name. The provider copies the trip's items;
/// this dialog never reads or builds item rows.
class SaveTemplateDialog extends StatefulWidget {
  const SaveTemplateDialog({super.key, required this.suggestedName});
  final String suggestedName;

  static Future<String?> requestName(
    BuildContext context,
    String suggestedName,
  ) => showDialog<String>(
    context: context,
    builder: (context) => SaveTemplateDialog(suggestedName: suggestedName),
  );

  @override
  State<SaveTemplateDialog> createState() => _SaveTemplateDialogState();
}

class _SaveTemplateDialogState extends State<SaveTemplateDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.suggestedName,
  );
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter a template name.');
      return;
    }
    Navigator.of(context).pop(_name.text.trim());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Save as template'),
    content: TextField(
      key: const ValueKey('save-template-name'),
      controller: _name,
      autofocus: true,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: 'Template name',
        errorText: _error,
        border: const OutlineInputBorder(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('save-template-confirm'),
        onPressed: _submit,
        child: const Text('Save template'),
      ),
    ],
  );
}
