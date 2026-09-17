import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:csc4330prog3/shared/widgets/trip_card.dart';
import 'package:csc4330prog3/shared/widgets/packing_item_row.dart';
import 'package:csc4330prog3/shared/widgets/category_heading.dart';
import 'package:csc4330prog3/shared/widgets/packing_progress.dart';
import 'package:csc4330prog3/shared/widgets/empty_state.dart';
import 'package:csc4330prog3/shared/widgets/error_state.dart';
import 'package:csc4330prog3/features/trips/domain/trip.dart';
import 'package:csc4330prog3/features/packing/domain/packing_item.dart';

Widget host(Widget child) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(textScaler: TextScaler.linear(2)),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);
void main() {
  final date = DateTime.utc(2026, 9, 16);
  testWidgets('progress handles zero and announces counts', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      host(const PackingProgress(packedCount: 0, totalCount: 0)),
    );
    expect(find.text('0% packed'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0,
    );
    await tester.pumpWidget(
      host(const PackingProgress(packedCount: 3, totalCount: 5)),
    );
    expect(find.text('60% packed'), findsOneWidget);
    expect(find.bySemanticsLabel('3 of 5 items packed.'), findsOneWidget);
    semantics.dispose();
  });
  testWidgets('trip optional data and callbacks', (tester) async {
    var tapped = 0;
    var deleted = 0;
    final trip = Trip(name: 'Weekend', startDate: date, createdAt: date);
    await tester.pumpWidget(
      host(
        TripCard(trip: trip, onTap: () => tapped++, onDelete: () => deleted++),
      ),
    );
    expect(find.byType(PackingProgress), findsNothing);
    await tester.tap(find.text('Weekend'));
    expect(tapped, 1);
    await tester.tap(find.byTooltip('Delete trip'));
    expect(deleted, 1);
    expect(tapped, 1);
    await tester.pumpWidget(
      host(
        TripCard(
          trip: trip.copyWith(destination: 'Park'),
          onTap: () {},
          packedCount: 1,
          totalCount: 2,
        ),
      ),
    );
    expect(find.text('Park'), findsOneWidget);
    expect(find.text('50% packed'), findsOneWidget);
  });
  for (final packed in [false, true]) {
    testWidgets('item packed=$packed and callbacks', (tester) async {
      bool? changed;
      var edits = 0;
      var deletes = 0;
      final item = PackingItem(
        tripId: 1,
        name: 'Socks',
        category: 'Clothes',
        quantity: packed ? 2 : 1,
        isPacked: packed,
        createdAt: date,
      );
      await tester.pumpWidget(
        host(
          PackingItemRow(
            item: item,
            onPackedChanged: (v) => changed = v,
            onEdit: () => edits++,
            onDelete: () => deletes++,
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Socks')).style?.decoration,
        packed ? TextDecoration.lineThrough : null,
      );
      expect(find.text('Quantity: 2'), packed ? findsOneWidget : findsNothing);
      await tester.tap(find.byType(Checkbox));
      expect(changed, !packed);
      await tester.tap(find.byTooltip('Edit item'));
      await tester.tap(find.byTooltip('Delete item'));
      expect(edits, 1);
      expect(deletes, 1);
    });
  }
  testWidgets('empty/error actions and category count', (tester) async {
    var actions = 0;
    await tester.pumpWidget(
      host(
        Column(
          children: [
            const CategoryHeading(category: 'Clothes', itemCount: 0),
            const EmptyState(title: 'Empty', message: 'Add items'),
            ErrorState(
              title: 'Error',
              message: 'Try again',
              actionLabel: 'Retry',
              onAction: () => actions++,
            ),
          ],
        ),
      ),
    );
    expect(find.text('Clothes (0)'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    expect(actions, 1);
  });
  testWidgets('long text fits narrow layout at 200 percent', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final long = List.filled(12, 'Long packing description').join(' ');
    final widgets = <Widget>[
      TripCard(
        trip: Trip(
          name: long,
          destination: long,
          startDate: date,
          createdAt: date,
        ),
        onTap: () {},
        packedCount: 0,
        totalCount: 0,
      ),
      PackingItemRow(
        item: PackingItem(
          tripId: 1,
          name: long,
          category: long,
          quantity: 3,
          isPacked: true,
          createdAt: date,
        ),
        onPackedChanged: (_) {},
        onEdit: () {},
        onDelete: () {},
      ),
      CategoryHeading(category: long, itemCount: 12),
      EmptyState(
        title: long,
        message: long,
        actionLabel: long,
        onAction: () {},
      ),
      ErrorState(
        title: long,
        message: long,
        actionLabel: long,
        onAction: () {},
      ),
    ];
    for (final widget in widgets) {
      await tester.pumpWidget(host(widget));
      expect(tester.takeException(), isNull);
    }
  });
}
