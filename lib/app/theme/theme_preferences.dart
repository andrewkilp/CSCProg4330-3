import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injectable persistence boundary; tests need no platform channels.
abstract interface class ThemePreferenceStore {
  Future<ThemeMode> load();
  Future<void> save(ThemeMode mode);
}

class ThemePreferences implements ThemePreferenceStore {
  static const key = 'theme_mode';
  static ThemeMode parse(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  @override
  Future<ThemeMode> load() async =>
      parse((await SharedPreferences.getInstance()).getString(key));
  @override
  Future<void> save(ThemeMode mode) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      key,
      mode.name,
    )) {
      throw StateError('Theme preference was not saved.');
    }
  }
}
