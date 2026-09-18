import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bootstrap/app_dependencies.dart';
import 'navigation/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import '../features/templates/providers/template_provider.dart';
import '../features/trips/providers/trip_provider.dart';

/// The caller owns and disposes the injected controller and dependencies.
class PackMateApp extends StatelessWidget {
  const PackMateApp({
    super.key,
    required this.themeController,
    required this.dependencies,
  });
  final ThemeController themeController;
  final AppDependencies dependencies;
  @override
  Widget build(BuildContext context) {
    final router = AppRouter(themeController: themeController);
    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: dependencies),
        ChangeNotifierProvider<TripProvider>.value(value: dependencies.trips),
        ChangeNotifierProvider<TemplateProvider>.value(
          value: dependencies.templates,
        ),
      ],
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) => MaterialApp(
          title: 'PackMate',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
          onGenerateRoute: router.onGenerateRoute,
        ),
      ),
    );
  }
}
