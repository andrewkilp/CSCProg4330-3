/// Field-level rules for the packing item form, mirroring PackingItem.validate.
abstract final class PackingItemFormValidator {
  /// Offered in the category dropdown; categories are plain text, not a table.
  static const defaultCategories = <String>[
    'Clothing',
    'Toiletries',
    'Documents',
    'Electronics',
    'Other',
  ];
  static const defaultQuantity = 1;

  static String? name(String? value) =>
      (value ?? '').trim().isEmpty ? 'Enter an item name.' : null;

  static String? category(String? value) =>
      (value ?? '').trim().isEmpty ? 'Choose a category.' : null;

  static String? quantity(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter a quantity.';
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Enter a whole number.';
    return parsed < 1 ? 'Quantity must be at least 1.' : null;
  }

  static int parseQuantity(String? value) =>
      int.tryParse((value ?? '').trim()) ?? defaultQuantity;
}
