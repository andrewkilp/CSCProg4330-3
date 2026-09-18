import 'dart:async';

import 'package:flutter/material.dart';

import 'app/bootstrap/app_dependencies.dart';
import 'app/packmate_app.dart';
import 'app/theme/theme_controller.dart';
import 'app/theme/theme_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = ThemeController(ThemePreferences());
  final dependencies = AppDependencies.production();
  // The shell renders immediately; stored theme, trips and template names all
  // load concurrently afterwards. No splash screen or artificial delay.
  runApp(PackMateApp(themeController: theme, dependencies: dependencies));
  unawaited(theme.load());
  unawaited(dependencies.warmUp());
}
