import 'package:flutter/material.dart';

import 'navigation/app_routes.dart';
import 'navigation/home_shell.dart';
import 'navigation/feature_placeholder_page.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import '../features/packing/presentation/packing_list_placeholder.dart';
import '../shared/widgets/error_state.dart';

/// The caller owns and disposes the injected controller.
class PackMateApp extends StatelessWidget {
  const PackMateApp({super.key, required this.themeController});
  final ThemeController themeController;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: themeController,
    builder: (context, _) => MaterialApp(
      title: 'PackMate',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.mode,
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => switch (settings.name) {
          AppRoutes.home => HomeShell(themeController: themeController),
          AppRoutes.tripDetails => Scaffold(
            appBar: AppBar(title: const Text('Packing list')),
            body: const PackingListPlaceholder(),
          ),
          AppRoutes.tripForm => const FeaturePlaceholderPage(
            title: 'Trip form',
          ),
          AppRoutes.itemForm => const FeaturePlaceholderPage(
            title: 'Item form',
          ),
          AppRoutes.templatePreview => const FeaturePlaceholderPage(
            title: 'Template preview',
          ),
          AppRoutes.templateApplication => const FeaturePlaceholderPage(
            title: 'Apply template',
          ),
          _ => Scaffold(
            appBar: AppBar(title: const Text('Page not found')),
            body: ErrorState(
              title: 'Page unavailable',
              message: 'Return to your trips to continue.',
              actionLabel: 'Go home',
              onAction: () =>
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
            ),
          ),
        },
      ),
    ),
  );
}
