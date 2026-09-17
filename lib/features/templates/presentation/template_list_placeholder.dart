import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

class TemplateListPlaceholder extends StatelessWidget {
  const TemplateListPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const EmptyState(
    title: 'Your templates',
    message: 'Reusable packing lists will appear here.',
  );
}
