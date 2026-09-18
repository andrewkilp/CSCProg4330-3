import 'dart:io';

import 'package:csc4330prog3/app/bootstrap/app_dependencies.dart';
import 'package:csc4330prog3/app/packmate_app.dart';
import 'package:csc4330prog3/app/theme/theme_controller.dart';
import 'package:csc4330prog3/app/theme/theme_preferences.dart';
import 'package:csc4330prog3/features/shared_data/data/database/app_database.dart';
import 'package:csc4330prog3/shared/widgets/packing_item_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// End-to-end workflow against an isolated database file. Item totals count
/// ROWS: "two Shirts" is one row with quantity two, so the summary reads
/// 1 of 2 items packed, never 1 of 3.
/// Shared end-to-end workflow. `integration_test/packmate_workflow_test.dart`
/// runs it on a device; `test/features/trips/presentation/
/// end_to_end_workflow_test.dart` runs the same steps on the host.
void packMateWorkflowTests() {
  late DatabaseFactory factory;
  late String databasePath;
  Directory? scratch;

  setUpAll(() async {
    if (Platform.isAndroid || Platform.isIOS) {
      factory = databaseFactory;
      databasePath = path.join(
        await getDatabasesPath(),
        'packmate_workflow_test.db',
      );
    } else {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
      scratch = Directory.systemTemp.createTempSync('packmate_workflow');
      databasePath = path.join(scratch!.path, 'packmate_workflow_test.db');
    }
    await factory.deleteDatabase(databasePath);
  });

  tearDownAll(() async {
    await factory.deleteDatabase(databasePath);
    if (scratch != null && scratch!.existsSync()) {
      scratch!.deleteSync(recursive: true);
    }
  });

  testWidgets('full PackMate workflow survives a restart', (tester) async {
    // A tall surface keeps every workflow control built and reachable.
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final theme = ThemeController(ThemePreferences());
    addTearDown(theme.dispose);
    var dependencies = AppDependencies.production(
      database: AppDatabase(factory: factory, databasePath: databasePath),
    );

    Future<void> launch() async {
      await tester.pumpWidget(
        PackMateApp(themeController: theme, dependencies: dependencies),
      );
      await tester.pumpAndSettle();
    }

    // A snack bar overlays the floating action buttons, so let it expire
    // before the next step taps one.
    Future<void> letSnackBarsExpire() =>
        tester.pumpAndSettle(const Duration(seconds: 5));

    Finder rowFor(String name) => find.ancestor(
      of: find.text(name),
      matching: find.byType(PackingItemRow),
    );

    Future<void> createTrip(String name) async {
      await tester.tap(find.byKey(const ValueKey('create-trip-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('trip-name-field')),
        name,
      );
      await tester.tap(find.text('Not set').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('trip-form-save')));
      await tester.pumpAndSettle();
    }

    Future<void> addItem(String name, String category, String quantity) async {
      await tester.tap(find.byKey(const ValueKey('add-item-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('item-name-field')),
        name,
      );
      await tester.enterText(
        find.byKey(const ValueKey('item-category-field')),
        category,
      );
      await tester.enterText(
        find.byKey(const ValueKey('item-quantity-field')),
        quantity,
      );
      await tester.tap(find.byKey(const ValueKey('item-form-save')));
      await tester.pumpAndSettle();
    }

    // 1. Launch PackMate on a fresh database.
    await launch();
    expect(find.text('Your trips'), findsOneWidget);

    // 2. Create a trip named Weekend Away.
    await createTrip('Weekend Away');
    expect(find.text('Weekend Away'), findsOneWidget);

    // 3. Add Passport in Documents and two Shirts in Clothing.
    await tester.tap(find.text('Weekend Away'));
    await tester.pumpAndSettle();
    await addItem('Passport', 'Documents', '1');
    expect(find.text('Documents (1)'), findsOneWidget);
    await addItem('Shirts', 'Clothing', '2');
    expect(find.text('Clothing (1)'), findsOneWidget);
    expect(find.text('Quantity: 2'), findsOneWidget);

    // 4. Mark Passport packed.
    await tester.tap(
      find.descendant(of: rowFor('Passport'), matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();

    // 5. The summary counts rows, not quantities.
    expect(find.text('Packed 1 of 2 items'), findsOneWidget);
    expect(find.text('50% packed'), findsOneWidget);

    // 6. Save the list as Weekend Template.
    await tester.tap(find.byKey(const ValueKey('packing-list-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save as template'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('save-template-name')),
      'Weekend Template',
    );
    await tester.tap(find.byKey(const ValueKey('save-template-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Saved Weekend Template as a template.'), findsOneWidget);
    await letSnackBarsExpire();

    // 7. Create a second trip.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await createTrip('Beach Break');
    expect(find.text('Beach Break'), findsOneWidget);

    // 8. Apply Weekend Template to it.
    await tester.tap(find.text('Templates'));
    await tester.pumpAndSettle();
    expect(find.text('Weekend Trip'), findsOneWidget);
    await tester.tap(find.text('Weekend Template'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('apply-template-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beach Break'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('apply-template-confirm')));
    await tester.pumpAndSettle();
    expect(
      find.text('Applied Weekend Template to Beach Break.'),
      findsOneWidget,
    );
    await letSnackBarsExpire();

    // 9. The copied items exist on the second trip and begin unpacked.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beach Break'));
    await tester.pumpAndSettle();
    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('Shirts'), findsOneWidget);
    expect(find.text('Packed 0 of 2 items'), findsOneWidget);

    // 10. Edit Shirts and delete Passport on the first trip.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekend Away'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: rowFor('Shirts'),
        matching: find.byTooltip('Edit item'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('item-name-field')),
      'Linen shirts',
    );
    await tester.tap(find.byKey(const ValueKey('item-form-save')));
    await tester.pumpAndSettle();
    expect(find.text('Linen shirts'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: rowFor('Passport'),
        matching: find.byTooltip('Delete item'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-delete-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Passport'), findsNothing);
    expect(find.text('Packed 0 of 1 items'), findsOneWidget);
    await letSnackBarsExpire();

    // 11. Recreate the app against the same file and verify persistence.
    // Unmounting first makes this a real restart: every screen disposes and
    // every provider is built again, exactly as a cold launch would.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await dependencies.dispose();
    dependencies = AppDependencies.production(
      database: AppDatabase(factory: factory, databasePath: databasePath),
    );
    addTearDown(dependencies.dispose);
    await launch();
    expect(find.text('Weekend Away'), findsOneWidget);
    expect(find.text('Beach Break'), findsOneWidget);
    await tester.tap(find.text('Weekend Away'));
    await tester.pumpAndSettle();
    expect(find.text('Linen shirts'), findsOneWidget);
    expect(find.text('Passport'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Templates'));
    await tester.pumpAndSettle();
    expect(find.text('Weekend Template'), findsOneWidget);
  });
}
