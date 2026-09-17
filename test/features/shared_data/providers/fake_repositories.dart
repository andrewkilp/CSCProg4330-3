import 'package:csc4330prog3/features/trips/domain/trip.dart';
import 'package:csc4330prog3/features/trips/domain/trip_repository.dart';
import 'package:csc4330prog3/features/packing/domain/packing_item.dart';
import 'package:csc4330prog3/features/packing/domain/packing_item_repository.dart';
import 'package:csc4330prog3/features/templates/domain/packing_template.dart';
import 'package:csc4330prog3/features/templates/domain/template_item.dart';
import 'package:csc4330prog3/features/templates/domain/packing_template_repository.dart';

final testDate = DateTime.utc(2026, 9, 17);
Trip testTrip([int? id = 1]) =>
    Trip(id: id, name: 'Trip', startDate: testDate, createdAt: testDate);
PackingItem testItem([int? id = 1]) => PackingItem(
  id: id,
  tripId: 1,
  name: 'Shirt',
  category: 'Clothing',
  quantity: 1,
  isPacked: false,
  createdAt: testDate,
);

class FakeTripRepository implements TripRepository {
  List<Trip> rows = [testTrip()];
  Future<List<Trip>> Function()? onLoad;
  Future<void> Function()? onWrite;
  int loads = 0;
  int nextId = 2;
  @override
  Future<List<Trip>> getAllTrips() async {
    loads++;
    return onLoad == null ? List.of(rows) : onLoad!();
  }

  @override
  Future<Trip?> getTripById(int id) async =>
      rows.where((t) => t.id == id).firstOrNull;
  @override
  Future<int> createTrip(Trip trip) async {
    await onWrite?.call();
    final id = nextId++;
    rows.add(trip.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    await onWrite?.call();
    rows = rows.map((t) => t.id == trip.id ? trip : t).toList();
  }

  @override
  Future<void> deleteTrip(int tripId) async {
    await onWrite?.call();
    rows.removeWhere((t) => t.id == tripId);
  }

  @override
  Future<int> duplicateTrip(
    int tripId, {
    required String newName,
    required DateTime newStartDate,
    DateTime? newEndDate,
  }) async {
    final source = (await getTripById(tripId))!;
    return createTrip(
      source.copyWith(
        name: newName,
        startDate: newStartDate,
        endDate: newEndDate,
      ),
    );
  }
}

class FakePackingRepository implements PackingItemRepository {
  List<PackingItem> rows = [testItem()];
  Future<List<PackingItem>> Function()? onLoad;
  Future<void> Function(int, bool)? onPacked;
  Future<void> Function()? onWrite;
  int loads = 0;
  int nextId = 2;
  @override
  Future<List<PackingItem>> getItemsForTrip(int tripId) async {
    loads++;
    return onLoad == null
        ? rows.where((i) => i.tripId == tripId).toList()
        : onLoad!();
  }

  @override
  Future<int> createItem(PackingItem item) async {
    await onWrite?.call();
    final id = nextId++;
    rows.add(item.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateItem(PackingItem item) async {
    await onWrite?.call();
    rows = rows.map((i) => i.id == item.id ? item : i).toList();
  }

  @override
  Future<void> setPacked(int itemId, bool isPacked) async {
    await onPacked?.call(itemId, isPacked);
    rows = rows
        .map((i) => i.id == itemId ? i.copyWith(isPacked: isPacked) : i)
        .toList();
  }

  @override
  Future<void> deleteItem(int itemId) async {
    await onWrite?.call();
    rows.removeWhere((i) => i.id == itemId);
  }

  @override
  Future<void> deletePackedItems(int tripId) async {
    await onWrite?.call();
    rows.removeWhere((i) => i.tripId == tripId && i.isPacked);
  }
}

class FakeTemplateRepository implements PackingTemplateRepository {
  List<PackingTemplate> rows = [
    PackingTemplate(id: 1, name: 'Saved', createdAt: testDate),
  ];
  List<TemplateItem> items = [
    const TemplateItem(
      id: 1,
      templateId: 1,
      name: 'Shirt',
      category: 'Clothing',
      quantity: 1,
    ),
  ];
  Future<List<PackingTemplate>> Function()? onLoad;
  Future<List<TemplateItem>> Function()? onItemLoad;
  Future<void> Function()? onWrite;
  int loads = 0;
  int itemLoads = 0;
  int nextId = 2;
  @override
  Future<List<PackingTemplate>> getAllTemplates() async {
    loads++;
    return onLoad == null ? List.of(rows) : onLoad!();
  }

  @override
  Future<List<TemplateItem>> getTemplateItems(int templateId) async {
    itemLoads++;
    return onItemLoad == null ? List.of(items) : onItemLoad!();
  }

  @override
  Future<int> saveTripAsTemplate(int tripId, String templateName) async {
    await onWrite?.call();
    final id = nextId++;
    rows.add(PackingTemplate(id: id, name: templateName, createdAt: testDate));
    return id;
  }

  @override
  Future<void> applyTemplateToTrip(int templateId, int tripId) async =>
      onWrite?.call();
  @override
  Future<void> deleteTemplate(int templateId) async {
    await onWrite?.call();
    rows.removeWhere((t) => t.id == templateId);
  }
}
