import '../domain/trip.dart';
import '../domain/trip_repository.dart';
import '../../shared_data/data/database/app_database.dart';
import '../../shared_data/data/repository_support.dart';

class SqliteTripRepository implements TripRepository {
  SqliteTripRepository(this._database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final AppDatabase _database;
  final DateTime Function() _now;

  Trip _clean(Trip trip) {
    final clean = trip.copyWith(
      name: trip.name.trim(),
      destination: trip.destination?.trim(),
    );
    clean.validate();
    return clean;
  }

  @override
  Future<List<Trip>> getAllTrips() =>
      withStorageContext('Could not load trips.', () async {
        final db = await _database.database;
        final trips = (await db.query(
          'trips',
          orderBy: 'start_date ASC, id ASC',
        )).map(Trip.fromMap).toList();
        // ISO strings can contain either three or six fractional digits.
        // Compare instants to preserve microsecond ordering across both forms.
        trips.sort((a, b) {
          final date = a.startDate.compareTo(b.startDate);
          return date != 0 ? date : a.id!.compareTo(b.id!);
        });
        return trips;
      });

  @override
  Future<Trip?> getTripById(int id) =>
      withStorageContext('Could not load the trip.', () async {
        final db = await _database.database;
        final rows = await db.query('trips', where: 'id = ?', whereArgs: [id]);
        return rows.isEmpty ? null : Trip.fromMap(rows.single);
      });

  @override
  Future<int> createTrip(Trip trip) =>
      withStorageContext('Could not create the trip.', () async {
        final values = _clean(trip).copyWith(id: null).toMap();
        return (await _database.database).insert('trips', values);
      });

  @override
  Future<void> updateTrip(Trip trip) =>
      withStorageContext('Could not update the trip.', () async {
        final id = persistedId(trip.id);
        final values = _clean(trip).toMap();
        final db = await _database.database;
        requireChanged(
          await db.update('trips', values, where: 'id = ?', whereArgs: [id]),
          'Trip',
        );
      });

  @override
  Future<void> deleteTrip(int tripId) =>
      withStorageContext('Could not delete the trip.', () async {
        final db = await _database.database;
        requireChanged(
          await db.delete('trips', where: 'id = ?', whereArgs: [tripId]),
          'Trip',
        );
      });

  @override
  Future<int> duplicateTrip(
    int tripId, {
    required String newName,
    required DateTime newStartDate,
    DateTime? newEndDate,
  }) => withStorageContext('Could not duplicate the trip.', () async {
    final db = await _database.database;
    return db.transaction((txn) async {
      final source = Trip.fromMap(
        await requireRow(txn, 'trips', tripId, 'Trip'),
      );
      final now = _now();
      final copy = _clean(
        source.copyWith(
          id: null,
          name: newName,
          startDate: newStartDate,
          endDate: newEndDate,
          createdAt: now,
        ),
      );
      final items = await txn.query(
        'packing_items',
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'id',
      );
      final id = await txn.insert('trips', copy.toMap());
      final batch = txn.batch();
      for (final item in items) {
        batch.insert('packing_items', {
          ...item,
          'id': null,
          'trip_id': id,
          'is_packed': 0,
          'created_at': now.toUtc().toIso8601String(),
        });
      }
      await batch.commit(noResult: true);
      return id;
    });
  });
}
