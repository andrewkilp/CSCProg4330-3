import 'package:flutter/material.dart';

/// Heading above a group of trip cards on the trip list.
class TripSectionHeader extends StatelessWidget {
  const TripSectionHeader({
    super.key,
    required this.title,
    required this.tripCount,
  });
  final String title;
  final int tripCount;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Semantics(
      header: true,
      child: Text(
        '$title ($tripCount)',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
  );
}
