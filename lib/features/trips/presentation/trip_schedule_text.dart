import '../../../core/time/date_calculations.dart';
import '../domain/trip.dart';

/// Countdown wording for a trip, using the shared calendar helpers.
/// The caller supplies an explicit [now] so the result stays deterministic.
String tripScheduleLabel(Trip trip, DateTime now) {
  if (isTripPast(trip.startDate, now, endDate: trip.endDate)) return 'Ended';
  final days = daysUntilTrip(trip.startDate, now);
  if (days > 1) return '$days days away';
  if (days == 1) return '1 day away';
  if (days == 0) return 'Today';
  return 'Started';
}
