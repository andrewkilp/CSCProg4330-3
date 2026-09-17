import '../../../core/errors/app_exception.dart';

const _unset = Object();

/// SQLite column contract.
abstract final class TripColumns {
  static const id = 'id';
  static const name = 'name';
  static const destination = 'destination';
  static const startDate = 'start_date';
  static const endDate = 'end_date';
  static const createdAt = 'created_at';
}

/// Immutable domain value; hydration does not validate user input.
class Trip {
  const Trip({
    this.id,
    required this.name,
    this.destination,
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });
  final int? id;
  final String name;
  final String? destination;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  /// Call at input/repository write boundaries before saving.
  void validate() {
    if (name.trim().isEmpty) {
      throw const ValidationException('Name is required.');
    }
    if (endDate != null && endDate!.isBefore(startDate)) {
      throw const ValidationException('End date cannot precede start date.');
    }
  }

  /// Omitted nullable fields are retained; explicit null clears them.
  Trip copyWith({
    Object? id = _unset,
    String? name,
    Object? destination = _unset,
    DateTime? startDate,
    Object? endDate = _unset,
    DateTime? createdAt,
  }) => Trip(
    id: identical(id, _unset) ? this.id : id as int?,
    name: name ?? this.name,
    destination: identical(destination, _unset)
        ? this.destination
        : destination as String?,
    startDate: startDate ?? this.startDate,
    endDate: identical(endDate, _unset) ? this.endDate : endDate as DateTime?,
    createdAt: createdAt ?? this.createdAt,
  );

  /// UTC ISO-8601 dates and integer booleans for SQLite.
  Map<String, Object?> toMap() => {
    TripColumns.id: id,
    TripColumns.name: name,
    TripColumns.destination: destination,
    TripColumns.startDate: startDate.toUtc().toIso8601String(),
    TripColumns.endDate: endDate?.toUtc().toIso8601String(),
    TripColumns.createdAt: createdAt.toUtc().toIso8601String(),
  };
  factory Trip.fromMap(Map<String, Object?> map) => Trip(
    id: map[TripColumns.id] as int?,
    name: map[TripColumns.name] as String,
    destination: map[TripColumns.destination] as String?,
    startDate: DateTime.parse(map[TripColumns.startDate] as String).toUtc(),
    endDate: map[TripColumns.endDate] == null
        ? null
        : DateTime.parse(map[TripColumns.endDate] as String).toUtc(),
    createdAt: DateTime.parse(map[TripColumns.createdAt] as String).toUtc(),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip &&
          id == other.id &&
          name == other.name &&
          destination == other.destination &&
          startDate.isAtSameMomentAs(other.startDate) &&
          (endDate == null
              ? other.endDate == null
              : other.endDate != null &&
                    endDate!.isAtSameMomentAs(other.endDate!)) &&
          createdAt.isAtSameMomentAs(other.createdAt);
  @override
  int get hashCode => Object.hash(
    id,
    name,
    destination,
    startDate.toUtc(),
    endDate?.toUtc(),
    createdAt.toUtc(),
  );
}
