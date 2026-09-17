import '../../../core/errors/app_exception.dart';

const _unset = Object();

/// SQLite column contract.
abstract final class PackingTemplateColumns {
  static const id = 'id';
  static const name = 'name';
  static const createdAt = 'created_at';
}

/// Immutable domain value; hydration does not validate user input.
class PackingTemplate {
  const PackingTemplate({this.id, required this.name, required this.createdAt});
  final int? id;
  final String name;
  final DateTime createdAt;

  /// Call at input/repository write boundaries before saving.
  void validate() {
    if (name.trim().isEmpty) {
      throw const ValidationException('Name is required.');
    }
  }

  /// Omitted nullable fields are retained; explicit null clears them.
  PackingTemplate copyWith({
    Object? id = _unset,
    String? name,
    DateTime? createdAt,
  }) => PackingTemplate(
    id: identical(id, _unset) ? this.id : id as int?,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );

  /// UTC ISO-8601 dates and integer booleans for SQLite.
  Map<String, Object?> toMap() => {
    PackingTemplateColumns.id: id,
    PackingTemplateColumns.name: name,
    PackingTemplateColumns.createdAt: createdAt.toUtc().toIso8601String(),
  };
  factory PackingTemplate.fromMap(Map<String, Object?> map) => PackingTemplate(
    id: map[PackingTemplateColumns.id] as int?,
    name: map[PackingTemplateColumns.name] as String,
    createdAt: DateTime.parse(map[PackingTemplateColumns.createdAt] as String)
        .toUtc(),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackingTemplate &&
          id == other.id &&
          name == other.name &&
          createdAt.isAtSameMomentAs(other.createdAt);
  @override
  int get hashCode => Object.hash(id, name, createdAt.toUtc());
}
