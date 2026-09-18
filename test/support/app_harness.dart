import 'package:csc4330prog3/app/bootstrap/app_dependencies.dart';
import 'package:csc4330prog3/app/packmate_app.dart';
import 'package:csc4330prog3/app/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/theme/fake_theme_preferences.dart';
import '../features/shared_data/providers/fake_repositories.dart';

/// Test-only composition: the real providers and app, fake repositories.
/// No production fake repository ships with the app.
class TestHarness {
  TestHarness({
    FakeTripRepository? trips,
    FakePackingRepository? items,
    FakeTemplateRepository? templates,
  }) : tripRepository = trips ?? FakeTripRepository(),
       itemRepository = items ?? FakePackingRepository(),
       templateRepository = templates ?? FakeTemplateRepository() {
    dependencies = AppDependencies(
      tripRepository: tripRepository,
      itemRepository: itemRepository,
      templateRepository: templateRepository,
    );
    themeController = ThemeController(FakeThemePreferences());
  }

  final FakeTripRepository tripRepository;
  final FakePackingRepository itemRepository;
  final FakeTemplateRepository templateRepository;
  late final AppDependencies dependencies;
  late final ThemeController themeController;

  Future<void> dispose() async {
    themeController.dispose();
    await dependencies.dispose();
  }
}

/// Pumps the real app so navigation, routes and providers are exercised.
Future<TestHarness> pumpApp(
  WidgetTester tester, {
  TestHarness? harness,
  bool settle = true,
  Size surfaceSize = const Size(800, 1600),
}) async {
  final active = harness ?? TestHarness();
  addTearDown(active.dispose);
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    PackMateApp(
      themeController: active.themeController,
      dependencies: active.dependencies,
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return active;
}
