import '../../../core/time/date_calculations.dart';
import '../domain/trip.dart';

/// Pure presentation split of the provider's trip snapshot.
class TripSections {
  const TripSections({required this.upcoming, required this.past});
  final List<Trip> upcoming;
  final List<Trip> past;
  bool get isEmpty => upcoming.isEmpty && past.isEmpty;
}

/// A trip is past once its end date, or its start date when it has no end,
/// falls before today. Everything else - including a trip already in progress -
/// stays under Upcoming so an ongoing trip never disappears from the list.
/// Upcoming is soonest first; past is most recent first. The caller captures
/// [now] once, outside item builders, so every row uses the same instant.
TripSections splitTrips(List<Trip> trips, DateTime now) {
  final upcoming = <Trip>[];
  final past = <Trip>[];
  for (final trip in trips) {
    if (isTripPast(trip.startDate, now, endDate: trip.endDate)) {
      past.add(trip);
    } else {
      upcoming.add(trip);
    }
  }
  upcoming.sort(_bySoonestStart);
  past.sort((a, b) => _bySoonestStart(b, a));
  return TripSections(upcoming: upcoming, past: past);
}

int _bySoonestStart(Trip a, Trip b) {
  final byDate = compareDates(a.startDate, b.startDate);
  return byDate != 0 ? byDate : (a.id ?? 0).compareTo(b.id ?? 0);
}
