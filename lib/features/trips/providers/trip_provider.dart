import '../../../core/errors/app_exception.dart';
import '../domain/trip.dart';
import '../domain/trip_repository.dart';
import '../../shared_data/providers/async_provider.dart';

class TripProvider extends AsyncProvider {
  TripProvider(this._repository);
  final TripRepository _repository;
  List<Trip> _trips = const [];
  List<Trip> get trips => _trips;
  Future<void>? _loading;

  Future<void> _refresh() async {
    final trips = await _repository.getAllTrips();
    if (isDisposed) return;
    _trips = List.unmodifiable(trips);
    hasLoaded = true;
  }

  Future<void> loadTrips({bool force = false}) {
    if (_loading != null) return _loading!;
    if (hasLoaded && !force) return Future.value();
    return _loading = operate(
      _refresh,
      loading: true,
    ).onError<AppException>((_, _) {}).whenComplete(() => _loading = null);
  }

  Future<T> _mutate<T>(Future<T> Function() action) => operate(() async {
    final result = await action();
    await refreshAfterWrite(_refresh);
    return result;
  }, mutation: true);

  Future<int> createTrip(Trip trip) =>
      _mutate(() => _repository.createTrip(trip));
  Future<void> updateTrip(Trip trip) =>
      _mutate(() => _repository.updateTrip(trip));
  Future<void> deleteTrip(int tripId) =>
      _mutate(() => _repository.deleteTrip(tripId));
  Future<int> duplicateTrip(
    int tripId, {
    required String newName,
    required DateTime newStartDate,
    DateTime? newEndDate,
  }) => _mutate(
    () => _repository.duplicateTrip(
      tripId,
      newName: newName,
      newStartDate: newStartDate,
      newEndDate: newEndDate,
    ),
  );
}
