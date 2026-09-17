/// Compares local calendar dates without time-of-day differences.
int compareDates(DateTime a, DateTime b) => _day(a).compareTo(_day(b));

/// Today counts as upcoming; use the trip start date.
bool isTripUpcoming(DateTime startDate, DateTime now) =>
    compareDates(startDate, now) >= 0;

/// Past means the end date (or start date if absent) precedes today.
bool isTripPast(DateTime startDate, DateTime now, {DateTime? endDate}) =>
    compareDates(endDate ?? startDate, now) < 0;

/// Signed whole calendar days, independent of daylight-saving day lengths.
int daysUntilTrip(DateTime startDate, DateTime now) =>
    _day(startDate).difference(_day(now)).inDays;
DateTime _day(DateTime value) {
  final local = value.toLocal();
  return DateTime.utc(local.year, local.month, local.day);
}
