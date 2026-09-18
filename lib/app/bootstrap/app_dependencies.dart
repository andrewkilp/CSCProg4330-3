import '../../features/packing/data/sqlite_packing_item_repository.dart';
import '../../features/packing/domain/packing_item_repository.dart';
import '../../features/packing/providers/packing_list_provider.dart';
import '../../features/shared_data/data/database/app_database.dart';
import '../../features/templates/data/sqlite_packing_template_repository.dart';
import '../../features/templates/domain/packing_template_repository.dart';
import '../../features/templates/providers/template_provider.dart';
import '../../features/trips/data/sqlite_trip_repository.dart';
import '../../features/trips/domain/trip_repository.dart';
import '../../features/trips/providers/trip_provider.dart';

/// Composition root described in docs/data_schema.md: one database owner, three
/// repositories, one trip/template provider, and one packing provider per open
/// detail view. Presentation reads these; it never builds repositories itself.
class AppDependencies {
  AppDependencies({
    required TripRepository tripRepository,
    required PackingTemplateRepository templateRepository,
    required this.itemRepository,
    this.database,
  }) : trips = TripProvider(tripRepository) {
    templates = TemplateProvider(
      templateRepository,
      onTripItemsChanged: _reloadOpenPackingViews,
    );
  }

  /// Real SQLite wiring in dependency order.
  factory AppDependencies.production({AppDatabase? database}) {
    final owner = database ?? AppDatabase();
    return AppDependencies(
      database: owner,
      tripRepository: SqliteTripRepository(owner),
      itemRepository: SqlitePackingItemRepository(owner),
      templateRepository: SqlitePackingTemplateRepository(owner),
    );
  }

  /// Null in tests that inject fake repositories instead of SQLite.
  final AppDatabase? database;

  /// Injected once and reused by every borrowed packing provider.
  final PackingItemRepository itemRepository;
  final TripProvider trips;
  late final TemplateProvider templates;
  final Map<int, Set<PackingListProvider>> _openPackingViews = {};

  /// Trip and template lists are independent, so the shell starts both at once.
  /// Item and template-item reads stay deferred until a detail view asks.
  Future<void> warmUp() =>
      Future.wait([trips.loadTrips(), templates.loadTemplates()]);

  PackingListProvider createPackingProvider(int tripId) {
    final provider = PackingListProvider(itemRepository, tripId: tripId);
    _openPackingViews
        .putIfAbsent(tripId, () => <PackingListProvider>{})
        .add(provider);
    return provider;
  }

  /// The packing provider a currently open detail view already owns for this
  /// trip, so a pushed form mutates the same state the list is showing.
  PackingListProvider? openPackingProviderFor(int tripId) =>
      _openPackingViews[tripId]?.firstOrNull;

  /// Call from the owning view's dispose before disposing the provider.
  void releasePackingProvider(PackingListProvider provider) {
    final open = _openPackingViews[provider.tripId];
    if (open == null) return;
    open.remove(provider);
    if (open.isEmpty) _openPackingViews.remove(provider.tripId);
  }

  Future<void> _reloadOpenPackingViews(int tripId) async {
    final open = _openPackingViews[tripId];
    if (open == null || open.isEmpty) return;
    await Future.wait([
      for (final provider in open.toList())
        provider.reloadAfterTemplate(tripId),
    ]);
  }

  /// Disposes the providers this object owns and closes the database. Borrowed
  /// packing providers belong to their views, which dispose them on release.
  Future<void> dispose() async {
    trips.dispose();
    templates.dispose();
    _openPackingViews.clear();
    await database?.close();
  }
}
