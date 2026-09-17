import '../../../core/errors/app_exception.dart';
import '../domain/packing_item.dart';
import '../domain/packing_item_repository.dart';
import '../../shared_data/providers/async_provider.dart';

/// One instance per trip detail lifetime; never reuse it for another trip ID.
class PackingListProvider extends AsyncProvider {
  PackingListProvider(this._repository, {required this.tripId});
  final PackingItemRepository _repository;
  final int tripId;
  List<PackingItem> _items = const [];
  List<PackingItem> get items => _items;
  int get totalCount => _items.length;
  int get packedCount => _items.where((item) => item.isPacked).length;

  /// Percentage on a 0..100 scale; an empty list is 0 percent complete.
  double get completionPercentage =>
      totalCount == 0 ? 0 : packedCount * 100 / totalCount;
  Future<void>? _loading;

  Future<void> _refresh() async {
    final items = await _repository.getItemsForTrip(tripId);
    if (isDisposed) return;
    _items = List.unmodifiable(items);
    hasLoaded = true;
  }

  Future<void> loadItems({bool force = false}) {
    if (_loading != null) return _loading!;
    if (hasLoaded && !force) return Future.value();
    return _loading = operate(
      _refresh,
      loading: true,
    ).onError<AppException>((_, _) {}).whenComplete(() => _loading = null);
  }

  /// Use as TemplateProvider's onTripItemsChanged callback. The queued reload
  /// runs after any earlier read/write, even when a load is already in flight.
  Future<void> reloadAfterTemplate(int affectedTripId) {
    if (affectedTripId != tripId || isDisposed) return Future.value();
    return operate(_refresh, loading: true).onError<AppException>((_, _) {});
  }

  void _checkTrip(PackingItem item) {
    if (item.tripId != tripId) {
      throw const ValidationException('The item belongs to another trip.');
    }
  }

  PackingItem _requireItem(int id) => _items.firstWhere(
    (item) => item.id == id,
    orElse: () => throw const NotFoundException(
      'Packing item was not found in this trip.',
    ),
  );

  Future<T> _mutate<T>(Future<T> Function() action) => operate(() async {
    final result = await action();
    await refreshAfterWrite(_refresh);
    return result;
  }, mutation: true);

  Future<int> createItem(PackingItem item) => _mutate(() {
    _checkTrip(item);
    return _repository.createItem(item);
  });
  Future<void> updateItem(PackingItem item) => _mutate(() {
    _checkTrip(item);
    _requireItem(item.id ?? -1);
    return _repository.updateItem(item);
  });
  Future<void> deleteItem(int id) => _mutate(() {
    _requireItem(id);
    return _repository.deleteItem(id);
  });
  Future<void> deletePackedItems() =>
      _mutate(() => _repository.deletePackedItems(tripId));

  Future<void> setPacked(int id, bool packed) => operate(() async {
    final original = _requireItem(id);
    final before = _items;
    if (original.isPacked != packed) {
      _items = List.unmodifiable(
        _items.map(
          (item) => item.id == id ? item.copyWith(isPacked: packed) : item,
        ),
      );
      changed();
    }
    try {
      await _repository.setPacked(id, packed);
    } catch (_) {
      if (!isDisposed) _items = before;
      rethrow;
    }
  }, mutation: true);
}
