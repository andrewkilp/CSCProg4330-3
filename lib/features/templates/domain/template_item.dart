import '../../../core/errors/app_exception.dart';

const _unset = Object();

/// SQLite column contract.
abstract final class TemplateItemColumns {
  static const id = 'id';
  static const templateId = 'template_id';
  static const name = 'name';
  static const category = 'category';
  static const quantity = 'quantity';
}

/// Immutable domain value; hydration does not validate user input.
class TemplateItem {
  const TemplateItem({
    this.id,
    required this.templateId,
    required this.name,
    required this.category,
    required this.quantity,
  });
  final int? id;
  final int templateId;
  final String name;
  final String category;
  final int quantity;

  /// Call at input/repository write boundaries before saving.
  void validate() {
    if (name.trim().isEmpty) {
      throw const ValidationException('Name is required.');
    }
    if (quantity < 1) {
      throw const ValidationException('Quantity must be at least one.');
    }
  }

  /// Omitted nullable fields are retained; explicit null clears them.
  TemplateItem copyWith({
    Object? id = _unset,
    int? templateId,
    String? name,
    String? category,
    int? quantity,
  }) => TemplateItem(
    id: identical(id, _unset) ? this.id : id as int?,
    templateId: templateId ?? this.templateId,
    name: name ?? this.name,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
  );

  /// UTC ISO-8601 dates and integer booleans for SQLite.
  Map<String, Object?> toMap() => {
    TemplateItemColumns.id: id,
    TemplateItemColumns.templateId: templateId,
    TemplateItemColumns.name: name,
    TemplateItemColumns.category: category,
    TemplateItemColumns.quantity: quantity,
  };
  factory TemplateItem.fromMap(Map<String, Object?> map) => TemplateItem(
    id: map[TemplateItemColumns.id] as int?,
    templateId: map[TemplateItemColumns.templateId] as int,
    name: map[TemplateItemColumns.name] as String,
    category: map[TemplateItemColumns.category] as String,
    quantity: map[TemplateItemColumns.quantity] as int,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateItem &&
          id == other.id &&
          templateId == other.templateId &&
          name == other.name &&
          category == other.category &&
          quantity == other.quantity;
  @override
  int get hashCode => Object.hash(id, templateId, name, category, quantity);
}
