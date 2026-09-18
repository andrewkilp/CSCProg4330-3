import '../../../../core/time/date_calculations.dart';

/// Field-level rules for the trip form. These mirror Trip.validate so the user
/// sees an inline message before a write is attempted.
abstract final class TripFormValidator {
  static String? name(String? value) =>
      (value ?? '').trim().isEmpty ? 'Enter a trip name.' : null;

  static String? startDate(DateTime? value) =>
      value == null ? 'Choose a start date.' : null;

  /// An end date is optional, but it may not fall before the start date.
  static String? endDate(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return null;
    return compareDates(endDate, startDate) < 0
        ? 'End date cannot be before the start date.'
        : null;
  }
}
