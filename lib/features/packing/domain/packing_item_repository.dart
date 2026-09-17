import 'packing_item.dart';

/// Failures must throw typed AppException subclasses, never be swallowed.
/// Create/update validate input; updates require a persisted non-null ID.
abstract interface class PackingItemRepository {
  Future<List<PackingItem>> getItemsForTrip(int tripId);
  Future<int> createItem(PackingItem item);
  Future<void> updateItem(PackingItem item);
  Future<void> setPacked(int itemId, bool isPacked);
  Future<void> deleteItem(int itemId);
  Future<void> deletePackedItems(int tripId);
}
