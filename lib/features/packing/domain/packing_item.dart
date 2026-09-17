import '../../../core/errors/app_exception.dart';

const _unset = Object();

/// SQLite column contract.
abstract final class PackingItemColumns {
  static const id = 'id';
  static const tripId = 'trip_id';
  static const name = 'name';
  static const category = 'category';
  static const quantity = 'quantity';
  static const isPacked = 'is_packed';
  static const createdAt = 'created_at';
}

/// Immutable domain value; hydration does not validate user input.
class PackingItem {
  const PackingItem({
    this.id,
    required this.tripId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.isPacked,
    required this.createdAt,
  });
  final int? id;
  final int tripId;
  final String name;
  final String category;
  final int quantity;
  final bool isPacked;
  final DateTime createdAt;

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
  PackingItem copyWith({
    Object? id = _unset,
    int? tripId,
    String? name,
    String? category,
    int? quantity,
    bool? isPacked,
    DateTime? createdAt,
  }) => PackingItem(
    id: identical(id, _unset) ? this.id : id as int?,
    tripId: tripId ?? this.tripId,
    name: name ?? this.name,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
    isPacked: isPacked ?? this.isPacked,
    createdAt: createdAt ?? this.createdAt,
  );

  /// UTC ISO-8601 dates and integer booleans for SQLite.
  Map<String, Object?> toMap() => {
    PackingItemColumns.id: id,
    PackingItemColumns.tripId: tripId,
    PackingItemColumns.name: name,
    PackingItemColumns.category: category,
    PackingItemColumns.quantity: quantity,
    PackingItemColumns.isPacked: isPacked ? 1 : 0,
    PackingItemColumns.createdAt: createdAt.toUtc().toIso8601String(),
  };
  factory PackingItem.fromMap(Map<String, Object?> map) => PackingItem(
    id: map[PackingItemColumns.id] as int?,
    tripId: map[PackingItemColumns.tripId] as int,
    name: map[PackingItemColumns.name] as String,
    category: map[PackingItemColumns.category] as String,
    quantity: map[PackingItemColumns.quantity] as int,
    isPacked: map[PackingItemColumns.isPacked] == 1,
    createdAt: DateTime.parse(map[PackingItemColumns.createdAt] as String)
        .toUtc(),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackingItem &&
          id == other.id &&
          tripId == other.tripId &&
          name == other.name &&
          category == other.category &&
          quantity == other.quantity &&
          isPacked == other.isPacked &&
          createdAt.isAtSameMomentAs(other.createdAt);
  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    name,
    category,
    quantity,
    isPacked,
    createdAt.toUtc(),
  );
}
