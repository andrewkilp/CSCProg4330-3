import 'dart:async';

import 'package:flutter/material.dart';

import 'app/packmate_app.dart';
import 'app/theme/theme_controller.dart';
import 'app/theme/theme_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = ThemeController(ThemePreferences());
  runApp(PackMateApp(themeController: theme));
  unawaited(theme.load());
}
