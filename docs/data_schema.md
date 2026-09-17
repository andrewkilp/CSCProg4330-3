# Offline data and application state

## Schema, version 1

All IDs are `INTEGER PRIMARY KEY AUTOINCREMENT`. All columns are required unless
marked nullable. No display dates or derived progress values are persisted.

| Table | Columns besides its ID |
| --- | --- |
| `trips` | `name TEXT`, `destination TEXT` (nullable), `start_date TEXT`, `end_date TEXT` (nullable), `created_at TEXT` |
| `packing_items` | `trip_id INTEGER`, `name TEXT`, `category TEXT`, `quantity INTEGER CHECK(quantity >= 1)`, `is_packed INTEGER DEFAULT 0 CHECK(is_packed IN (0,1))`, `created_at TEXT` |
| `packing_templates` | `name TEXT`, `created_at TEXT` |
| `template_items` | `template_id INTEGER`, `name TEXT`, `category TEXT`, `quantity INTEGER CHECK(quantity >= 1)` |

`packing_items.trip_id` references `trips.id` with `ON DELETE CASCADE`.
`template_items.template_id` references `packing_templates.id` with
`ON DELETE CASCADE`. Foreign keys are enabled in `onConfigure` before any schema
or data access. A parent DELETE and its cascade are one atomic SQLite statement.

Indexes: `packing_items(trip_id)`, `packing_items(trip_id, is_packed)`,
`template_items(template_id)`, and `trips(start_date)`.

Dates use the existing domain models' UTC `toIso8601String()` representation and
are parsed back to UTC. Booleans use integers 0 and 1. Trip ordering is by start
instant, then ID; after the indexed SQL read, an in-memory comparison handles
the model's variable fractional-second precision correctly. Packing items sort
by trimmed, lowercase category, creation instant, then ID. Templates sort by
SQLite NOCASE name then ID; template items sort by ID.

## Database lifecycle and migrations

`AppDatabase` owns one lazy, shared initialization future and database connection.
Inject the same owner into all three repositories. The default path is
`getDatabasesPath()/packmate.db`. Tests inject a `DatabaseFactory` and either an
in-memory path or a disposable temporary file; they never use the app database.
`close()` is terminal for that owner and also waits for pending initialization.
Create a new owner to reopen a file. Failed SQLite opening can be retried.

Schema DDL, migration dispatch, connection opening, and preset seeding live in
separate files. `DatabaseSchema.version` is 1. The migration dispatcher applies
each intermediate version in order; future versions need an explicit switch
case and version increment. sqflite runs creation/upgrade callbacks inside its
transaction. Unsupported versions and downgrades fail instead of erasing data.

Only first creation seeds Weekend Trip, Beach Trip, and Business Trip (eight
items total). Seeding runs in the schema-creation transaction and batches child
inserts. No launch-time name lookup or reseeding occurs. A deleted preset stays
deleted after reopening or restarting the app.

## Repository behavior

The existing domain models/interfaces are unchanged. Create/update trim names,
destination and categories, and use model validation. An empty category is
allowed by the existing model contract. Invalid input raises
`ValidationException`; missing ID-based writes and missing source/target parents
raise `NotFoundException`; low-level SQLite failures become contextual
`StorageException` messages without exposing SQL. `getTripById` returns null for
a missing trip. An item-list query for a missing trip returns an empty list.

Trip duplication reads the source and items and inserts independent copies in
one transaction. New rows receive generated IDs and a fresh creation timestamp;
all copied items are unpacked. Requested dates/name replace the original values;
omitting `newEndDate` clears the end date, as required by the domain contract.

Saving a trip as a template is transactional and **allows an empty trip**.
Applying a template checks both parents and reads/inserts within one transaction.
A duplicate is a pair of **trimmed, lowercase name and category**, using Dart
normalization for both existing and incoming values. The seen set is updated
during application, so duplicates within the template are skipped too. Existing
quantities and packed flags are preserved. New items start unpacked. Child writes
use batches; a batch failure rolls back the complete operation.

## Providers and integration handoff

Providers use constructor-injected repository interfaces:

- `TripProvider(repository)`: `trips`, `loadTrips({force})`, and trip CRUD/duplicate.
- `PackingListProvider(repository, tripId: id)`: one immutable trip binding,
  `items`, `loadItems({force})`, item CRUD, packed toggle and packed deletion.
  `packedCount` and `totalCount` count rows; `completionPercentage` is 0–100 and
  equals zero for an empty list.
- `TemplateProvider(repository, onTripItemsChanged: callback)`: `templates`,
  on-demand `templateItems` cache keyed by ID, `loadingItemIds`, template loads,
  save, apply and delete. The callback is required so integration explicitly
  coordinates affected packing data.

Lists, nested cache values, maps and loading-ID sets are unmodifiable snapshots.
Each provider exposes `isInitialLoading`, `isRefreshing`, `isMutating` and
`AppException? error`. A successfully loaded empty list counts as usable data.
Refreshes preserve the previous snapshot during loading and after failure.
Concurrent identical loads share a future; normal repeated loads use the cache;
`force: true` refreshes it. Operations serialize per provider, preventing an older
read from overwriting a later mutation. Independent providers can load concurrently.
No trip-item or template-item queries run merely from provider construction.

Load methods record typed failures in `error` and complete normally. Mutation
methods record and rethrow write failures, so the caller can decide whether to
close a form. A successful write followed by a failed refresh **still returns
success** and records the refresh error; retry the load, not the write. A new
operation clears an old error. A cached no-op load does not clear an error.

Packed toggles optimistically change the displayed row before their database
write completes, then restore the snapshot on failure. Writes queue in order,
including rapid opposing toggles. Loaded row IDs and the provider's trip binding
guard against accidentally changing another trip's items. Providers ignore late
state updates/notifications after disposal. Do not invoke new operations on a
disposed provider; queued operations that have not started reject with StateError.

`PackingListProvider.reloadAfterTemplate(tripId)` always queues a fresh load,
including when an earlier load is still pending. It ignores other trip IDs and
disposed instances. Reload failures appear on the affected packing provider.
Template deletion removes its item cache. Templates have no item-edit API, so
remaining item caches are valid until explicitly forced to refresh.

### Composition boundary

The merged foundation has **no `lib/app/bootstrap/` registration seam**.
`main.dart` only creates the theme controller. Consequently this contribution
does not modify the entry point, navigation or placeholder screens. Developer 3
(with the app owner) must connect the providers when replacing placeholders.
The existing placeholder app continues to compile but does not yet use SQLite.

The composition owner should construct dependencies in this order:

```dart
final database = AppDatabase();
final tripRepository = SqliteTripRepository(database);
final itemRepository = SqlitePackingItemRepository(database);
final templateRepository = SqlitePackingTemplateRepository(database);
final trips = TripProvider(tripRepository);
final activePacking = <int, PackingListProvider>{};
final templates = TemplateProvider(
  templateRepository,
  onTripItemsChanged: (id) async {
    await activePacking[id]?.reloadAfterTemplate(id);
  },
);
await Future.wait([trips.loadTrips(), templates.loadTemplates()]);
// Create/register a PackingListProvider only when opening a trip detail.
// Load template items only when previewing that template.
```

The map above belongs to the composition owner, not a global service locator.
If multiple views retain separate packing providers for the same trip, notify
all of them. Remove/dispose detail providers when their owning view is released.
The app owner disposes providers and closes the single database at shutdown.
Register dependencies before consumers if using MultiProvider. Loading flags
are local to the provider; ordinary mutations need no full-screen loading UI.

## Validation coverage

The foundation's 29 tests passed before editing. New tests use
`sqflite_common_ffi` (a dev-only SQLite test adapter) and fake repositories.
They cover schema/index creation, shared opening, foreign keys and constraints,
cascades, reopening and deleted presets, repository CRUD and validation,
deterministic ordering, template duplicate suppression, trip-copy independence,
and transaction rollback using deliberately failing insert triggers. Provider
tests cover caching/immutability, delayed operations, loading and mutation state,
retained snapshots, errors/recovery, optimistic rollback, ordered writes,
template coordination and disposal. Production presentation and integration
tests remain Developer 3's responsibility.

Final validation on Windows, 2026-09-16:

| Command | Result |
| --- | --- |
| `dart format .` | PASS: 54 Dart files, zero changes on final run |
| `flutter analyze` | PASS: no issues |
| `flutter test` | PASS: all 61 tests (29 foundation + 32 new) |
| `flutter build apk --debug` | PASS: `build/app/outputs/flutter-apk/app-debug.apk` |
| `git diff --check` | PASS |

Flutter required SDK-cache access outside the workspace sandbox. Its initial
dependency resolution reported the existing Windows symlink-support issue;
rerunning succeeded. The Android build emitted Java native-access and Android
SDK XML-version warnings but succeeded. Incidental generated desktop registrant
changes were restored. No commit was created.
