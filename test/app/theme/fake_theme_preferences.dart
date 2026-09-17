import 'package:flutter/material.dart';
import 'package:csc4330prog3/app/theme/theme_preferences.dart';

class FakeThemePreferences implements ThemePreferenceStore {
  ThemeMode value = ThemeMode.system;
  Future<ThemeMode>? pending;
  bool fail = false;
  final writes = <ThemeMode>[];
  @override
  Future<ThemeMode> load() async {
    if (fail) throw StateError('read failed');
    return pending ?? Future.value(value);
  }

  @override
  Future<void> save(ThemeMode mode) async {
    if (fail) throw StateError('write failed');
    writes.add(mode);
    value = mode;
  }
}
