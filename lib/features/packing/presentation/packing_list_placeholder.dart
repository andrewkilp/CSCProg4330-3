import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

class PackingListPlaceholder extends StatelessWidget {
  const PackingListPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const EmptyState(
    title: 'Packing list',
    message: 'Categorized packing items will appear here.',
  );
}
