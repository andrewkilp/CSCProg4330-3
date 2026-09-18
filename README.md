# PackMate

PackMate is an offline Android packing companion. Create trips, build categorized
packing lists, tick items off as you pack, search and filter a list, reuse saved
templates, and duplicate a trip you take often. Everything is stored locally on
the device; there is no account, no server, and no network use at runtime.

## Setup and commands

Prerequisites: Flutter 3.47.2 / Dart 3.13.2 (validated SDK), Android Studio with
an Android SDK and Java 17-compatible toolchain, and an Android emulator or
device. Put Flutter's `bin` directory on PATH. On Windows, enable Developer Mode
if Flutter reports that plugin symlinks are unavailable.

```sh
flutter --version
flutter doctor -v
flutter pub get
flutter run -d <android-device-id>
dart format .
flutter analyze
flutter test
flutter test integration_test
flutter build apk --debug
```

Use `flutter devices` to find the device ID. The debug APK is written to
`build/app/outputs/flutter-apk/app-debug.apk`. No production signing is
configured. The existing Dart package `csc4330prog3` and Android ID
`com.example.csc4330prog3` are retained; the Android display name is PackMate.

`flutter test integration_test` runs the end-to-end workflow. On a host machine
it uses a temporary SQLite file through the FFI test adapter; on a device or
emulator, run it with `flutter test integration_test -d <android-device-id>`.
Either way the test creates and deletes its own database and never touches the
app's real `packmate.db`.

## Features

- **Trips.** Upcoming and past sections, soonest first and most recent first. A
  trip that is already under way stays under Upcoming until its end date passes.
- **Trip form.** Required name, optional destination, required start date,
  optional end date. An end date cannot precede the start date, the save button
  is disabled while a save is in flight, and leaving with unsaved edits asks
  before discarding.
- **Packing lists.** Items grouped by category, unpacked before packed and then
  alphabetical. Tapping a checkbox updates instantly and rolls back if the write
  fails. Edit, delete, and "Clear packed items" all confirm before destroying
  anything.
- **Item form.** Name, category (with Clothing, Toiletries, Documents,
  Electronics and Other offered, plus categories already used in the trip) and a
  quantity of at least one.
- **Search and filters.** Case-insensitive name search combined with a packed
  status filter and a category filter, plus Clear Filters. Filtering happens in
  memory and is not saved between launches.
- **Trip summary.** Total items, packed count, completion percentage and a
  countdown that reads Today, 1 day away, N days away, Started or Ended.
- **Templates.** Weekend Trip, Beach Trip and Business Trip are seeded once on
  first launch and sit alongside templates you save. Preview a template, apply
  it to a trip, or delete it. Applying skips an item whose name and category
  already match one in that trip and keeps the existing quantity.
- **Duplicate a trip.** Pick a new name and dates; the copied items come across
  unpacked.
- **Theme.** System, Light or Dark, saved locally.

**Item counts are rows, not units.** Two Shirts is one row with a quantity of
two, so a list holding Passport and Shirts reads "Packed 1 of 2 items" once
Passport is ticked.

## Offline and local storage

All trip, item and template data lives in a single SQLite database
(`packmate.db`) created in the app's private storage on first launch. The
database is opened once and shared, foreign keys are on, and deleting a trip
cascades to its items. The chosen theme is stored separately in shared
preferences. Nothing leaves the device and no feature needs connectivity, so
there is no sign-in, sync, or offline-mode banner anywhere in the app.

## Manual demo sequence

This mirrors `integration_test/packmate_workflow_test.dart`.

1. Launch PackMate on a device with no previous install. The Trips tab shows the
   empty state; the Templates tab already lists the three starter templates.
2. Create a trip named **Weekend Away** with today's date.
3. Open it and add **Passport** in *Documents* (quantity 1), then **Shirts** in
   *Clothing* (quantity 2).
4. Tick **Passport**. The summary reads *Packed 1 of 2 items*, 50% packed.
5. Type `sh` in the search box, switch the status filter to *Unpacked*, then tap
   *Clear filters*.
6. Open the overflow menu, choose **Save as template**, and name it
   **Weekend Template**.
7. Go back and create a second trip, **Beach Break**.
8. On the Templates tab, open **Weekend Template**, tap *Apply to a trip*, choose
   **Beach Break**, and confirm.
9. Open Beach Break: Passport and Shirts are there and both are unpacked.
10. Back in Weekend Away, edit **Shirts** to *Linen shirts* and delete
    **Passport**, confirming the deletion.
11. Force-stop and relaunch the app. Both trips, the edited item and the saved
    template are still there. Delete a starter template and relaunch; it stays
    deleted.

## Known limitations

- Android is the target. The iOS, web and desktop folders are untouched
  scaffolding and are not tested.
- No accounts, backend, cloud sync, sharing, export, reminders, maps, payments or
  notifications. A device restore or uninstall loses the data.
- Item deletion is confirmed rather than undoable; there is no trash or undo.
- Search and filters are in-memory and reset on launch, which suits list sizes a
  packing app produces but is not built for thousands of rows per trip.
- Quantities are counted as one row each in progress and summaries.
- Template items cannot be edited after a template is saved; save a new template
  from an updated trip instead.
- There is no sort control on the trip list or packing list; ordering is fixed.
- The debug APK is unsigned and is not suitable for distribution.

## Architecture and team workflow

`app/` owns startup, dependency composition, named routes, navigation and theme.
`core/` holds typed errors and pure calendar calculations. Each feature has
`domain/` contracts, a `data/` SQLite implementation, a `providers/`
ChangeNotifier, and `presentation/` screens and widgets. `shared/widgets/`
receives only data and callbacks. See [architecture](docs/architecture.md) for
ownership and contracts and [data schema](docs/data_schema.md) for the database.

- Developer 1: `feature/packmate-foundation` - navigation, theme, core, domain
  contracts, shared widgets.
- Developer 2: `feature/packmate-data-state` - SQLite, repositories, providers.
- Developer 3: `feature/packmate-user-experience` - screens, forms, validation,
  accessibility, widget tests and the integration test.

## Validation

See the [foundation validation record](docs/validation.md) for the earlier
commands, results and environment limitations.
