import 'package:flutter/material.dart';

import '../../shared/widgets/error_state.dart';
import 'app_routes.dart';

/// Recoverable destination for unknown routes and invalid route arguments.
class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({
    super.key,
    this.message = 'Return to your trips to continue.',
  });
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Page not found')),
    body: ErrorState(
      title: 'Page unavailable',
      message: message,
      actionLabel: 'Go home',
      onAction: () =>
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
    ),
  );
}
