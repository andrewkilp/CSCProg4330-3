import 'package:flutter/material.dart';

import '../../features/trips/domain/trip.dart';
import 'packing_progress.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.packedCount,
    this.totalCount,
    this.scheduleLabel,
  });
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final int? packedCount;
  final int? totalCount;

  /// Optional caller-computed countdown text; the card performs no date math.
  final String? scheduleLabel;
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
            if (scheduleLabel != null) Text(scheduleLabel!),
            if (packedCount != null && totalCount != null)
              PackingProgress(
                packedCount: packedCount!,
                totalCount: totalCount!,
              ),
            if (onEdit != null || onDuplicate != null || onDelete != null)
              Wrap(
                children: [
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'Edit trip',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  if (onDuplicate != null)
                    IconButton(
                      tooltip: 'Duplicate trip',
                      onPressed: onDuplicate,
                      icon: const Icon(Icons.copy_outlined),
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Delete trip',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}
