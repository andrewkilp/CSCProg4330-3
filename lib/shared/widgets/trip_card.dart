import 'package:flutter/material.dart';

import '../../features/trips/domain/trip.dart';
import 'packing_progress.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.onDelete,
    this.packedCount,
    this.totalCount,
  });
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int? packedCount;
  final int? totalCount;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.name, style: Theme.of(context).textTheme.titleLarge),
            if (trip.destination?.trim().isNotEmpty ?? false)
              Text(trip.destination!),
            Text(
              MaterialLocalizations.of(context)
                  .formatMediumDate(trip.startDate.toLocal()),
            ),
            if (packedCount != null && totalCount != null)
              PackingProgress(
                packedCount: packedCount!,
                totalCount: totalCount!,
              ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Delete trip',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    ),
  );
}
