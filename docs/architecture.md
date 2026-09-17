# Architecture and handoff

## Production files

```text
lib/app/navigation/app_routes.dart
lib/app/navigation/feature_placeholder_page.dart
lib/app/navigation/home_shell.dart
lib/app/packmate_app.dart
lib/app/theme/app_theme.dart
lib/app/theme/theme_controller.dart
lib/app/theme/theme_preferences.dart
lib/core/errors/app_exception.dart
lib/core/time/date_calculations.dart
lib/features/packing/domain/packing_item.dart
lib/features/packing/domain/packing_item_repository.dart
lib/features/packing/presentation/packing_list_placeholder.dart
lib/features/settings/presentation/settings_screen.dart
lib/features/templates/domain/packing_template.dart
lib/features/templates/domain/packing_template_repository.dart
lib/features/templates/domain/template_item.dart
lib/features/templates/presentation/template_list_placeholder.dart
lib/features/trips/domain/trip.dart
lib/features/trips/domain/trip_repository.dart
lib/features/trips/presentation/trip_list_placeholder.dart
lib/main.dart
lib/shared/widgets/category_heading.dart
lib/shared/widgets/empty_state.dart
lib/shared/widgets/error_state.dart
lib/shared/widgets/packing_item_row.dart
lib/shared/widgets/packing_progress.dart
lib/shared/widgets/trip_card.dart
```

Tests mirror `app/`, `core/`, `features/*/domain/`, and `shared/widgets/`. Future data and provider directories are deliberately absent until Developer 2 implements them.

## Dependency direction

Runtime flow: presentation -> providers -> repository interfaces -> repository implementations -> SQLite.

Compile-time dependency inversion: repository implementations implement and import domain interfaces; domain interfaces never import data implementations. The app composition root will inject implementations into providers. Data code must never import presentation code. Widgets must never execute SQL. Shared widgets have no Provider, navigation, or repository lookup.

## Ownership

| Developer | Files and responsibility |
| --- | --- |
| 1 | app/navigation, app/theme (including ThemeController), core, domain models/interfaces, shared widgets, foundation tests/docs |
| 2 | All future data files, schema/migrations, SQLite repository implementations, feature ChangeNotifier providers and associated tests |
| 3 | Production feature screens/forms, placeholder replacements, end-to-end integration test; coordinate Settings and route changes with Developer 1 |

## Domain and persistence contracts

Models are immutable and compare by value; dates compare by instant. Date columns use UTC ISO-8601 strings; display and calendar calculations explicitly convert to local time. Column constants live beside each model. SQLite booleans are 0/1. Explicit null in copyWith clears nullable fields; omitted fields are preserved. Constructors/fromMap tolerate legacy invalid input; call validate at form and repository write boundaries. Names must be nonblank, quantities at least one, and a trip end cannot precede its start. Updates require persisted IDs. New database IDs are returned from create operations.

Repository failures must be typed AppException subclasses: validation, storage, or not-found. Missing getTripById returns null; failed ID-based writes should report NotFoundException. Never silently swallow database failures or expose raw SQL/stack traces in UI. Multi-row operations must be transactional. Deleting parents removes owned items. Trip duplication creates independent rows with all packed flags reset. Applying a template skips matches on both trimmed, case-insensitive name and category, including duplicates introduced earlier in the same application. New template-derived items start unpacked.

## Navigation and state

PackMateApp owns MaterialApp, theme listening, and named-route generation. HomeShell retains its three destination widgets in an IndexedStack. Settings listens locally for selection/error updates even when two theme modes resolve to the same brightness. No feature screen performs database work. Standard Navigator routes preserve Android back behavior. Unknown routes offer a Go home action.

Route constants are in app_routes.dart. Feature routes currently require no arguments and open explicit placeholders; Developer 3 should add typed argument contracts with Developer 2 when persisted IDs are connected. Do not invent unused argument classes now.

The caller owns ThemeController. It starts in system mode, applies stored preferences asynchronously, ignores a stale load after a user choice, serializes writes, and handles completion after disposal. Theme persistence is separate from future SQLite feature persistence.

## Calendar semantics

Today counts as upcoming. Past uses endDate when present, otherwise startDate. An ongoing multi-day trip can be neither upcoming nor past. Whole days use local calendar components projected onto UTC midnights to avoid daylight-saving duration errors. Pure functions require an explicit now.
