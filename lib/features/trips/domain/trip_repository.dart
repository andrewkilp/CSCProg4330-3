import 'trip.dart';

/// Failures must throw typed AppException subclasses, never be swallowed.
/// Create/update validate input; updates require a persisted non-null ID.
abstract interface class TripRepository {
  Future<List<Trip>> getAllTrips();
  Future<Trip?> getTripById(int id);
  Future<int> createTrip(Trip trip);
  Future<void> updateTrip(Trip trip);

  /// Atomically deletes the trip and all its items.
  Future<void> deleteTrip(int tripId);

  /// Atomically creates independent item rows and resets isPacked to false.
  /// A null newEndDate means the duplicate has no end date.
  Future<int> duplicateTrip(
    int tripId, {
    required String newName,
    required DateTime newStartDate,
    DateTime? newEndDate,
  });
}
