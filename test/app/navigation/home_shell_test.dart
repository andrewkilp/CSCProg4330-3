import 'package:csc4330prog3/app/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  testWidgets('shell, retained tabs, settings and route recovery', (
    tester,
  ) async {
    final harness = TestHarness();
    harness.tripRepository.rows = [];
    harness.templateRepository.rows = [];
    await pumpApp(tester, harness: harness);
    expect(find.text('Your trips'), findsOneWidget);
    final trips = tester.element(find.text('Your trips'));
    await tester.tap(find.text('Templates'));
    await tester.pumpAndSettle();
    expect(find.text('Your templates'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();
    expect(tester.element(find.text('Your trips')), same(trips));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    for (final route in [
      AppRoutes.tripForm,
      AppRoutes.tripDetails,
      AppRoutes.itemForm,
      AppRoutes.templatePreview,
      AppRoutes.templateApplication,
    ]) {
      navigator.pushNamed(route);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      navigator.pop();
      await tester.pumpAndSettle();
    }
    navigator.pushNamed('/missing');
    await tester.pumpAndSettle();
    expect(find.text('Page unavailable'), findsOneWidget);
    await tester.tap(find.text('Go home'));
    await tester.pumpAndSettle();
    expect(find.text('Your trips'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
