import 'package:flutter/material.dart';

import '../../../../shared/widgets/packing_progress.dart';
import '../../domain/trip.dart';
import '../trip_schedule_text.dart';

/// Header summary for a trip's packing list. Counts are item ROWS: a quantity
/// of two still counts as one row, matching PackingListProvider's totals.
class TripSummary extends StatelessWidget {
  const TripSummary({
    super.key,
    required this.trip,
    required this.packedCount,
    required this.totalCount,
    required this.now,
  });
  final Trip trip;
  final int packedCount;
  final int totalCount;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final destination = trip.destination?.trim() ?? '';
    final end = trip.endDate;
    final dates = end == null
        ? localizations.formatMediumDate(trip.startDate.toLocal())
        : '${localizations.formatMediumDate(trip.startDate.toLocal())} - '
              '${localizations.formatMediumDate(end.toLocal())}';
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                trip.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (destination.isNotEmpty) Text(destination),
            Text(dates),
            Text(
              tripScheduleLabel(trip, now),
              key: const ValueKey('trip-schedule-label'),
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Text(
                'Packed $packedCount of $totalCount items',
                key: const ValueKey('trip-packed-count'),
              ),
            ),
            PackingProgress(packedCount: packedCount, totalCount: totalCount),
          ],
        ),
      ),
    );
  }
}
