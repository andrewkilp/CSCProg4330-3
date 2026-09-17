import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:csc4330prog3/app/theme/theme_preferences.dart';
import 'package:csc4330prog3/app/theme/theme_controller.dart';

import 'fake_theme_preferences.dart';

void main() {
  test('preference parsing defaults safely', () {
    expect(ThemePreferences.parse(null), ThemeMode.system);
    expect(ThemePreferences.parse('unknown'), ThemeMode.system);
    for (final mode in ThemeMode.values) {
      expect(ThemePreferences.parse(mode.name), mode);
    }
  });
  test('load notifies only for changed mode', () async {
    final store = FakeThemePreferences();
    final controller = ThemeController(store);
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);
    expect(controller.mode, ThemeMode.system);
    await controller.load();
    expect(notifications, 0);
    store.value = ThemeMode.dark;
    await controller.load();
    expect(notifications, 1);
    await controller.load();
    expect(notifications, 1);
  });
  test('selection applies immediately and wins over pending load', () async {
    final pending = Completer<ThemeMode>();
    final store = FakeThemePreferences()..pending = pending.future;
    final controller = ThemeController(store);
    addTearDown(controller.dispose);
    final load = controller.load();
    final save = controller.setMode(ThemeMode.light);
    expect(controller.mode, ThemeMode.light);
    pending.complete(ThemeMode.dark);
    await load;
    await save;
    expect(controller.mode, ThemeMode.light);
    expect(store.value, ThemeMode.light);
    await Future.wait([
      controller.setMode(ThemeMode.dark),
      controller.setMode(ThemeMode.system),
    ]);
    expect(store.writes, [ThemeMode.light, ThemeMode.dark, ThemeMode.system]);
  });
  test('storage errors are recoverable', () async {
    final store = FakeThemePreferences()..fail = true;
    final controller = ThemeController(store);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.error, isNotNull);
    await controller.setMode(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);
    expect(controller.error, isNotNull);
    store.fail = false;
    await controller.setMode(ThemeMode.dark);
    expect(controller.error, isNull);
  });
  test('late completion after disposal is safe', () async {
    final pending = Completer<ThemeMode>();
    final controller = ThemeController(
      FakeThemePreferences()..pending = pending.future,
    );
    final load = controller.load();
    controller.dispose();
    pending.complete(ThemeMode.dark);
    await load;
  });
}
