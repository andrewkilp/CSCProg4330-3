import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/bootstrap/app_dependencies.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../app/navigation/route_arguments.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../trips/domain/trip.dart';
import '../../../trips/presentation/widgets/trip_summary.dart';
import '../../../trips/providers/trip_provider.dart';
import '../../domain/packing_item.dart';
import '../../providers/packing_list_provider.dart';
import '../models/packing_filter.dart';
import '../models/packing_group.dart';
import '../widgets/categorized_item_list.dart';
import '../widgets/clear_packed_dialog.dart';
import '../widgets/packing_filter_bar.dart';
import '../widgets/packing_item_delete_dialog.dart';

/// Packing list for one trip. The route carries a trip ID only; the screen
/// borrows a packing provider for its own lifetime and returns it on dispose.
class PackingListScreen extends StatefulWidget {
  const PackingListScreen({super.key, required this.tripId});
  final int tripId;
  @override
  State<PackingListScreen> createState() => _PackingListScreenState();
}

class _PackingListScreenState extends State<PackingListScreen> {
  late final AppDependencies _dependencies;
  late final PackingListProvider _items;
  final TextEditingController _search = TextEditingController();
  PackingFilter _filter = PackingFilter.cleared;

  @override
  void initState() {
    super.initState();
    _dependencies = context.read<AppDependencies>();
    _items = _dependencies.createPackingProvider(widget.tripId);
    // Only this trip's items are read, and only once the screen opens.
    unawaited(_items.loadItems());
    unawaited(context.read<TripProvider>().loadTrips());
  }

  @override
  void dispose() {
    _dependencies.releasePackingProvider(_items);
    _items.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.select<TripProvider, Trip?>(
      (provider) =>
          provider.trips.where((trip) => trip.id == widget.tripId).firstOrNull,
    );
    final tripsLoading = context.select<TripProvider, bool>(
      (provider) => provider.isInitialLoading,
    );
    return ChangeNotifierProvider<PackingListProvider>.value(
      value: _items,
      child: Scaffold(
        appBar: AppBar(
          title: Text(trip?.name ?? 'Packing list'),
          actions: [if (trip != null) _overflowMenu()],
        ),
        body: trip == null ? _missingTrip(tripsLoading) : _body(context, trip),
        floatingActionButton: trip == null
            ? null
            : FloatingActionButton.extended(
                key: const ValueKey('add-item-button'),
                tooltip: 'Add packing item',
                onPressed: () => _openItemForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
      ),
    );
  }

  Widget _overflowMenu() => Consumer<PackingListProvider>(
    builder: (context, provider, _) => PopupMenuButton<String>(
      key: const ValueKey('packing-list-menu'),
      tooltip: 'Packing list actions',
      onSelected: (value) {
        if (value == 'clear-packed') {
          unawaited(_clearPacked(context, provider.packedCount));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'clear-packed',
          enabled: provider.packedCount > 0,
          child: const Text('Clear packed items'),
        ),
      ],
    ),
  );

  Widget _missingTrip(bool loading) => loading
      ? const Center(child: CircularProgressIndicator())
      : const ErrorState(
          title: 'Trip unavailable',
          message: 'This trip is no longer saved on this device.',
        );

  Widget _body(
    BuildContext context,
    Trip trip,
  ) => Consumer<PackingListProvider>(
    builder: (context, provider, _) {
      final items = provider.items;
      if (provider.isInitialLoading) {
        return const Center(
          key: ValueKey('packing-list-loading'),
          child: CircularProgressIndicator(),
        );
      }
      final error = provider.error;
      if (items.isEmpty && error != null) {
        return ErrorState(
          title: 'Packing list could not be loaded',
          message: error.message,
          actionLabel: 'Retry',
          onAction: () => unawaited(provider.loadItems(force: true)),
        );
      }
      // Filtering and grouping run once per items/filter change, not per row.
      final filtered = applyPackingFilter(items, _filter);
      final groups = groupPackingItems(filtered);
      final now = DateTime.now();
      return CustomScrollView(
        slivers: [
          if (error != null)
            SliverToBoxAdapter(
              child: MaterialBanner(
                key: const ValueKey('packing-list-error-banner'),
                content: Text(error.message),
                actions: [
                  TextButton(
                    onPressed: () => unawaited(provider.loadItems(force: true)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          SliverToBoxAdapter(
            child: TripSummary(
              trip: trip,
              packedCount: provider.packedCount,
              totalCount: provider.totalCount,
              now: now,
            ),
          ),
          if (items.isNotEmpty)
            SliverToBoxAdapter(
              child: PackingFilterBar(
                filter: _filter,
                searchController: _search,
                categories: categoryOptions(items),
                onQueryChanged: (value) =>
                    setState(() => _filter = _filter.copyWith(query: value)),
                onStatusChanged: (value) =>
                    setState(() => _filter = _filter.copyWith(status: value)),
                onCategoryChanged: (value) =>
                    setState(() => _filter = _filter.copyWith(category: value)),
                onClear: () => setState(() {
                  _filter = PackingFilter.cleared;
                  _search.clear();
                }),
              ),
            ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: 'Nothing packed yet',
                message: 'Add your first item to start this packing list.',
                actionLabel: 'Add item',
                onAction: () => _openItemForm(context),
              ),
            )
          else if (filtered.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No items match your search or filters.',
                  key: ValueKey('no-filter-matches'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            CategorizedItemList(
              groups: groups,
              onPackedChanged: (item, value) =>
                  unawaited(_togglePacked(context, item, value)),
              onEdit: (item) => _openItemForm(context, item: item),
              onDelete: (item) => unawaited(_deleteItem(context, item)),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      );
    },
  );

  void _openItemForm(BuildContext context, {PackingItem? item}) => unawaited(
    Navigator.of(context).pushNamed(
      AppRoutes.itemForm,
      arguments: PackingItemFormArguments(
        tripId: widget.tripId,
        item: item,
        knownCategories: [
          for (final option in categoryOptions(_items.items))
            if (option.key != null) option.label,
        ],
      ),
    ),
  );

  Future<void> _togglePacked(
    BuildContext context,
    PackingItem item,
    bool isPacked,
  ) async {
    final id = item.id;
    if (id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      // The provider updates the row first, then persists and rolls back.
      await _items.setPacked(id, isPacked);
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _deleteItem(BuildContext context, PackingItem item) async {
    final id = item.id;
    if (id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!await PackingItemDeleteDialog.confirm(context, item.name)) return;
    try {
      await _items.deleteItem(id);
      messenger.showSnackBar(SnackBar(content: Text('Deleted ${item.name}.')));
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _clearPacked(BuildContext context, int packedCount) async {
    if (packedCount == 0) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!await ClearPackedDialog.confirm(context, packedCount)) return;
    try {
      await _items.deletePackedItems();
      messenger.showSnackBar(
        const SnackBar(content: Text('Cleared packed items.')),
      );
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
