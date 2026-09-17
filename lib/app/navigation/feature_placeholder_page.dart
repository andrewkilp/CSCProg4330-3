import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const EmptyState(
      title: 'Coming next',
      message: 'This feature is planned for a later team commit.',
    ),
  );
}
