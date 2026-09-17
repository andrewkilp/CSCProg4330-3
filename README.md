# PackMate

PackMate is an offline Android packing companion for planning trips, organizing categorized packing lists, marking items packed, and eventually reusing templates, searching/filtering items, and tracking progress. This foundation provides navigation, immutable domain models, persistence contracts, shared UI, and a working saved theme setting. Feature destinations intentionally remain placeholders.

## Setup and commands

Prerequisites: Flutter 3.47.2 / Dart 3.13.2 (validated SDK), Android Studio with an Android SDK and Java 17-compatible toolchain, and an Android emulator or device. Put Flutter's `bin` directory on PATH. On Windows, enable Developer Mode if Flutter reports that plugin symlinks are unavailable.

```sh
flutter --version
flutter doctor -v
flutter pub get
flutter run -d <android-device-id>
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

Use `flutter devices` to find the device ID. The debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`. No production signing is configured. The existing Dart package `csc4330prog3` and Android ID `com.example.csc4330prog3` are retained; the Android display name is PackMate. Existing non-Android scaffolding is preserved, but Android is the target.

## Architecture

`app/` owns startup, named routes, navigation, and theme dependencies. `core/` holds typed errors and pure calendar calculations. Feature `domain/` folders contain immutable values, SQLite map contracts, and asynchronous repository interfaces. Future `data/` implementations will own SQLite; future providers will orchestrate repositories and expose feature state. Feature presentation owns screens, while `shared/widgets/` receives only data and callbacks. See [architecture](docs/architecture.md) for ownership and contracts.

The first frame uses the system theme and renders the shell immediately; preferences load asynchronously. System, Light, and Dark apply immediately and persist locally. Save failures are shown in Settings and can be retried by selecting the desired mode again.

## Team workflow

- Developer 1: `feature/packmate-foundation`; merge this foundation first. Owns app/navigation, theme, core, domain contracts, shared widgets, and their tests. ThemeController is the explicit exception to Developer 2's ChangeNotifier ownership.
- Developer 2: suggested branch `feature/packmate-data`; owns all future data/schema/migrations, repository implementations, and feature ChangeNotifier providers, plus their tests.
- Developer 3: suggested branch `feature/packmate-features`; owns production feature screens/forms, replacing the explicit placeholders, and the end-to-end integration test. Coordinate changes to the foundation Settings screen and route wiring.

Each developer rebases or merges the foundation before feature work, keeps commits focused, and runs analysis/tests before merging. No SQLite implementation, feature provider, CRUD form, template workflow, or integration test belongs in this commit.

Recommended foundation commit:

```text
feat: scaffold PackMate architecture and shared UI
```

## Scope

No accounts, backend, cloud sync, maps, payments, ads, social features, or runtime network services. Provider, sqflite, path, and shared_preferences are resolved through Flutter tooling for later work; only shared_preferences is used for persistence in this commit.

## Validation

See [validation record](docs/validation.md) for commands, results, and environment limitations.
