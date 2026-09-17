import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

class TripListPlaceholder extends StatelessWidget {
  const TripListPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const EmptyState(
    title: 'Your trips',
    message: 'Your trips and packing progress will appear here.',
  );
}
