import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/bootstrap/app_dependencies.dart';
import '../../../../app/navigation/route_arguments.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/packing_item.dart';
import '../../providers/packing_list_provider.dart';
import '../models/packing_filter.dart';
import '../validation/packing_item_form_validator.dart';

/// One form for creating and editing a packing item. It writes through the
/// packing provider the open trip detail already owns, so the list updates.
class PackingItemFormScreen extends StatefulWidget {
  const PackingItemFormScreen({super.key, required this.arguments});
  final PackingItemFormArguments arguments;
  @override
  State<PackingItemFormScreen> createState() => _PackingItemFormScreenState();
}

class _PackingItemFormScreenState extends State<PackingItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PackingItem? _existing = widget.arguments.item;
  late final TextEditingController _name = TextEditingController(
    text: _existing?.name ?? '',
  );
  late final TextEditingController _category = TextEditingController(
    text: _existing?.category ?? '',
  );
  late final TextEditingController _quantity = TextEditingController(
    text: '${_existing?.quantity ?? PackingItemFormValidator.defaultQuantity}',
  );
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _quantity.dispose();
    super.dispose();
  }

  List<String> get _suggestions {
    final merged = <String, String>{};
    for (final category in [
      ...PackingItemFormValidator.defaultCategories,
      ...widget.arguments.knownCategories,
    ]) {
      merged.putIfAbsent(normalizeCategory(category), () => category.trim());
    }
    return merged.values.toList();
  }

  bool get _isDirty =>
      _name.text != (_existing?.name ?? '') ||
      _category.text != (_existing?.category ?? '') ||
      _quantity.text !=
          '${_existing?.quantity ?? PackingItemFormValidator.defaultQuantity}';

  Future<bool> _confirmDiscard() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your unsaved item details will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              key: const ValueKey('item-form-discard'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _save(PackingListProvider provider) async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final quantity = PackingItemFormValidator.parseQuantity(_quantity.text);
    try {
      final existing = _existing;
      if (existing == null) {
        await provider.createItem(
          PackingItem(
            tripId: widget.arguments.tripId,
            name: _name.text.trim(),
            category: _category.text.trim(),
            quantity: quantity,
            isPacked: false,
            createdAt: DateTime.now(),
          ),
        );
      } else {
        await provider.updateItem(
          existing.copyWith(
            name: _name.text.trim(),
            category: _category.text.trim(),
            quantity: quantity,
          ),
        );
      }
      navigator.pop(true);
    } on AppException catch (error) {
      // Entered values are kept so the user can correct and retry.
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppDependencies>().openPackingProviderFor(
      widget.arguments.tripId,
    );
    if (provider == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Packing item')),
        body: const ErrorState(
          title: 'Packing list unavailable',
          message: 'Open the trip again to add or edit items.',
        ),
      );
    }
    return PopScope(
      canPop: !_isDirty || _submitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.arguments.isEditing ? 'Edit item' : 'New item'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const ValueKey('item-name-field'),
                controller: _name,
                autofocus: !widget.arguments.isEditing,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                validator: PackingItemFormValidator.name,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  helperText: 'Required',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('item-category-field'),
                controller: _category,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                validator: PackingItemFormValidator.category,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Category',
                  helperText: 'Required',
                  border: const OutlineInputBorder(),
                  suffixIcon: PopupMenuButton<String>(
                    key: const ValueKey('item-category-suggestions'),
                    tooltip: 'Choose a category',
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (value) => setState(() {
                      _category.text = value;
                    }),
                    itemBuilder: (context) => [
                      for (final suggestion in _suggestions)
                        PopupMenuItem(
                          value: suggestion,
                          child: Text(suggestion),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('item-quantity-field'),
                controller: _quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                validator: PackingItemFormValidator.quantity,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  helperText: 'At least 1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('item-form-save'),
                onPressed: _submitting ? null : () => _save(provider),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.arguments.isEditing ? 'Save item' : 'Add item',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
